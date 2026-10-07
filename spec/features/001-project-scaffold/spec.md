# 001 · Project Scaffold

## Qué hace

Establece la estructura de carpetas, archivos base y herramientas de calidad del repositorio. No contiene lógica de negocio; su único propósito es que cualquier integrante (o agente) pueda clonar el repo y arrancar backend y frontend sin fricción.

## Por qué existe

Sin una base reproducible, cada feature siguiente añade deuda de configuración. Este scaffold define las convenciones una sola vez.

## Criterios de aceptación

- [x] `backend/` existe con `app/main.py`, `app/db.py`, `schema.sql` y `requirements.txt` funcionales.
- [x] `app/` existe como proyecto Flutter válido (`flutter pub get` sin errores).
- [x] `uvicorn app.main:app --reload` arranca y devuelve `{"status": "ok"}` en `GET /health`.
- [x] `pytest` corre sin errores (0 tests, 0 fallos).
- [x] `ruff check .` corre sin errores.
- [x] `.env.example` documenta todas las variables necesarias; `.env` y `uploads/` están en `.gitignore`.
- [x] `schema.sql` define las tablas `photos`, `cells`, `challenges`, `points_ledger` con las columnas del modelo de datos.
- [x] El README raíz explica cómo arrancar backend y app en desarrollo.
