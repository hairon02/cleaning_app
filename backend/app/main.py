from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import UPLOAD_DIR
from app.db import init_db
from app.routes.map import router as map_router
from app.routes.ranking import router as ranking_router
from app.routes.upload import router as upload_router


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

# Flutter Web is served from the HTTPS tunnel while the API runs locally.
# The anonymous MVP does not use cookies or credentialed requests.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_origin_regex=r"https?://.*",
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(upload_router, prefix="/api")
app.include_router(map_router, prefix="/api")
app.include_router(ranking_router, prefix="/api")


@app.get("/health")
async def health_check():
    return {"status": "ok"}
