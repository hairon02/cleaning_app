import json
from pathlib import Path

import pytest
from PIL import Image

from app.pipeline.verify import (
    ChallengeCriterion,
    GemmaError,
    GemmaResult,
    verify_photo,
)


@pytest.fixture
def sample_image(tmp_path: Path) -> Path:
    img_path = tmp_path / "test_park.jpg"
    img = Image.new("RGB", (100, 100), color="green")
    img.save(img_path)
    return img_path


def test_verify_photo_success(sample_image: Path):
    mock_response = json.dumps({
        "is_outdoor": True,
        "description": "A green park with trees",
        "tags": ["park", "tree", "green"],
        "time_of_day": "morning",
        "weather": "sunny"
    })

    result = verify_photo(
        str(sample_image),
        backend_caller=lambda path, prompt: mock_response
    )

    assert isinstance(result, GemmaResult)
    assert result.is_outdoor is True
    assert result.description == "A green park with trees"
    assert "park" in result.tags
    assert result.time_of_day == "morning"
    assert result.weather == "sunny"


def test_verify_photo_markdown_json_cleaning(sample_image: Path):
    mock_response = """
    Aquí está la respuesta:
    ```json
    {
        "is_outdoor": false,
        "description": "A laptop screen",
        "tags": ["screen", "keyboard"],
        "time_of_day": "night",
        "weather": "unknown"
    }
    ```
    I hope this helps.
    """

    result = verify_photo(
        str(sample_image),
        backend_caller=lambda path, prompt: mock_response
    )

    assert result.is_outdoor is False
    assert result.description == "A laptop screen"
    assert result.tags == ["screen", "keyboard"]


def test_verify_photo_retry_success(sample_image: Path):
    attempts = 0

    def mock_flaky_backend(path: str, prompt: str) -> str:
        nonlocal attempts
        attempts += 1
        if attempts == 1:
            return "I am not a valid json!"
        return json.dumps({
            "is_outdoor": True,
            "description": "A forest after retry",
            "tags": ["forest"],
            "time_of_day": "afternoon",
            "weather": "cloudy"
        })

    result = verify_photo(
        str(sample_image),
        backend_caller=mock_flaky_backend,
        max_retries=2
    )

    assert attempts == 2
    assert result.is_outdoor is True
    assert result.description == "A forest after retry"


def test_verify_photo_failure_raises_gemma_error(sample_image: Path):
    def mock_broken_backend(path: str, prompt: str) -> str:
        return "The response is never valid JSON."

    with pytest.raises(GemmaError) as exc_info:
        verify_photo(
            str(sample_image),
            backend_caller=mock_broken_backend,
            max_retries=1
        )

    assert "Failed to verify photo" in str(exc_info.value)


def test_verify_photo_includes_challenge_criteria_in_same_prompt(sample_image: Path):
    prompts = []
    response = json.dumps(
        {
            "is_outdoor": True,
            "description": "A park with a leaf",
            "tags": ["park", "leaf", "tree"],
            "time_of_day": "afternoon",
            "weather": "sunny",
            "challenge_results": [
                {
                    "challenge_id": "daily-1",
                    "meets_criterion": True,
                    "reason": "A leaf is clearly visible.",
                }
            ],
        }
    )

    result = verify_photo(
        str(sample_image),
        backend_caller=lambda _path, prompt: prompts.append(prompt) or response,
        challenge_criteria=[
            ChallengeCriterion(
                challenge_id="daily-1",
                title="Find a leaf",
                visual_criterion="A leaf is clearly visible.",
            )
        ],
    )

    assert len(prompts) == 1
    assert "A leaf is clearly visible." in prompts[0]
    assert "challenge_results" in prompts[0]
    assert result.is_outdoor is True
    assert result.challenge_results[0].challenge_id == "daily-1"
    assert result.challenge_results[0].meets_criterion is True


def test_invalid_challenge_result_does_not_fail_photo_verification(sample_image: Path):
    response = json.dumps(
        {
            "is_outdoor": True,
            "description": "A park",
            "tags": ["park", "trees", "grass"],
            "challenge_results": [{"challenge_id": "daily-1", "meets_criterion": "maybe"}],
        }
    )

    result = verify_photo(
        str(sample_image),
        backend_caller=lambda _path, _prompt: response,
        challenge_criteria=[
            ChallengeCriterion(
                challenge_id="daily-1",
                title="Find a leaf",
                visual_criterion="A leaf is clearly visible.",
            )
        ],
    )

    assert result.is_outdoor is True
    assert result.challenge_results == []
