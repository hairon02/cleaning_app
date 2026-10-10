"""Generate safe challenge drafts with local Ollama and insert them for review."""

import argparse
import json
import logging
import re
import sqlite3
import sys
import uuid
from pathlib import Path
from typing import Literal

import httpx
from pydantic import BaseModel, Field, ValidationError

BASE_DIR = Path(__file__).resolve().parents[1]
if str(BASE_DIR) not in sys.path:
    sys.path.insert(0, str(BASE_DIR))

from app.challenge_filter import is_safe  # noqa: E402
from app.challenges import challenge_points  # noqa: E402
from app.config import DB_PATH, GEMMA_MODEL  # noqa: E402

logger = logging.getLogger("gen_challenges")
PROMPT_PATH = BASE_DIR / "prompts" / "challenge_gen.txt"
_TOPICS = (
    "a fallen leaf with a visible pattern",
    "a reflection in a public park or on a sidewalk",
    "a tree trunk with visible bark texture",
    "a flower growing in a public green space",
    "a public walking path bordered by plants",
    "a shadow cast on the ground in daylight",
    "a public park bench surrounded by plants",
    "cloud shapes visible above a public outdoor area",
    "a naturally occurring pattern in grass or leaves",
    "a public sidewalk with visible surface patterns",
    "a small group of trees along a public path",
    "sunlight passing through tree leaves",
    "a public garden with multiple kinds of plants",
    "a puddle reflecting nearby plants or trees",
    "a natural stone beside a public walking path",
    "a public outdoor space with a clearly visible tree",
    "a plant growing beside a public sidewalk",
    "a visible contrast between plants and a paved path",
)


class ChallengeDraft(BaseModel):
    title: str = Field(min_length=3, max_length=80)
    description: str = Field(min_length=10, max_length=240)
    visual_criterion: str = Field(min_length=10, max_length=240)
    period: Literal["daily", "weekly"]
    difficulty: Literal["easy", "medium", "hard"]


def _extract_json(text: str) -> str:
    cleaned = text.strip()
    fenced = re.search(r"```(?:json)?\s*([\s\S]*?)\s*```", cleaned, re.IGNORECASE)
    if fenced:
        cleaned = fenced.group(1).strip()
    for opening, closing in (("[", "]"), ("{", "}")):
        start, end = cleaned.find(opening), cleaned.rfind(closing)
        if start >= 0 and end > start:
            return cleaned[start : end + 1]
    raise ValueError("Gemma response does not contain a JSON object or array")


def _generate_batch(
    period: Literal["daily", "weekly"],
    topic: str,
    existing_titles: list[str],
) -> list[ChallengeDraft]:
    prompt = PROMPT_PATH.read_text(encoding="utf-8").format(
        topic=topic,
        period=period,
        existing_titles="\n".join(f"- {title}" for title in existing_titles) or "- none",
    )
    payload: object | None = None
    for attempt in range(3):
        response = httpx.post(
            "http://localhost:11434/api/generate",
            json={
                "model": GEMMA_MODEL,
                "prompt": prompt,
                "stream": False,
                "format": "json",
                "options": {"temperature": 0.5},
            },
            timeout=180.0,
        )
        response.raise_for_status()
        raw = response.json().get("response", "")
        try:
            payload = json.loads(_extract_json(raw))
        except (json.JSONDecodeError, ValueError) as exc:
            logger.warning(
                "Gemma returned invalid challenge JSON (attempt %d/3): %s",
                attempt + 1,
                exc,
            )
            continue
        break
    if isinstance(payload, dict):
        payload = payload.get("challenges", payload.get("items", [payload]))
    if not isinstance(payload, list):
        raise ValueError("Gemma response must be a challenge object or JSON array")
    drafts: list[ChallengeDraft] = []
    seen_titles = {title.casefold() for title in existing_titles}
    for item in payload:
        try:
            draft = ChallengeDraft.model_validate(item)
        except ValidationError as exc:
            logger.warning("Skipping invalid challenge draft: %s", exc)
            continue
        normalized_title = draft.title.casefold()
        if normalized_title in seen_titles:
            logger.warning("Skipping repeated challenge title: %s", draft.title)
            continue
        seen_titles.add(normalized_title)
        existing_titles.append(draft.title)
        if draft.period != period:
            logger.warning("Skipping challenge with wrong period: %s", draft.title)
            continue
        if not is_safe(draft):
            logger.warning("Skipping unsafe challenge: %s", draft.title)
            continue
        drafts.append(draft)
    logger.info("Gemma produced %d safe %s drafts", len(drafts), period)
    return drafts


