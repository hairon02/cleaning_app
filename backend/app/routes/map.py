"""Map state endpoint."""

import io
import json
import sqlite3
from pathlib import Path

from fastapi import APIRouter, Depends, HTTPException, Query, Response
from PIL import Image, UnidentifiedImageError

from app.cells import get_cleared_cells
from app.db import get_db

router = APIRouter()
MAX_BBOX_DEGREES = 50_000 / 111_320
DEMO_PHOTOS = (
    {
        "id": "demo-test1",
        "lat": 19.0414,
        "lon": -98.2063,
        "image_url": "/api/map/demo-photos/test1.jpg",
    },
    {
        "id": "demo-test2",
        "lat": 19.0281,
        "lon": -98.2108,
        "image_url": "/api/map/demo-photos/test2.jpg",
    },
    {
        "id": "demo-test3",
        "lat": 19.0522,
        "lon": -98.1937,
        "image_url": "/api/map/demo-photos/test3.jpg",
    },
)
DEMO_PHOTO_DIR = Path(__file__).resolve().parents[2] / "eval" / "photos"


def _parse_bbox(raw_bbox: str) -> tuple[float, float, float, float]:
    try:
        values = tuple(float(value.strip()) for value in raw_bbox.split(","))
    except ValueError as exc:
        raise HTTPException(status_code=400, detail="bbox must contain four numbers") from exc
    if len(values) != 4:
        raise HTTPException(status_code=400, detail="bbox must be lat_min,lon_min,lat_max,lon_max")
    lat_min, lon_min, lat_max, lon_max = values
    if not (-90 <= lat_min < lat_max <= 90 and -180 <= lon_min < lon_max <= 180):
        raise HTTPException(status_code=400, detail="bbox coordinates are invalid")
    if lat_max - lat_min > MAX_BBOX_DEGREES or lon_max - lon_min > MAX_BBOX_DEGREES:
        raise HTTPException(status_code=400, detail="bbox cannot exceed 50 km by 50 km")
    return values


@router.get("/map")
async def get_map(
    user_id: str = Query(min_length=1),
    bbox: str = Query(...),
    conn: sqlite3.Connection = Depends(get_db),
) -> dict[str, object]:
    parsed_bbox = _parse_bbox(bbox)
    cleared = get_cleared_cells(user_id, parsed_bbox, conn)
    total = conn.execute(
        "SELECT COUNT(*) FROM cells WHERE user_id = ?",
        (user_id,),
    ).fetchone()[0]
    lat_min, lon_min, lat_max, lon_max = parsed_bbox
    rows = conn.execute(
        """
        SELECT id, lat, lon, taken_at, gemma_json
        FROM photos
        WHERE user_id = ? AND status = 'verified'
          AND lat BETWEEN ? AND ? AND lon BETWEEN ? AND ?
        ORDER BY taken_at DESC
        LIMIT 300
        """,
        (user_id, lat_min, lat_max, lon_min, lon_max),
    ).fetchall()
    photos = []
    for row in rows:
        metadata = json.loads(row["gemma_json"] or "{}")
        photos.append(
            {
                "id": row["id"],
                "lat": row["lat"],
                "lon": row["lon"],
                "image_url": f"/api/map/photos/{row['id']}/thumbnail?user_id={user_id}",
                "taken_at": row["taken_at"],
                "description": metadata.get("description"),
                "demo": False,
            }
        )
    photos.extend(
        {**photo, "demo": True}
        for photo in DEMO_PHOTOS
        if lat_min <= photo["lat"] <= lat_max and lon_min <= photo["lon"] <= lon_max
    )
    return {"cleared": cleared, "total_cleared": total, "photos": photos}


def _thumbnail(path: Path) -> Response:
    try:
        with Image.open(path) as image:
            image.thumbnail((240, 320), Image.Resampling.LANCZOS)
            output = io.BytesIO()
            image.convert("RGB").save(output, format="JPEG", quality=76, optimize=True)
    except (FileNotFoundError, UnidentifiedImageError, OSError) as exc:
        raise HTTPException(status_code=404, detail="photo thumbnail not found") from exc
    return Response(
        content=output.getvalue(),
        media_type="image/jpeg",
        headers={"Cache-Control": "public, max-age=86400"},
    )


@router.get("/map/photos/{photo_id}/thumbnail")
async def get_photo_thumbnail(
    photo_id: str,
    user_id: str = Query(min_length=1),
    conn: sqlite3.Connection = Depends(get_db),
) -> Response:
    row = conn.execute(
        "SELECT path FROM photos WHERE id = ? AND user_id = ? AND status = 'verified'",
        (photo_id, user_id),
    ).fetchone()
    if row is None:
        raise HTTPException(status_code=404, detail="photo not found")
    return _thumbnail(Path(row["path"]))


@router.get("/map/demo-photos/{filename}")
async def get_demo_photo_thumbnail(filename: str) -> Response:
    if filename not in {"test1.jpg", "test2.jpg", "test3.jpg"}:
        raise HTTPException(status_code=404, detail="demo photo not found")
    return _thumbnail(DEMO_PHOTO_DIR / filename)
