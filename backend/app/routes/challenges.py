"""Challenge bank API."""

import sqlite3

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel

from app.challenges import Challenge, get_active_challenges
from app.db import get_db

router = APIRouter(tags=["challenges"])


class ActiveChallenge(Challenge):
    completed_by_user: bool = False


class ActiveChallengesResponse(BaseModel):
    daily: ActiveChallenge
    weekly: ActiveChallenge


def _completed_challenge_ids(user_id: str, conn: sqlite3.Connection) -> set[str]:
    rows = conn.execute(
        """
        SELECT ref_id FROM points_ledger
        WHERE user_id = ? AND reason IN ('daily_challenge', 'weekly_challenge')
          AND ref_id IS NOT NULL
        """,
        (user_id,),
    ).fetchall()
    return {row["ref_id"] for row in rows}


@router.get("/challenges", response_model=ActiveChallengesResponse)
def get_challenges(
    user_id: str | None = Query(default=None),
    conn: sqlite3.Connection = Depends(get_db),
) -> ActiveChallengesResponse:
    daily, weekly = get_active_challenges(conn)
    if daily is None or weekly is None:
        missing = []
        if daily is None:
            missing.append("daily")
        if weekly is None:
            missing.append("weekly")
        raise HTTPException(
            status_code=503,
            detail=f"No reviewed {' and '.join(missing)} challenge is available.",
        )

    completed_ids = _completed_challenge_ids(user_id, conn) if user_id else set()
    return ActiveChallengesResponse(
        daily=ActiveChallenge(**daily.model_dump(), completed_by_user=daily.id in completed_ids),
        weekly=ActiveChallenge(**weekly.model_dump(), completed_by_user=weekly.id in completed_ids),
    )
