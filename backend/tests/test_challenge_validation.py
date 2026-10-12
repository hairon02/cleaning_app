"""Challenge result scoring tests for feature 010."""

import sqlite3

import pytest

from app.challenges import Challenge
from app.pipeline.challenge_validator import (
    get_challenges_to_validate,
    validate_challenges,
)
from app.pipeline.verify import ChallengeCheckResult
from app.scoring import get_user_total


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
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id TEXT NOT NULL,
            reason TEXT NOT NULL,
            amount INTEGER NOT NULL,
            ref_id TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (user_id) REFERENCES users(id)
        );
        CREATE UNIQUE INDEX uq_points_ledger_idempotency
            ON points_ledger(user_id, reason, COALESCE(ref_id, ''));
        INSERT INTO users (id, display_name) VALUES ('user-1', 'Test User');
        INSERT INTO challenges VALUES
            ('daily-1', 'Find a leaf', 'Find a leaf in a park.',
             'A leaf is clearly visible.', 'daily', 'easy', 15, 1),
            ('weekly-1', 'Find a tree', 'Find a tree in a public space.',
             'A tree trunk is clearly visible.', 'weekly', 'easy', 50, 1),
            ('daily-unreviewed', 'Unreviewed', 'Hidden challenge.',
             'A plant is visible.', 'daily', 'easy', 15, 0);
        """
    )
    connection.commit()
    try:
        yield connection
    finally:
        connection.close()


def test_verified_challenges_award_period_points_once(conn: sqlite3.Connection):
    challenges = get_challenges_to_validate("user-1", conn)
    results = [
        ChallengeCheckResult(challenge_id="daily-1", meets_criterion=True),
        ChallengeCheckResult(challenge_id="weekly-1", meets_criterion=True),
        ChallengeCheckResult(challenge_id="not-in-prompt", meets_criterion=True),
    ]

    completed = validate_challenges("user-1", challenges, results, conn)
    repeated = validate_challenges("user-1", challenges, results, conn)

    assert set(completed) == {"Find a leaf", "Find a tree"}
    assert repeated == []
    assert get_user_total("user-1", conn) == 65
    assert len(get_challenges_to_validate("user-1", conn)) == 0


def test_nonmatching_or_missing_gemma_results_award_nothing(conn: sqlite3.Connection):
    challenges = get_challenges_to_validate("user-1", conn)
    results = [
        ChallengeCheckResult(challenge_id="daily-1", meets_criterion=False),
    ]

    assert validate_challenges("user-1", challenges, results, conn) == []
    assert validate_challenges("user-1", challenges, [], conn) == []
    assert get_user_total("user-1", conn) == 0


def test_only_reviewed_challenges_are_passed_for_validation(conn: sqlite3.Connection):
    challenges = get_challenges_to_validate("user-1", conn)

    assert {challenge.id for challenge in challenges} == {"daily-1", "weekly-1"}


def test_duplicate_result_does_not_award_twice(conn: sqlite3.Connection):
    challenge = Challenge(
        id="daily-1",
        title="Find a leaf",
        description="Find a leaf in a park.",
        visual_criterion="A leaf is clearly visible.",
        period="daily",
        difficulty="easy",
        points=15,
    )
    result = ChallengeCheckResult(challenge_id="daily-1", meets_criterion=True)

    assert validate_challenges("user-1", [challenge], [result, result], conn) == [
        "Find a leaf"
    ]
    assert get_user_total("user-1", conn) == 15
