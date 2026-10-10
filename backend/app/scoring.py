"""Idempotent point awards and streak calculations backed by the ledger."""

import sqlite3
from datetime import date, datetime, timedelta, timezone
from enum import StrEnum

from app.config import (
    POINTS_DAILY_CHALLENGE,
    POINTS_NEW_CELL,
    POINTS_PHOTO_VERIFIED,
    POINTS_STREAK_DAY,
    POINTS_WEEKLY_CHALLENGE,
)


class PointReason(StrEnum):
    PHOTO_VERIFIED = "photo_verified"
    NEW_CELL = "new_cell"
    DAILY_CHALLENGE = "daily_challenge"
    WEEKLY_CHALLENGE = "weekly_challenge"
    STREAK_DAY = "streak_day"


POINTS_BY_REASON = {
    PointReason.PHOTO_VERIFIED: POINTS_PHOTO_VERIFIED,
    PointReason.NEW_CELL: POINTS_NEW_CELL,
    PointReason.DAILY_CHALLENGE: POINTS_DAILY_CHALLENGE,
    PointReason.WEEKLY_CHALLENGE: POINTS_WEEKLY_CHALLENGE,
    PointReason.STREAK_DAY: POINTS_STREAK_DAY,
}


def award_points(
    user_id: str,
    reason: PointReason | str,
    amount: int,
    ref_id: str | None,
    conn: sqlite3.Connection,
) -> bool:
    """Insert one point award; return False when its idempotency key exists."""
    try:
        point_reason = PointReason(reason)
    except ValueError as exc:
        raise ValueError(f"unsupported point reason: {reason}") from exc
    if amount <= 0:
        raise ValueError("point awards must be positive")
    if ref_id == "":
        ref_id = None
    cursor = conn.execute(
        """
        INSERT OR IGNORE INTO points_ledger (user_id, reason, amount, ref_id)
        VALUES (?, ?, ?, ?)
        """,
        (user_id, point_reason.value, amount, ref_id),
    )
    conn.commit()
    return cursor.rowcount == 1


def _photo_activity_dates(user_id: str, conn: sqlite3.Connection) -> list[date]:
    rows = conn.execute(
        """
        SELECT DISTINCT date(created_at) AS activity_date
        FROM points_ledger
        WHERE user_id = ? AND reason = ?
        ORDER BY activity_date DESC
        """,
        (user_id, PointReason.PHOTO_VERIFIED.value),
    ).fetchall()
    return [date.fromisoformat(row["activity_date"]) for row in rows]


def _check_and_award_streak(user_id: str, conn: sqlite3.Connection) -> bool:
    """Award one daily streak bonus when the latest photo day follows another."""
    activity_dates = _photo_activity_dates(user_id, conn)
    if len(activity_dates) < 2:
        return False
    latest, previous = activity_dates[:2]
    if latest - previous != timedelta(days=1):
        return False
    return award_points(
        user_id,
        PointReason.STREAK_DAY,
        POINTS_BY_REASON[PointReason.STREAK_DAY],
        latest.isoformat(),
        conn,
    )


def get_user_total(user_id: str, conn: sqlite3.Connection) -> int:
    row = conn.execute(
        "SELECT COALESCE(SUM(amount), 0) AS total FROM points_ledger WHERE user_id = ?",
        (user_id,),
    ).fetchone()
    return int(row["total"])


def get_streak_days(user_id: str, conn: sqlite3.Connection) -> int:
    """Return the active consecutive UTC days with verified-photo awards."""
    activity_dates = _photo_activity_dates(user_id, conn)
    if not activity_dates:
        return 0
    today_utc = datetime.now(timezone.utc).date()
    if activity_dates[0] not in {today_utc, today_utc - timedelta(days=1)}:
        return 0

    streak = 1
    for newer, older in zip(activity_dates, activity_dates[1:]):
        if newer - older != timedelta(days=1):
            break
        streak += 1
    return streak
