"""Verified photo journal for an individual user."""

import io
import json
import mimetypes
import sqlite3
from pathlib import Path
from typing import Any

from fastapi import APIRouter, Depends, HTTPException, Query, Response
from fastapi.responses import FileResponse
from PIL import Image, UnidentifiedImageError
from pydantic import BaseModel

from app.db import get_db

router = APIRouter(tags=["journal"])
PAGE_SIZE = 20


class JournalEntry(BaseModel):
    photo_id: str
    photo_url: str
    thumbnail_url: str
    description: str
    tags: list[str]
    taken_at: str


class JournalPage(BaseModel):
    entries: list[JournalEntry]
    page: int
    page_size: int
    total: int
    has_more: bool


def _image_url(photo_id: str, user_id: str, kind: str) -> str:
    return f"/api/journal/photos/{photo_id}/{kind}?user_id={user_id}"


@router.get("/journal", response_model=JournalPage)
async def get_journal(
    user_id: str = Query(min_length=1),
    page: int = Query(default=0, ge=0),
    conn: sqlite3.Connection = Depends(get_db),
) -> JournalPage:
    """Return a user's verified photos, newest first, in zero-based pages."""
    total = conn.execute(
        "SELECT COUNT(*) FROM photos WHERE user_id = ? AND status = 'verified'",
        (user_id,),
    ).fetchone()[0]
    rows = conn.execute(
        """
        SELECT id, taken_at, gemma_json
        FROM photos
        WHERE user_id = ? AND status = 'verified'
        ORDER BY datetime(taken_at) DESC, id DESC
        LIMIT ? OFFSET ?
        """,
        (user_id, PAGE_SIZE + 1, page * PAGE_SIZE),
    ).fetchall()

    entries = []
    for row in rows[:PAGE_SIZE]:
        try:
            metadata: dict[str, Any] = json.loads(row["gemma_json"] or "{}")
        except (TypeError, json.JSONDecodeError):
            metadata = {}
        raw_tags = metadata.get("tags", [])
        tags = raw_tags if isinstance(raw_tags, list) else []
        photo_id = row["id"]
        entries.append(
            JournalEntry(
                photo_id=photo_id,
                photo_url=_image_url(photo_id, user_id, "image"),
                thumbnail_url=_image_url(photo_id, user_id, "thumbnail"),
                description=str(metadata.get("description") or "A moment outdoors."),
                tags=[str(tag) for tag in tags if tag],
                taken_at=str(row["taken_at"]),
            )
        )

    return JournalPage(
        entries=entries,
        page=page,
        page_size=PAGE_SIZE,
        total=total,
        has_more=len(rows) > PAGE_SIZE,
    )


def _verified_photo_path(
    photo_id: str,
    user_id: str,
    conn: sqlite3.Connection,
) -> Path:
    row = conn.execute(
        "SELECT path FROM photos WHERE id = ? AND user_id = ? AND status = 'verified'",
        (photo_id, user_id),
    ).fetchone()
    if row is None:
        raise HTTPException(status_code=404, detail="photo not found")
    path = Path(row["path"])
    if not path.is_file():
        raise HTTPException(status_code=404, detail="photo file not found")
    return path


@router.get("/journal/photos/{photo_id}/image")
async def get_journal_image(
    photo_id: str,
    user_id: str = Query(min_length=1),
    conn: sqlite3.Connection = Depends(get_db),
) -> FileResponse:
    path = _verified_photo_path(photo_id, user_id, conn)
    media_type = mimetypes.guess_type(path.name)[0] or "application/octet-stream"
    return FileResponse(
        path,
        media_type=media_type,
        headers={"Cache-Control": "private, max-age=86400"},
    )


@router.get("/journal/photos/{photo_id}/thumbnail")
async def get_journal_thumbnail(
    photo_id: str,
    user_id: str = Query(min_length=1),
    conn: sqlite3.Connection = Depends(get_db),
) -> Response:
    path = _verified_photo_path(photo_id, user_id, conn)
    try:
        with Image.open(path) as image:
            image.thumbnail((320, 320), Image.Resampling.LANCZOS)
            output = io.BytesIO()
            image.convert("RGB").save(output, format="JPEG", quality=78, optimize=True)
    except (UnidentifiedImageError, OSError) as exc:
        raise HTTPException(status_code=404, detail="photo thumbnail not found") from exc
    return Response(
        content=output.getvalue(),
        media_type="image/jpeg",
        headers={"Cache-Control": "private, max-age=86400"},
    )