def _insert_drafts(
    drafts: list[ChallengeDraft],
    conn: sqlite3.Connection,
) -> tuple[int, int]:
    inserted = skipped = 0
    for draft in drafts:
        cursor = conn.execute(
            """
            INSERT INTO challenges
                (id, title, description, visual_criterion, period, difficulty, points, reviewed)
            SELECT ?, ?, ?, ?, ?, ?, ?, 0
            WHERE NOT EXISTS (
                SELECT 1 FROM challenges WHERE lower(title) = lower(?)
            )
            """,
            (
                uuid.uuid4().hex,
                draft.title,
                draft.description,
                draft.visual_criterion,
                draft.period,
                draft.difficulty,
                challenge_points(draft.period),
                draft.title,
            ),
        )
        inserted += cursor.rowcount
        skipped += 1 - cursor.rowcount
    conn.commit()
    return inserted, skipped


def generate_and_store(
    daily_count: int = 14,
    weekly_count: int = 4,
    db_path: Path = DB_PATH,
) -> dict[str, int]:
    """Generate drafts and store them as unreviewed rows; never auto-approve."""
    if daily_count < 0 or weekly_count < 0 or daily_count + weekly_count == 0:
        raise ValueError("At least one non-negative daily or weekly count is required")
    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row
    try:
        existing_counts = {
            row["period"]: row["total"]
            for row in conn.execute(
                "SELECT period, COUNT(*) AS total FROM challenges GROUP BY period"
            ).fetchall()
        }
        generated = {"daily": 0, "weekly": 0}
        inserted = skipped = 0
        periods: tuple[tuple[Literal["daily", "weekly"], int], ...] = (
            ("daily", daily_count),
            ("weekly", weekly_count),
        )
        for period, target_count in periods:
            remaining = max(0, target_count - existing_counts.get(period, 0))
            empty_rounds = 0
            title_rows = conn.execute(
                "SELECT title FROM challenges WHERE period = ? ORDER BY title",
                (period,),
            ).fetchall()
            existing_titles = [row["title"] for row in title_rows]
            while remaining and empty_rounds < 12:
                topic_index = (target_count - remaining + empty_rounds) % len(_TOPICS)
                drafts = _generate_batch(period, _TOPICS[topic_index], existing_titles)
                generated[period] += len(drafts)
                batch_inserted, batch_skipped = _insert_drafts(drafts, conn)
                inserted += batch_inserted
                skipped += batch_skipped
                remaining -= batch_inserted
                empty_rounds = 0 if batch_inserted else empty_rounds + 1
            if remaining:
                raise RuntimeError(
                    f"Could not fill the {period} challenge bank: "
                    f"{remaining} unique safe draft(s) still needed after 12 batches."
                )
        return {
            "generated_daily": generated["daily"],
            "generated_weekly": generated["weekly"],
            "inserted": inserted,
            "duplicates_skipped": skipped,
        }
    finally:
        conn.close()


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--daily", type=int, default=14, help="number of daily drafts (default: 14)"
    )
    parser.add_argument(
        "--weekly", type=int, default=4, help="number of weekly drafts (default: 4)"
    )
    parser.add_argument("--db", type=Path, default=DB_PATH, help="SQLite database path")
    args = parser.parse_args()
    logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")
    result = generate_and_store(args.daily, args.weekly, args.db)
    print(json.dumps(result, indent=2))
    print("All inserted challenges have reviewed=0. Review them manually before publication.")


if __name__ == "__main__":
    main()
