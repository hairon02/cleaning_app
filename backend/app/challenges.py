"""Reviewed challenge bank and deterministic daily/weekly selection."""

import sqlite3
from datetime import date
from typing import Literal

from pydantic import BaseModel

from app.config import POINTS_DAILY_CHALLENGE, POINTS_WEEKLY_CHALLENGE


class Challenge(BaseModel):
    id: str
    title: str
    description: str
    visual_criterion: str
    period: Literal["daily", "weekly"]
    difficulty: Literal["easy", "medium", "hard"]
    points: int


def _select_challenge(
    conn: sqlite3.Connection,
    period: Literal["daily", "weekly"],
    today: date,
) -> Challenge | None:
    rows = conn.execute(
        """
        SELECT id, title, description, visual_criterion, period, difficulty, points
        FROM challenges
        WHERE period = ? AND reviewed = 1
        ORDER BY id
        """,
        (period,),
    ).fetchall()
    if not rows:
        return None

    if period == "daily":
        period_index = today.toordinal()
    else:
        iso = today.isocalendar()
        period_index = iso.year * 53 + iso.week
    row = rows[period_index % len(rows)]
    return Challenge.model_validate(dict(row))


def get_active_challenges(
    conn: sqlite3.Connection,
    today: date | None = None,
) -> tuple[Challenge | None, Challenge | None]:
    """Return the reviewed daily and weekly challenges active for a date."""
    selection_date = today or date.today()
    return (
        _select_challenge(conn, "daily", selection_date),
        _select_challenge(conn, "weekly", selection_date),
    )


def challenge_points(period: Literal["daily", "weekly"]) -> int:
    """Return the configured point value for a challenge period."""
    return POINTS_DAILY_CHALLENGE if period == "daily" else POINTS_WEEKLY_CHALLENGE
