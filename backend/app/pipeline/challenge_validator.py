"""Evaluate already-generated challenge results and award completion points."""

import logging
import sqlite3
from collections.abc import Sequence

from app.challenges import Challenge, get_active_challenges
from app.pipeline.verify import ChallengeCheckResult, ChallengeCriterion
from app.scoring import PointReason, award_points

logger = logging.getLogger(__name__)


def get_challenges_to_validate(
    user_id: str,
    conn: sqlite3.Connection,
) -> list[Challenge]:
    """Get today's reviewed challenges the user has not already completed."""
    daily, weekly = get_active_challenges(conn)
    pending: list[Challenge] = []
    for challenge in (daily, weekly):
        if challenge is None:
            continue
        reason = (
            PointReason.DAILY_CHALLENGE
            if challenge.period == "daily"
            else PointReason.WEEKLY_CHALLENGE
        )
        existing = conn.execute(
            """
            SELECT 1 FROM points_ledger
            WHERE user_id = ? AND reason = ? AND ref_id = ?
            LIMIT 1
            """,
            (user_id, reason.value, challenge.id),
        ).fetchone()
        if existing is None:
            pending.append(challenge)
    return pending


def build_challenge_criteria(challenges: Sequence[Challenge]) -> list[ChallengeCriterion]:
    """Convert database challenges into the minimal data passed to Gemma."""
    return [
        ChallengeCriterion(
            challenge_id=challenge.id,
            title=challenge.title,
            visual_criterion=challenge.visual_criterion,
        )
        for challenge in challenges
    ]


def validate_challenges(
    user_id: str,
    challenges: Sequence[Challenge],
    results: Sequence[ChallengeCheckResult],
    conn: sqlite3.Connection,
) -> list[str]:
    """Award completed challenges once and return their titles for the upload response."""
    challenge_by_id = {challenge.id: challenge for challenge in challenges}
    completed_titles: list[str] = []
    seen: set[str] = set()
    for result in results:
        challenge = challenge_by_id.get(result.challenge_id)
        if challenge is None or not result.meets_criterion or challenge.id in seen:
            continue
        seen.add(challenge.id)
        reason = (
            PointReason.DAILY_CHALLENGE
            if challenge.period == "daily"
            else PointReason.WEEKLY_CHALLENGE
        )
        awarded = award_points(
            user_id,
            reason,
            challenge.points,
            challenge.id,
            conn,
        )
        if awarded:
            completed_titles.append(challenge.title)
    return completed_titles
