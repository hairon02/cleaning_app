"""POST /upload endpoint: receive a photo, verify with Gemma, detect duplicates."""

import json
import logging
import sqlite3
import uuid
from datetime import datetime
from typing import Annotated, Optional

from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile
from PIL import Image, UnidentifiedImageError
from pydantic import BaseModel, Field

from app.cells import latlon_to_cell, mark_cleared
from app.config import POINTS_NEW_CELL, POINTS_PHOTO_VERIFIED, UPLOAD_DIR
from app.db import get_db
from app.pipeline.phash import compute_phash, find_duplicate
from app.pipeline.verify import GemmaError, verify_photo
from app.scoring import PointReason, _check_and_award_streak, award_points

logger = logging.getLogger(__name__)

router = APIRouter()

# ---------------------------------------------------------------------------
# Response model
# ---------------------------------------------------------------------------


class PhotoUploadResponse(BaseModel):
    photo_id: str
    status: str  # verified | rejected | duplicate | pending_review
    description: Optional[str] = None
    tags: Optional[list[str]] = None
    challenges_completed: list[str] = Field(default_factory=list)


# ---------------------------------------------------------------------------
# Points integration
# ---------------------------------------------------------------------------


def _award_points(
    user_id: str,
    photo_id: str,
    conn: sqlite3.Connection,
    *,
    is_new_cell: bool = False,
) -> None:
    """Award verified-photo, new-cell, and consecutive-day points."""
    award_points(
        user_id,
        PointReason.PHOTO_VERIFIED,
        POINTS_PHOTO_VERIFIED,
        photo_id,
        conn,
    )
    if is_new_cell:
        row = conn.execute(
            "SELECT cell_id FROM photos WHERE id = ? AND user_id = ?",
            (photo_id, user_id),
        ).fetchone()
        if row is not None:
            award_points(
                user_id,
                PointReason.NEW_CELL,
                POINTS_NEW_CELL,
                row["cell_id"],
                conn,
            )
    _check_and_award_streak(user_id, conn)


# ---------------------------------------------------------------------------
# Endpoint
# ---------------------------------------------------------------------------


@router.post("/upload", response_model=PhotoUploadResponse)
async def upload_photo(
    file: Annotated[UploadFile, File(description="Photo captured from the camera")],
    lat: Annotated[float, Form(ge=-90, le=90, description="Latitude at capture time")],
    lon: Annotated[float, Form(ge=-180, le=180, description="Longitude at capture time")],
    taken_at: Annotated[datetime, Form(description="Capture timestamp in ISO 8601")],
    user_id: Annotated[str, Form(description="Anonymous device user identifier")],
    conn: sqlite3.Connection = Depends(get_db),
) -> PhotoUploadResponse:
    """Receive a photo, run pHash deduplication and Gemma verification.

    This endpoint never returns HTTP 500 due to a Gemma failure; instead
    the photo is stored with ``status=pending_review``.
    """
    # ------------------------------------------------------------------
    # 1. Validate inputs
    # ------------------------------------------------------------------
    # ------------------------------------------------------------------
    # 2. Save file to disk before any processing
    # ------------------------------------------------------------------
    photo_id = str(uuid.uuid4())
    user_upload_dir = UPLOAD_DIR / user_id
    user_upload_dir.mkdir(parents=True, exist_ok=True)

    dest_path = user_upload_dir / f"{photo_id}.jpg"
    contents = await file.read()
    dest_path.write_bytes(contents)
    try:
        with Image.open(dest_path) as image:
            image.verify()
    except (UnidentifiedImageError, OSError):
        dest_path.unlink(missing_ok=True)
        raise HTTPException(status_code=422, detail="file must be a valid image")

    # The client creates the anonymous device id on first launch. Register it
    # lazily so the photos/cells/ledger foreign keys remain valid without a
    # separate signup request.
    conn.execute(
        "INSERT OR IGNORE INTO users (id, display_name) VALUES (?, ?)",
        (user_id, "Guest"),
    )
    conn.commit()

    # ------------------------------------------------------------------
    # 3. Compute pHash and check for duplicates
    # ------------------------------------------------------------------
    try:
        phash = compute_phash(str(dest_path))
    except Exception as exc:
        logger.error("Failed to compute pHash for photo %s: %s", photo_id, exc)
        phash = None

    status = "pending_review"
    duplicate_of: Optional[str] = None
    gemma_result = None

    if phash is not None:
        duplicate_of = find_duplicate(user_id, phash, conn)

    if duplicate_of is not None:
        status = "duplicate"
    else:
        # ------------------------------------------------------------------
        # 4. Call Gemma for verification
        # ------------------------------------------------------------------
        try:
            gemma_result = verify_photo(str(dest_path))
            if gemma_result.is_outdoor:
                status = "verified"
            else:
                status = "rejected"
        except GemmaError as exc:
            logger.warning("Gemma failed for photo %s: %s", photo_id, exc)
            status = "pending_review"

    # ------------------------------------------------------------------
    # 5. Compute cell_id (always, for DB completeness)
    # ------------------------------------------------------------------
    cell_id = latlon_to_cell(lat, lon)

    # ------------------------------------------------------------------
    # 6. Persist to DB
    # ------------------------------------------------------------------
    gemma_json = json.dumps(gemma_result.model_dump()) if gemma_result is not None else None

    conn.execute(
        """
        INSERT INTO photos
            (id, user_id, path, lat, lon, taken_at, cell_id, phash, gemma_json, status)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """,
        (
            photo_id,
            user_id,
            str(dest_path),
            lat,
            lon,
            taken_at.isoformat(),
            cell_id,
            phash,
            gemma_json,
            status,
        ),
    )
    conn.commit()

    # Log only non-sensitive info (no exact coordinates)
    logger.info("Photo %s | status=%s | user=%s", photo_id, status, user_id)

    # ------------------------------------------------------------------
    # 7. Side effects for verified photos
    # ------------------------------------------------------------------
    if status == "verified":
        is_new_cell = mark_cleared(user_id, cell_id, conn)
        _award_points(user_id, photo_id, conn, is_new_cell=is_new_cell)

    # ------------------------------------------------------------------
    # 8. Build response
    # ------------------------------------------------------------------
    return PhotoUploadResponse(
        photo_id=photo_id,
        status=status,
        description=gemma_result.description if gemma_result else None,
        tags=gemma_result.tags if gemma_result else None,
        challenges_completed=[],
    )
