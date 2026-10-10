"""Tests for reviewed challenge selection and its API behavior (feature 009)."""

import sqlite3
from datetime import date

import pytest
from fastapi import HTTPException

from app.challenge_filter import is_safe
from app.challenges import Challenge, get_active_challenges
from app.routes.challenges import get_challenges
from scripts.gen_challenges import ChallengeDraft, _insert_drafts


@pytest.fixture
def conn():
    connection = sqlite3.connect(":memory:")
    connection.row_factory = sqlite3.Row
    connection.executescript(
        """
        CREATE TABLE challenges (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            description TEXT NOT NULL,
            visual_criterion TEXT NOT NULL,
            period TEXT NOT NULL,
            difficulty TEXT NOT NULL,
            points INTEGER NOT NULL,
            reviewed INTEGER NOT NULL DEFAULT 0
        );
        CREATE TABLE points_ledger (
            user_id TEXT NOT NULL,
            reason TEXT NOT NULL,
            ref_id TEXT
        );
        """
    )
    connection.commit()
    try:
        yield connection
    finally:
        connection.close()


def _insert_challenge(
    conn: sqlite3.Connection,
    challenge_id: str,
    period: str,
    *,
    reviewed: bool = True,
) -> None:
    conn.execute(
        """
        INSERT INTO challenges
            (id, title, description, visual_criterion, period, difficulty, points, reviewed)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        """,
        (
            challenge_id,
            f"Challenge {challenge_id}",
            "Explore an outdoor place and take a clear photo.",
            "A tree is clearly visible in the photo.",
            period,
            "easy",
            15 if period == "daily" else 50,
            int(reviewed),
        ),
    )
    conn.commit()


def test_selection_is_deterministic_for_same_date(conn: sqlite3.Connection):
    for challenge_id in ("daily-a", "daily-b", "weekly-a", "weekly-b"):
        period = "daily" if challenge_id.startswith("daily") else "weekly"
        _insert_challenge(conn, challenge_id, period)

    first = get_active_challenges(conn, date(2026, 10, 9))
    second = get_active_challenges(conn, date(2026, 10, 9))

    assert first[0] is not None and second[0] is not None
    assert first[1] is not None and second[1] is not None
    assert (first[0].id, first[1].id) == (second[0].id, second[1].id)


def test_selection_uses_only_reviewed_challenges(conn: sqlite3.Connection):
    _insert_challenge(conn, "daily-hidden", "daily", reviewed=False)
    _insert_challenge(conn, "weekly-hidden", "weekly", reviewed=False)
    _insert_challenge(conn, "daily-reviewed", "daily")
    _insert_challenge(conn, "weekly-reviewed", "weekly")

    daily, weekly = get_active_challenges(conn, date(2026, 10, 9))

    assert daily is not None and daily.id == "daily-reviewed"
    assert weekly is not None and weekly.id == "weekly-reviewed"


def test_selection_returns_correct_challenge_periods(conn: sqlite3.Connection):
    _insert_challenge(conn, "daily-a", "daily")
    _insert_challenge(conn, "weekly-a", "weekly")

    daily, weekly = get_active_challenges(conn)

    assert isinstance(daily, Challenge)
    assert isinstance(weekly, Challenge)
    assert daily.period == "daily"
    assert weekly.period == "weekly"
    assert daily.points == 15
    assert weekly.points == 50


def test_unreviewed_challenges_are_not_exposed_and_endpoint_returns_503(
    conn: sqlite3.Connection,
):
    _insert_challenge(conn, "daily-a", "daily", reviewed=False)
    _insert_challenge(conn, "weekly-a", "weekly")

    daily, weekly = get_active_challenges(conn, date.today())
    assert daily is None
    assert weekly is not None
    with pytest.raises(HTTPException) as exc_info:
        get_challenges(user_id=None, conn=conn)

    assert exc_info.value.status_code == 503
    assert "daily" in exc_info.value.detail


def test_endpoint_marks_challenge_completed_from_points_ledger(conn: sqlite3.Connection):
    _insert_challenge(conn, "daily-a", "daily")
    _insert_challenge(conn, "weekly-a", "weekly")
    conn.execute(
        "INSERT INTO points_ledger (user_id, reason, ref_id) VALUES (?, ?, ?)",
        ("user-1", "daily_challenge", "daily-a"),
    )
    conn.commit()

    response = get_challenges(user_id="user-1", conn=conn)

    assert response.daily.completed_by_user is True
    assert response.weekly.completed_by_user is False
    assert "reviewed" not in response.daily.model_dump()


def test_safety_filter_blocks_risk_and_private_property_terms():
    safe = {
        "title": "Find a leaf",
        "description": "Explore a public park during daylight.",
        "visual_criterion": "A leaf with visible veins appears in the photo.",
    }
    unsafe = {
        **safe,
        "visual_criterion": "Photograph a view from an azotea.",
    }

    assert is_safe(safe)
    assert not is_safe(unsafe)


def test_generated_challenges_are_inserted_unreviewed_and_deduplicated(
    conn: sqlite3.Connection,
):
    draft = ChallengeDraft(
        title="Find a leaf pattern",
        description="Photograph a naturally fallen leaf.",
        visual_criterion="A fallen leaf with branching veins is visible.",
        period="daily",
        difficulty="easy",
    )

    assert _insert_drafts([draft], conn) == (1, 0)
    assert _insert_drafts([draft], conn) == (0, 1)
    row = conn.execute(
        "SELECT points, reviewed FROM challenges WHERE title = ?", (draft.title,)
    ).fetchone()
    assert row["points"] == 15
    assert row["reviewed"] == 0
