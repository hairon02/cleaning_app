"""Leaderboard endpoints backed by the points ledger."""

import sqlite3
from typing import Annotated

from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel

from app.db import get_db
from app.scoring import get_streak_days, get_user_total

router = APIRouter()


class RankingEntry(BaseModel):
    position: int
    user_id: str
    display_name: str
    total_points: int
    streak_days: int


class RankingMe(BaseModel):
    user_id: str
    position: int | None
    total_points: int
    streak_days: int


def _ranked_totals(conn: sqlite3.Connection) -> list[sqlite3.Row]:
    return conn.execute(
        """
        SELECT users.id AS user_id,
               users.display_name,
               SUM(points_ledger.amount) AS total_points
        FROM points_ledger
        JOIN users ON users.id = points_ledger.user_id
        GROUP BY users.id, users.display_name
        HAVING SUM(points_ledger.amount) > 0
        ORDER BY total_points DESC, users.id ASC
        """
    ).fetchall()


@router.get("/ranking", response_model=list[RankingEntry])
def get_ranking(conn: sqlite3.Connection = Depends(get_db)) -> list[RankingEntry]:
    """Return the top 20 users without exposing location data."""
    return [
        RankingEntry(
            position=position,
            user_id=row["user_id"],
            display_name=row["display_name"],
            total_points=int(row["total_points"]),
            streak_days=get_streak_days(row["user_id"], conn),
        )
        for position, row in enumerate(_ranked_totals(conn)[:20], start=1)
    ]


@router.get("/ranking/me", response_model=RankingMe)
def get_my_ranking(
    user_id: Annotated[str, Query(min_length=1)],
    conn: sqlite3.Connection = Depends(get_db),
) -> RankingMe:
    """Return a user's global position, total, and active photo streak."""
    rows = _ranked_totals(conn)
    position = next(
        (index for index, row in enumerate(rows, start=1) if row["user_id"] == user_id),
        None,
    )
    return RankingMe(
        user_id=user_id,
        position=position,
        total_points=get_user_total(user_id, conn),
        streak_days=get_streak_days(user_id, conn),
    )
