# Plan — 001 · Project Scaffold

## Enfoque

Crear la estructura mínima que permita arrancar backend y frontend sin configuración manual, con convenciones de calidad aplicadas desde el primer commit.

## Decisiones técnicas

- **SQLite con SQL explícito:** `schema.sql` define todas las tablas; `db.py` expone `get_conn()` con `row_factory = sqlite3.Row`. Sin ORM para mantener visibilidad total de las queries.
- **FastAPI + `lifespan`:** la conexión a la DB se abre en el lifespan de la app (no por petición).
- **`python-dotenv`:** carga `.env` automáticamente. `.env.example` documenta cada variable.
- **`ruff` como linter:** configurado en `pyproject.toml`. Sin formatter por ahora (el equipo decide).
- **Flutter Web:** se inicializa con `flutter create app --platforms web`. El build se servirá desde FastAPI en la feature 012; por ahora solo se verifica que `flutter pub get` funciona.

## Estructura de carpetas resultante

```
Clearing/
├── backend/
│   ├── app/
│   │   ├── main.py          # FastAPI + health endpoint
│   │   └── db.py            # get_conn()
│   ├── prompts/             # vacío, preparado para 002
│   ├── eval/                # vacío, preparado para 002
│   ├── uploads/             # .gitignore
│   ├── tests/
│   │   └── test_health.py
│   ├── schema.sql
│   ├── requirements.txt
│   └── pyproject.toml       # ruff config
├── app/                     # proyecto Flutter
├── spec/                    # SDD (ya existe)
├── .env.example
├── .gitignore
└── README.md
```

## Variables de entorno (`.env.example`)

```
DB_PATH=backend/clearing.db
UPLOAD_DIR=backend/uploads
CELL_SIZE_M=200
GEMMA_MODEL=gemma3n:e4b          # tag exacto de Ollama (por confirmar)
GEMMA_BACKEND=ollama              # ollama | transformers
GEMMA_MAX_RETRIES=2
```
