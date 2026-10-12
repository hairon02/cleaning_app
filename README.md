# Clearing 🌿

> **Repository:** [hairon02/cleaning_app](https://github.com/hairon02/cleaning_app) · **Maintainer:** [@hairon02](https://github.com/hairon02)

> A mobile web app (PWA) that clears the fog of war from your map when you go outside and take a real photo. Photos are verified by a Gemma vision model running locally on your computer. Photos and exact GPS coordinates stay on your local backend; map tiles are fetched from a map provider.

---

## What Makes It Different

Traditional "fog of war" apps passively clear the map based on GPS movement. In Clearing, the fog only clears when a photo passes on-device AI verification. The local model is an essential core mechanic, not an afterthought.

- **"Touch Grass" Philosophy:** The camera is the primary screen. The map and journal are quick rewards viewed for a few seconds. All value happens outdoors.
- **Privacy by Design:** Photos, location, and metadata are processed by the backend running on your local machine.
- **No paid vision API:** Photo verification runs against a local model.
- **Objective Progression:** Points and leaderboard positions are earned through objective rules (verified photos, newly cleared grid cells, completed challenges, streaks). No subjective AI scoring or social voting.

---

## Architecture & Tech Stack

- **Client:** Flutter Web installed as an iOS/Safari PWA.
- **Backend:** FastAPI (Python 3.11+) + SQLite (`sqlite3` stdlib with explicit SQL schema).
- **Local AI:** Gemma 3n (vision) executed locally via Ollama or `transformers`.
- **Duplicate Prevention:** Perceptual hashing (`imagehash` + Pillow) without model overhead.
- **Mapping:** Flutter map widgets with a Mapbox map style.
- **Deployment & Networking:** The backend and model run on the host machine. An HTTPS tunnel can provide access from an iPhone during development.

---

## Prerequisites

- **Python 3.11+**
- **Flutter SDK 3.13+** (with web platform enabled)
- **Ollama** with a multimodal Gemma model pulled (or local environment with `transformers`)

---

## Getting Started in Development

Run the backend and Flutter app in separate terminals. The examples below use
PowerShell on Windows; macOS/Linux activation and copy commands are included.

### 1. Backend (FastAPI + SQLite)

```bash
cd backend
python -m venv .venv
```

Activate the environment and create the local settings file:

```powershell
.venv\Scripts\Activate.ps1
Copy-Item .env.example .env
```

On macOS/Linux, use `source .venv/bin/activate` and `cp .env.example .env`.
Edit `backend/.env` if you need to change the database, upload directory, or
local Gemma model. Make sure Ollama is running and has the configured model.

Install dependencies and start the API:

```bash
pip install -r requirements.txt ruff
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

In a second terminal, configure the client and run it in Chrome:

```powershell
cd app/clearing
Copy-Item .env.example .env
```

On macOS/Linux, use `cp .env.example .env`. Edit `app/clearing/.env` and set
your Mapbox public access token and `API_BASE_URL=http://localhost:8000` for
local Chrome development. Restrict the Mapbox token to the domains you use.

Then run:

```bash
flutter pub get
flutter run -d chrome
```

### 3. Open the app on an iPhone (development tunnels)

Use four terminals. Start the backend as above, then expose the API with ngrok:

```bash
ngrok http 8000
```

Copy the HTTPS URL printed by ngrok and set it as `API_BASE_URL` in
`app/clearing/.env` (omit a trailing slash). Restart Flutter after changing the
URL.

In another terminal, start Flutter's web development server:

```powershell
cd app/clearing
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 5000
```

Then expose the frontend on port 5000 with Cloudflare Tunnel:

```bash
cloudflared tunnel --url http://localhost:5000
```

Open the `https://…trycloudflare.com` URL printed by `cloudflared` in Safari.
These tunnel URLs are temporary; keep both tunnel processes running while using
the app and do not commit their URLs or local `.env` files.

To create a production web bundle, set `API_BASE_URL` to the HTTPS address of
your backend before building:

```bash
flutter build web
```

The bundle is written to `app/clearing/build/web/`. Host that directory over
HTTPS; the backend currently serves the API, not the Flutter web bundle. The
frontend `.env` is bundled with the app, so only put public configuration such
as a domain-restricted Mapbox public token and the API URL in it.

---

## Methodology & Specifications (SDD)

This repository follows **Spec Driven Development (SDD)**:
- **Constitution:** Mission, architectural principles, and tech constraints live in [`spec/constitution/`](spec/constitution/).
- **Roadmap:** The chronological delivery sequence is tracked in [`spec/constitution/roadmap.md`](spec/constitution/roadmap.md).
- **Features:** Each feature follows a lifecycle (`spec.md` → `plan.md` → `tasks.md`) under [`spec/features/`](spec/features/).
