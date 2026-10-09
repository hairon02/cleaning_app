"""Tests for POST /upload endpoint (feature 003)."""

import sqlite3
from pathlib import Path
from typing import Generator

import pytest
from fastapi.testclient import TestClient
from PIL import Image

import app.routes.upload as upload_module
from app.db import get_db
from app.main import app
from app.pipeline.verify import GemmaResult

# ---------------------------------------------------------------------------
# Helpers / fixtures
# ---------------------------------------------------------------------------


def _make_image(tmp_path: Path, name: str = "photo.jpg") -> Path:
    path = tmp_path / name
    Image.new("RGB", (200, 200), color=(80, 160, 80)).save(path)
    return path


_SCHEMA_SQL = """
CREATE TABLE IF NOT EXISTS photos (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    path TEXT NOT NULL,
    lat REAL NOT NULL,
    lon REAL NOT NULL,
    taken_at TIMESTAMP NOT NULL,
    cell_id TEXT NOT NULL,
    phash TEXT,
    gemma_json TEXT,
    status TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS users (
    id TEXT PRIMARY KEY,
    display_name TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS cells (
    user_id TEXT NOT NULL,
    cell_id TEXT NOT NULL,
    cleared_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, cell_id),
    FOREIGN KEY(user_id) REFERENCES users(id)
);
"""

# A shared in-memory DB that allows cross-thread access for testing
_TEST_DB_URI = "file::mem_test:?mode=memory&cache=shared"


def _make_test_db() -> sqlite3.Connection:
    """Open a named in-memory DB that can be shared across threads."""
    conn = sqlite3.connect(_TEST_DB_URI, check_same_thread=False, uri=True)
    conn.row_factory = sqlite3.Row
    conn.executescript(_SCHEMA_SQL)
    conn.commit()
    return conn


@pytest.fixture
def client(tmp_path: Path, monkeypatch: pytest.MonkeyPatch):
    """TestClient with a shared in-memory DB and UPLOAD_DIR in tmp."""
    # Patch UPLOAD_DIR in the upload module so files land in tmp
    monkeypatch.setattr(upload_module, "UPLOAD_DIR", tmp_path / "uploads")

    master_conn = _make_test_db()

    def _override_get_db() -> Generator[sqlite3.Connection, None, None]:
        # Each call opens a fresh connection to the same named in-memory DB
        conn = sqlite3.connect(_TEST_DB_URI, check_same_thread=False, uri=True)
        conn.row_factory = sqlite3.Row
        try:
            yield conn
        finally:
            conn.close()

    app.dependency_overrides[get_db] = _override_get_db

    with TestClient(app, raise_server_exceptions=True) as c:
        yield c

    app.dependency_overrides.clear()
    master_conn.close()


def _upload(client, img_path: Path, user_id: str = "user-abc", override_caller=None):
    """POST /api/upload helper. Patches verify_photo if override_caller given."""
    with open(img_path, "rb") as f:
        data = {
            "lat": "19.4326",
            "lon": "-99.1332",
            "taken_at": "2026-10-07T10:00:00",
            "user_id": user_id,
        }
        return client.post(
            "/api/upload",
            files={"file": ("photo.jpg", f, "image/jpeg")},
            data=data,
        )


# ---------------------------------------------------------------------------
# Test: verified photo
# ---------------------------------------------------------------------------


def test_upload_verified(tmp_path: Path, client, monkeypatch: pytest.MonkeyPatch):
    img = _make_image(tmp_path)

    good_result = GemmaResult(
        is_outdoor=True,
        description="A sunny park",
        tags=["park", "trees"],
        time_of_day="morning",
        weather="sunny",
    )

    monkeypatch.setattr(
        "app.routes.upload.verify_photo",
        lambda path: good_result,
    )

    award_calls = []
    monkeypatch.setattr(
        "app.routes.upload._award_points",
        lambda user_id, photo_id, conn, *, is_new_cell=False: award_calls.append(is_new_cell),
    )

    resp = _upload(client, img)
    assert resp.status_code == 200, resp.text
    body = resp.json()
    assert body["status"] == "verified"
    assert body["description"] == "A sunny park"
    assert "park" in body["tags"]
    assert body["photo_id"]
    assert award_calls == [True]

    map_resp = client.get(
        "/api/map",
        params={"user_id": "user-abc", "bbox": "19.42,-99.14,19.45,-99.12"},
    )
    assert map_resp.status_code == 200, map_resp.text
    assert map_resp.json()["total_cleared"] == 1
    assert len(map_resp.json()["cleared"]) == 1


# ---------------------------------------------------------------------------
# Test: rejected photo (not outdoor)
# ---------------------------------------------------------------------------


def test_upload_rejected(tmp_path: Path, client, monkeypatch: pytest.MonkeyPatch):
    img = _make_image(tmp_path)

    indoor_result = GemmaResult(
        is_outdoor=False,
        description="An indoor room",
        tags=["room"],
        time_of_day="unknown",
        weather="unknown",
    )

    monkeypatch.setattr(
        "app.routes.upload.verify_photo",
        lambda path: indoor_result,
    )

    resp = _upload(client, img)
    assert resp.status_code == 200
    assert resp.json()["status"] == "rejected"


# ---------------------------------------------------------------------------
# Test: duplicate photo
# ---------------------------------------------------------------------------


def test_upload_duplicate(tmp_path: Path, client, monkeypatch: pytest.MonkeyPatch):
    img = _make_image(tmp_path)

    good_result = GemmaResult(
        is_outdoor=True,
        description="A park",
        tags=["park"],
        time_of_day="morning",
        weather="sunny",
    )

    monkeypatch.setattr(
        "app.routes.upload.verify_photo",
        lambda path: good_result,
    )

    # First upload — should be verified
    resp1 = _upload(client, img)
    assert resp1.json()["status"] == "verified"

    # Second upload of the same image — should be duplicate
    resp2 = _upload(client, img)
    assert resp2.json()["status"] == "duplicate"


# ---------------------------------------------------------------------------
# Test: Gemma fails → pending_review
# ---------------------------------------------------------------------------


def test_upload_gemma_failure(tmp_path: Path, client, monkeypatch: pytest.MonkeyPatch):
    img = _make_image(tmp_path, "fail.jpg")

    from app.pipeline.verify import GemmaError

    def _raise(_path):
        raise GemmaError("model timeout")

    monkeypatch.setattr("app.routes.upload.verify_photo", _raise)

    resp = _upload(client, img)
    assert resp.status_code == 200
    body = resp.json()
    assert body["status"] == "pending_review"
    assert body["description"] is None


# ---------------------------------------------------------------------------
# Test: missing required fields → 422
# ---------------------------------------------------------------------------


def test_upload_missing_fields(client):
    resp = client.post("/api/upload", data={})
    assert resp.status_code == 422


def test_upload_invalid_lat(tmp_path: Path, client, monkeypatch: pytest.MonkeyPatch):
    img = _make_image(tmp_path)
    monkeypatch.setattr(
        "app.routes.upload.verify_photo",
        lambda p: GemmaResult(
            is_outdoor=True, description="x", tags=[], time_of_day="day", weather="clear"
        ),
    )
    with open(img, "rb") as f:
        resp = client.post(
            "/api/upload",
            files={"file": ("p.jpg", f, "image/jpeg")},
            data={
                "lat": "999",   # invalid
                "lon": "-99.1332",
                "taken_at": "2026-10-07T10:00:00",
                "user_id": "user-abc",
            },
        )
    assert resp.status_code == 422
