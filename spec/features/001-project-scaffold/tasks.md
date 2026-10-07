# Tasks — 001 · Project Scaffold

## Backend

- [x] Crear `backend/app/__init__.py` y `backend/app/main.py` con app FastAPI y `GET /health`.
- [x] Crear `backend/app/db.py` con `get_conn()` usando `sqlite3.Row` como row_factory.
- [x] Crear `backend/schema.sql` con tablas: `users`, `photos`, `cells`, `challenges`, `points_ledger`.
- [x] Crear `backend/app/config.py` con variables leídas de entorno (`DB_PATH`, `UPLOAD_DIR`, `CELL_SIZE_M`, etc.).
- [x] Crear `backend/requirements.txt` con: `fastapi`, `uvicorn[standard]`, `python-dotenv`, `pydantic`, `pillow`, `imagehash`.
- [x] Crear `backend/pyproject.toml` con configuración de `ruff` (target Python 3.11).
- [x] Crear `backend/tests/test_health.py` que llame a `GET /health` con `TestClient`.
- [x] Crear carpetas vacías con `.gitkeep`: `backend/prompts/`, `backend/eval/photos/`, `backend/uploads/`.

## Flutter

- [x] Inicializar proyecto Flutter en `app/` con `flutter create app --platforms web`.
- [x] Verificar que `flutter pub get` corre sin errores.
- [x] Añadir dependencias iniciales en `pubspec.yaml`: `http`, `flutter_map`, `latlong2`, `camera`, `geolocator`, `permission_handler`, `shared_preferences`, `cached_network_image`.

## Repo

- [x] Crear `.env.example` con todas las variables documentadas.
- [x] Crear `.gitignore` que excluya: `.env`, `backend/uploads/`, `backend/*.db`, `app/build/`, `__pycache__/`, `.dart_tool/`.
- [x] Crear `README.md` raíz con instrucciones de arranque (backend y Flutter).

## Verificación

- [x] `uvicorn app.main:app --reload` arranca y `GET /health` devuelve `{"status": "ok"}`.
- [x] `pytest` corre sin errores.
- [x] `ruff check .` sin errores.
- [x] `flutter pub get` sin errores.
