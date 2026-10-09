"""Deterministic grid-cell conversion and per-user fog state."""

import math
import sqlite3
from collections.abc import Iterable

from app.config import CELL_SIZE_M

METERS_PER_DEGREE = 111_320.0


def _steps(size_m: int | float | None = None) -> tuple[float, float]:
    size = float(size_m or CELL_SIZE_M)
    if size <= 0:
        raise ValueError("cell size must be positive")
    step = size / METERS_PER_DEGREE
    return step, step


def latlon_to_cell(lat: float, lon: float, size_m: int | float | None = None) -> str:
    """Return a reproducible cell id for a latitude/longitude pair."""
    lat_step, lon_step = _steps(size_m)
    return f"{math.floor(lat / lat_step):+07d}_{math.floor(lon / lon_step):+07d}"


def cell_to_bounds(cell_id: str, size_m: int | float | None = None) -> tuple[float, float, float, float]:
    """Return ``(lat_min, lon_min, lat_max, lon_max)`` for a cell id."""
    try:
        lat_index, lon_index = (int(part) for part in cell_id.split("_", 1))
    except (TypeError, ValueError) as exc:
        raise ValueError(f"invalid cell id: {cell_id}") from exc
    lat_step, lon_step = _steps(size_m)
    lat_min = lat_index * lat_step
    lon_min = lon_index * lon_step
    return lat_min, lon_min, lat_min + lat_step, lon_min + lon_step


def mark_cleared(user_id: str, cell_id: str, conn: sqlite3.Connection) -> bool:
    """Mark a cell as cleared; return whether this was a new cell."""
    cursor = conn.execute(
        "INSERT OR IGNORE INTO cells (user_id, cell_id) VALUES (?, ?)",
        (user_id, cell_id),
    )
    conn.commit()
    return cursor.rowcount == 1


def get_cleared_cells(
    user_id: str,
    bbox: tuple[float, float, float, float],
    conn: sqlite3.Connection,
) -> list[str]:
    """Return the user's cleared cells whose bounds intersect the bbox."""
    lat_min, lon_min, lat_max, lon_max = bbox
    rows = conn.execute(
        "SELECT cell_id FROM cells WHERE user_id = ?",
        (user_id,),
    ).fetchall()
    result: list[str] = []
    for row in rows:
        cell_lat_min, cell_lon_min, cell_lat_max, cell_lon_max = cell_to_bounds(row["cell_id"])
        if cell_lat_max > lat_min and cell_lat_min < lat_max and cell_lon_max > lon_min and cell_lon_min < lon_max:
            result.append(row["cell_id"])
    return result


def cells_in_bbox(bbox: tuple[float, float, float, float]) -> Iterable[str]:
    """Yield every cell intersecting a bbox, for the Flutter fog overlay."""
    lat_min, lon_min, lat_max, lon_max = bbox
    lat_step, lon_step = _steps()
    start_lat = math.floor(lat_min / lat_step)
    end_lat = math.floor(lat_max / lat_step)
    start_lon = math.floor(lon_min / lon_step)
    end_lon = math.floor(lon_max / lon_step)
    for lat_index in range(start_lat, end_lat + 1):
        for lon_index in range(start_lon, end_lon + 1):
            yield f"{lat_index:+07d}_{lon_index:+07d}"
