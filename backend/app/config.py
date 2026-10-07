import os
from pathlib import Path

from dotenv import load_dotenv

load_dotenv()

BASE_DIR = Path(__file__).resolve().parent.parent

DB_PATH = Path(os.getenv("DB_PATH", str(BASE_DIR / "clearing.db")))
UPLOAD_DIR = Path(os.getenv("UPLOAD_DIR", str(BASE_DIR / "uploads")))
SCHEMA_PATH = BASE_DIR / "schema.sql"

CELL_SIZE_M = int(os.getenv("CELL_SIZE_M", "200"))
PHASH_THRESHOLD = int(os.getenv("PHASH_THRESHOLD", "10"))

GEMMA_MODEL = os.getenv("GEMMA_MODEL", "gemma3n:e4b")
GEMMA_BACKEND = os.getenv("GEMMA_BACKEND", "ollama")
GEMMA_MAX_RETRIES = int(os.getenv("GEMMA_MAX_RETRIES", "2"))

POINTS_PHOTO_VERIFIED = int(os.getenv("POINTS_PHOTO_VERIFIED", "10"))
POINTS_NEW_CELL = int(os.getenv("POINTS_NEW_CELL", "20"))
POINTS_DAILY_CHALLENGE = int(os.getenv("POINTS_DAILY_CHALLENGE", "15"))
POINTS_WEEKLY_CHALLENGE = int(os.getenv("POINTS_WEEKLY_CHALLENGE", "50"))
POINTS_STREAK_DAY = int(os.getenv("POINTS_STREAK_DAY", "5"))
