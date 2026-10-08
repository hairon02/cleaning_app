import base64
import importlib.util
import json
import logging
import re
from pathlib import Path
from typing import Callable, Optional

import httpx
from pydantic import BaseModel, Field

from app.config import (
    BASE_DIR,
    GEMMA_BACKEND,
    GEMMA_MAX_RETRIES,
    GEMMA_MODEL,
)

logger = logging.getLogger(__name__)

PROMPT_FILE = BASE_DIR / "prompts" / "verify.txt"


class GemmaError(Exception):
    """Raised when Gemma fails to provide a valid response after retries."""

    pass


class GemmaResult(BaseModel):
    is_outdoor: bool
    description: str
    tags: list[str] = Field(default_factory=list)
    time_of_day: str = "unknown"
    weather: str = "unknown"


def _load_prompt_template() -> str:
    if PROMPT_FILE.exists():
        return PROMPT_FILE.read_text(encoding="utf-8")
    return (
        "You are a strict visual classifier. "
        "Return only a JSON object with {is_outdoor, description, tags, time_of_day, weather}."
    )


# Loaded once at import time
PROMPT_TEMPLATE = _load_prompt_template()


def _clean_json_output(raw_text: str) -> str:
    """Extract and sanitize JSON from model raw text response."""
    text = raw_text.strip()

    # Strip markdown code blocks like ```json ... ``` or ``` ... ```
    match = re.search(r"```(?:json)?\s*([\s\S]*?)\s*```", text, re.IGNORECASE)
    if match:
        text = match.group(1).strip()

    # Sometimes extra explanation text wraps JSON, find first { and last }
    first_brace = text.find("{")
    last_brace = text.rfind("}")
    if first_brace != -1 and last_brace != -1 and last_brace > first_brace:
        text = text[first_brace : last_brace + 1]

    return text


def _call_ollama(
    image_path: str,
    prompt: str,
    model: str = GEMMA_MODEL,
    host: str = "http://localhost:11434",
) -> str:
    """Call local Ollama API with base64 encoded image."""
    img_bytes = Path(image_path).read_bytes()
    b64_img = base64.b64encode(img_bytes).decode("utf-8")

    payload = {
        "model": model,
        "prompt": prompt,
        "images": [b64_img],
        "stream": False,
        "format": "json",
        "options": {"temperature": 0},
    }

    try:
        with httpx.Client(timeout=120.0) as client:
            resp = client.post(f"{host}/api/generate", json=payload)
            if resp.is_error:
                # Ollama puts the actionable cause in the response body (for
                # example, when a text-only model receives an image).
                detail = resp.text.strip()
                raise GemmaError(
                    f"Ollama API returned HTTP {resp.status_code}"
                    + (f": {detail}" if detail else "")
                )
            data = resp.json()
            return data.get("response", "")
    except GemmaError:
        raise
    except Exception as exc:
        raise GemmaError(f"Ollama API request failed: {exc}") from exc


def _call_transformers(
    image_path: str,
    prompt: str,
    model: str = GEMMA_MODEL,
) -> str:
    """Stub / implementation for running via transformers AutoModelForVision2Seq."""
    if (
        importlib.util.find_spec("torch") is None
        or importlib.util.find_spec("transformers") is None
    ):
        raise GemmaError(
            "transformers / torch dependencies not installed for GEMMA_BACKEND=transformers"
        )

    # In transformers, vision pipeline can process image and prompt
    raise NotImplementedError(
        "Transformers vision backend not loaded or device unavailable."
    )


def verify_photo(
    image_path: str,
    backend_caller: Optional[Callable[[str, str], str]] = None,
    max_retries: int = GEMMA_MAX_RETRIES,
) -> GemmaResult:
    """Verify photo with Gemma and return structured GemmaResult.

    Retries on JSON decoding or Pydantic validation failure.
    Raises GemmaError if unsuccessful.
    """
    path = Path(image_path)
    if not path.is_file():
        raise FileNotFoundError(f"Image not found at {image_path}")

    if backend_caller is None:
        if GEMMA_BACKEND == "transformers":
            def default_caller(img: str, pr: str) -> str:
                return _call_transformers(img, pr)
        else:
            def default_caller(img: str, pr: str) -> str:
                return _call_ollama(img, pr)
        backend_caller = default_caller

    current_prompt = PROMPT_TEMPLATE
    last_error: Optional[Exception] = None

    for attempt in range(max_retries + 1):
        try:
            raw_response = backend_caller(str(path), current_prompt)
            clean_json = _clean_json_output(raw_response)
            data = json.loads(clean_json)
            result = GemmaResult.model_validate(data)
            return result
        except Exception as exc:
            last_error = exc
            logger.warning(
                "Attempt %d/%d failed verifying photo %s: %s",
                attempt + 1,
                max_retries + 1,
                image_path,
                exc,
            )
            # Enhance prompt on retry with instruction to correct the JSON
            current_prompt = (
                f"{PROMPT_TEMPLATE}\n\n"
                f"IMPORTANT: Your previous response caused a validation error ({exc}). "
                f"Make sure to respond ONLY with a valid and well-formed JSON object."
            )

    raise GemmaError(
        f"Failed to verify photo after {max_retries + 1} attempts. Last error: {last_error}"
    ) from last_error
