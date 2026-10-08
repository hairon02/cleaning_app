"""Tests for the pHash module (feature 003)."""

import sqlite3
from pathlib import Path

import imagehash
import pytest
from PIL import Image

from app.config import PHASH_THRESHOLD
from app.pipeline.phash import compute_phash, find_duplicate

# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------


@pytest.fixture
def green_image(tmp_path: Path) -> Path:
    """A green-gradient image with distinct texture for pHash."""
    path = tmp_path / "green.jpg"
    img = Image.new("RGB", (256, 256))
    pixels = img.load()
    for y in range(256):
        for x in range(256):
            pixels[x, y] = (0, (x + y) % 256, 0)
    img.save(path)
    return path


@pytest.fixture
def blue_image(tmp_path: Path) -> Path:
    """A blue-gradient image with distinct texture for pHash."""
    path = tmp_path / "blue.jpg"
    img = Image.new("RGB", (256, 256))
    pixels = img.load()
    for y in range(256):
        for x in range(256):
            pixels[x, y] = (0, 0, (255 - x - y) % 256)
    img.save(path)
    return path


@pytest.fixture
def mem_db() -> sqlite3.Connection:
    """In-memory SQLite DB with just enough schema for phash tests."""
    conn = sqlite3.connect(":memory:")
    conn.row_factory = sqlite3.Row
    conn.execute(
        """
        CREATE TABLE photos (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            phash TEXT
        )
        """
    )
    conn.commit()
    return conn


# ---------------------------------------------------------------------------
# compute_phash
# ---------------------------------------------------------------------------


def test_compute_phash_returns_string(green_image: Path):
    result = compute_phash(str(green_image))
    assert isinstance(result, str)
    assert len(result) > 0


def test_same_image_distance_is_zero(green_image: Path):
    h1 = compute_phash(str(green_image))
    h2 = compute_phash(str(green_image))
    distance = imagehash.hex_to_hash(h1) - imagehash.hex_to_hash(h2)
    assert distance == 0


def test_different_images_high_distance(green_image: Path, blue_image: Path):
    h1 = compute_phash(str(green_image))
    h2 = compute_phash(str(blue_image))
    distance = imagehash.hex_to_hash(h1) - imagehash.hex_to_hash(h2)
    # Completely different colours should yield a non-trivially high distance
    assert distance > PHASH_THRESHOLD


def test_compute_phash_missing_file_raises():
    with pytest.raises(FileNotFoundError):
        compute_phash("/does/not/exist.jpg")


# ---------------------------------------------------------------------------
# find_duplicate
# ---------------------------------------------------------------------------


def test_find_duplicate_returns_none_when_empty(green_image: Path, mem_db: sqlite3.Connection):
    phash = compute_phash(str(green_image))
    assert find_duplicate("user1", phash, mem_db) is None


def test_find_duplicate_detects_same_photo(green_image: Path, mem_db: sqlite3.Connection):
    phash = compute_phash(str(green_image))
    mem_db.execute(
        "INSERT INTO photos (id, user_id, phash) VALUES ('photo-1', 'user1', ?)",
        (phash,),
    )
    mem_db.commit()

    result = find_duplicate("user1", phash, mem_db)
    assert result == "photo-1"


def test_find_duplicate_ignores_other_users(green_image: Path, mem_db: sqlite3.Connection):
    phash = compute_phash(str(green_image))
    mem_db.execute(
        "INSERT INTO photos (id, user_id, phash) VALUES ('photo-1', 'other_user', ?)",
        (phash,),
    )
    mem_db.commit()

    result = find_duplicate("user1", phash, mem_db)
    assert result is None


def test_find_duplicate_threshold_configurable(
    green_image: Path, blue_image: Path, mem_db: sqlite3.Connection
):
    """With threshold=0, even slightly different images should not match."""
    phash_green = compute_phash(str(green_image))
    phash_blue = compute_phash(str(blue_image))

    mem_db.execute(
        "INSERT INTO photos (id, user_id, phash) VALUES ('photo-1', 'user1', ?)",
        (phash_blue,),
    )
    mem_db.commit()

    # threshold=0 means only exact matches are duplicates
    result = find_duplicate("user1", phash_green, mem_db, threshold=0)
    assert result is None
