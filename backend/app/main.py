from contextlib import asynccontextmanager

from fastapi import FastAPI

from app.config import UPLOAD_DIR
from app.db import init_db


@asynccontextmanager
async def lifespan(app: FastAPI):
    init_db()
    UPLOAD_DIR.mkdir(parents=True, exist_ok=True)
    yield


app = FastAPI(
    title="Clearing API",
    description="Local backend for AI-powered outdoor verification and fog-of-war map",
    version="0.1.0",
    lifespan=lifespan,
)


@app.get("/health")
async def health_check():
    return {"status": "ok"}
