# Clearing 🌿

> A mobile web app (PWA) that clears the fog of war from your map only when you go outside and take a real photo of the location. Verified locally using Gemma 3n (vision) running on your laptop—no photos or GPS coordinates ever touch the cloud or third-party APIs.

---

## What Makes It Different

Traditional "fog of war" apps passively clear the map based on GPS movement. In Clearing, the fog only clears when a photo passes on-device AI verification. The local model is an essential core mechanic, not an afterthought.

- **"Touch Grass" Philosophy:** The camera is the primary screen. The map and journal are quick rewards viewed for a few seconds. All value happens outdoors.
- **Privacy by Design:** Photos, location, and metadata are processed entirely on your local machine.
- **Zero Cost per Photo:** No paid vision APIs.
- **Objective Progression:** Points and leaderboard positions are earned through objective rules (verified photos, newly cleared grid cells, completed challenges, streaks). No subjective AI scoring or social voting.

---

## Architecture & Tech Stack

- **Client:** Flutter Web installed as an iOS/Safari PWA.
- **Backend:** FastAPI (Python 3.11+) + SQLite (`sqlite3` stdlib with explicit SQL schema).
- **Local AI:** Gemma 3n (vision) executed locally via Ollama or `transformers`.
- **Duplicate Prevention:** Perceptual hashing (`imagehash` + Pillow) without model overhead.
- **Mapping:** `flutter_map` with OpenStreetMap tile overlays.
- **Deployment & Networking:** 100% local on host machine, exposed via HTTPS tunnel (Cloudflare Tunnel or mkcert) for iPhone access.

---

## Prerequisites

- **Python 3.11+**
- **Flutter SDK 3.13+** (with web platform enabled)
- **Ollama** with a multimodal Gemma model pulled (or local environment with `transformers`)

---

## Getting Started in Development

### 1. Backend (FastAPI + SQLite)

```bash
# Navigate to the backend directory
cd backend

# Create and activate virtual environment
python -m venv .venv
# On Windows (PowerShell):
.venv\Scripts\Activate.ps1
# On Linux / macOS:
source .venv/bin/activate

# Install dependencies
pip install -r requirements.txt pytest ruff

# Set up local environment variables
cp .env.example .env

# Start the local development server
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

- Health check: [http://localhost:8000/health](http://localhost:8000/health)
- Interactive API docs (Swagger): [http://localhost:8000/docs](http://localhost:8000/docs)

#### Tests & Code Quality
```bash
# Run backend test suite
pytest

# Check code formatting and linting
ruff check .
```

---

### 2. Frontend (Flutter Web)

The client application is located in `app/clearing/`:

```bash
cd app/clearing

# Fetch dependencies
flutter pub get

# Run development mode in Chrome
flutter run -d chrome
```

To create the production web bundle served by FastAPI:
```bash
flutter build web
```

---

## Methodology & Specifications (SDD)

This repository follows **Spec Driven Development (SDD)**:
- **Constitution:** Mission, architectural principles, and tech constraints live in [`spec/constitution/`](file:///C:/Users/hairo/Documents/Clearing/spec/constitution).
- **Roadmap:** The chronological delivery sequence is tracked in [`spec/constitution/roadmap.md`](file:///C:/Users/hairo/Documents/Clearing/spec/constitution/roadmap.md).
- **Features:** Each feature follows a strict lifecycle (`spec.md` -> `plan.md` -> `tasks.md`) under [`spec/features/`](file:///C:/Users/hairo/Documents/Clearing/spec/features).