"""Perceptual hash computation and duplicate detection."""

import logging
import sqlite3
from pathlib import Path

import imagehash
from PIL import Image

from app.config import PHASH_THRESHOLD

logger = logging.getLogger(__name__)


def compute_phash(image_path: str) -> str:
    """Compute the perceptual hash of an image.

    Args:
        image_path: Absolute or relative path to the image file.

    Returns:
        Hex string representation of the pHash.

    Raises:
        FileNotFoundError: If the image does not exist.
        OSError: If the image cannot be opened.
    """
    path = Path(image_path)
    if not path.is_file():
        raise FileNotFoundError(f"Image not found: {image_path}")
    with Image.open(path) as img:
        return str(imagehash.phash(img))


def _phash_distance(hash_a: str, hash_b: str) -> int:
    """Return the Hamming distance between two hex pHash strings."""
    return imagehash.hex_to_hash(hash_a) - imagehash.hex_to_hash(hash_b)


def find_duplicate(
    user_id: str,
    phash: str,
    conn: sqlite3.Connection,
    threshold: int = PHASH_THRESHOLD,
) -> int | None:
    """Search for a previously uploaded photo with a similar pHash.

    Args:
        user_id: The uploading user's identifier.
        phash: Hex pHash of the candidate photo.
        conn: An open SQLite connection.
        threshold: Maximum Hamming distance to consider a duplicate (inclusive).

    Returns:
        The ``id`` of the duplicate photo row, or ``None`` if no duplicate found.
    """
    rows = conn.execute(
        "SELECT id, phash FROM photos WHERE user_id = ? AND phash IS NOT NULL",
        (user_id,),
    ).fetchall()

    for row in rows:
        try:
            distance = _phash_distance(phash, row["phash"])
        except Exception as exc:
            logger.warning("Could not compare phash for photo %s: %s", row["id"], exc)
            continue
        if distance <= threshold:
            logger.debug(
                "Duplicate detected (distance=%d, threshold=%d) for user %s",
                distance,
                threshold,
                user_id,
            )
            return row["id"]

    return None
