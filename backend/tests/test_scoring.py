"""Tests for the points ledger and streak scoring (feature 008)."""

import sqlite3
from datetime import date, timedelta

import pytest

from app.config import (
    POINTS_NEW_CELL,
    POINTS_PHOTO_VERIFIED,
    POINTS_STREAK_DAY,
)
from app.scoring import (
    PointReason,
    _check_and_award_streak,
    award_points,
    get_streak_days,
    get_user_total,
)


@pytest.fixture
def conn():
    connection = sqlite3.connect(":memory:")
    connection.row_factory = sqlite3.Row
    connection.executescript(
        """
        CREATE TABLE users (
            id TEXT PRIMARY KEY,
            display_name TEXT NOT NULL
        );
        CREATE TABLE points_ledger (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id TEXT NOT NULL,
            reason TEXT NOT NULL,
            amount INTEGER NOT NULL,
            ref_id TEXT,
            created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (user_id) REFERENCES users(id)
        );
        CREATE UNIQUE INDEX uq_points_ledger_idempotency
            ON points_ledger(user_id, reason, COALESCE(ref_id, ''));
        INSERT INTO users (id, display_name) VALUES ('user-1', 'Test User');
        """
    )
    connection.commit()
    try:
        yield connection
    finally:
        connection.close()


def _award_photo(conn: sqlite3.Connection, photo_id: str, activity_date: date) -> None:
    award_points(
        "user-1",
        PointReason.PHOTO_VERIFIED,
        POINTS_PHOTO_VERIFIED,
        photo_id,
        conn,
    )
    conn.execute(
        "UPDATE points_ledger SET created_at = ? WHERE user_id = ? AND reason = ? AND ref_id = ?",
        (
            f"{activity_date.isoformat()} 12:00:00",
            "user-1",
            PointReason.PHOTO_VERIFIED.value,
            photo_id,
        ),
    )
    conn.commit()


def test_verified_photo_awards_points(conn: sqlite3.Connection):
    assert award_points(
        "user-1", PointReason.PHOTO_VERIFIED, POINTS_PHOTO_VERIFIED, "photo-1", conn
    )

    assert get_user_total("user-1", conn) == POINTS_PHOTO_VERIFIED


def test_new_cell_awards_additional_points(conn: sqlite3.Connection):
    award_points("user-1", PointReason.PHOTO_VERIFIED, POINTS_PHOTO_VERIFIED, "photo-1", conn)
    award_points("user-1", PointReason.NEW_CELL, POINTS_NEW_CELL, "cell-1", conn)

    assert get_user_total("user-1", conn) == POINTS_PHOTO_VERIFIED + POINTS_NEW_CELL


def test_duplicate_award_does_not_add_points_twice(conn: sqlite3.Connection):
    first = award_points(
        "user-1", PointReason.PHOTO_VERIFIED, POINTS_PHOTO_VERIFIED, "photo-1", conn
    )
    second = award_points(
        "user-1", PointReason.PHOTO_VERIFIED, POINTS_PHOTO_VERIFIED, "photo-1", conn
    )

    assert first is True
    assert second is False
    assert get_user_total("user-1", conn) == POINTS_PHOTO_VERIFIED


def test_two_consecutive_photo_days_award_streak_bonus(conn: sqlite3.Connection):
    yesterday = date.today() - timedelta(days=1)
    today = date.today()
    _award_photo(conn, "photo-yesterday", yesterday)
    _award_photo(conn, "photo-today", today)

    assert _check_and_award_streak("user-1", conn) is True
    assert get_user_total("user-1", conn) == (
        2 * POINTS_PHOTO_VERIFIED + POINTS_STREAK_DAY
    )
    assert get_streak_days("user-1", conn) == 2


def test_broken_streak_does_not_deduct_points(conn: sqlite3.Connection):
    three_days_ago = date.today() - timedelta(days=3)
    today = date.today()
    _award_photo(conn, "photo-older", three_days_ago)
    _award_photo(conn, "photo-today", today)
    total_before_check = get_user_total("user-1", conn)

    assert _check_and_award_streak("user-1", conn) is False
    assert get_user_total("user-1", conn) == total_before_check
    assert total_before_check == 2 * POINTS_PHOTO_VERIFIED
