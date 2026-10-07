# Tasks — 003 · Photo Upload & Verification Pipeline

## Backend — módulo pHash

- [ ] Crear `backend/app/pipeline/phash.py` con `compute_phash(image_path: str) -> str`.
- [ ] Crear `find_duplicate(user_id, phash, conn) -> int | None` que busca foto previa con distancia ≤ `PHASH_THRESHOLD` (default 10).
- [ ] Test `test_phash.py`: misma foto → distancia 0, fotos distintas → distancia alta, umbral configurable.

## Backend — endpoint `/upload`

- [ ] Crear `backend/app/routes/upload.py` con `POST /upload` (multipart).
- [ ] Crear modelo Pydantic `PhotoUploadResponse` con `photo_id`, `status`, `description`, `tags`, `challenges_completed`.
- [ ] Validar `lat`, `lon` con Pydantic (float, rango válido) y `taken_at` como `datetime`.
- [ ] Guardar el archivo en `uploads/{user_id}/{uuid4()}.jpg` antes de cualquier procesamiento.
- [ ] Calcular pHash y buscar duplicados; si `status=duplicate`, insertar en DB y retornar.
- [ ] Llamar a `verify_photo`; capturar `GemmaError` → `status=pending_review`.
- [ ] Si `is_outdoor=False` → `status=rejected`.
- [ ] Si `status=verified`: llamar a `mark_cleared(user_id, cell_id)` (stub) y `award_points(...)` (stub).
- [ ] Insertar fila en `photos` con todos los campos.
- [ ] Registrar en el log el `photo_id` y `status` (nunca lat/lon exactos).
- [ ] Registrar la ruta en `main.py`: `app.include_router(upload_router, prefix="/api")`.

## Tests

- [ ] `test_upload.py`: foto exterior → `verified`, foto duplicada → `duplicate`, Gemma falla → `pending_review`.
- [ ] Test de foto rechazada (interior): mockear `verify_photo` con `is_outdoor=False` → `rejected`.
- [ ] Test de campos faltantes en el request → 422.

## Verificación

- [ ] `POST /upload` con una foto real devuelve `{"status": "verified", "description": "..."}`.
- [ ] Una segunda subida de la misma foto devuelve `{"status": "duplicate"}`.
- [ ] `pytest tests/test_upload.py` sin errores.
