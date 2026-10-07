# Plan — 003 · Photo Upload & Verification Pipeline

## Enfoque

Un único endpoint `POST /upload` que orquesta pHash → Gemma → DB en secuencia. El pipeline no lanza excepciones hacia el cliente: cualquier fallo interno resulta en un status conocido.

## Decisiones técnicas

- **Endpoint:** `multipart/form-data` con `UploadFile` de FastAPI + campos Pydantic para lat, lon, taken_at.
- **Guardado de archivo:** `uuid4()` como nombre; estructura `uploads/{user_id}/{uuid}.jpg`. Se guarda antes de cualquier procesamiento para no perder la foto si falla algo después.
- **pHash:** `imagehash.phash(Image.open(path))` de `imagehash` + Pillow. Distancia ≤ 10 → `duplicate`. El umbral se guarda en `config.py`.
- **Llamada a Gemma:** solo si no es duplicado. Timeout de 60 s; si se agota o lanza `GemmaError`, status → `pending_review`.
- **Actualización de celdas:** si status es `verified`, se llama a `cells.mark_cleared(user_id, cell_id)` de la feature 004. En esta feature se deja como un stub (`pass`) que se completa en 004.
- **Respuesta:** `PhotoUploadResponse` Pydantic con `photo_id`, `status`, `description`, `tags`, `challenges_completed` (stub vacío hasta feature 007).
- **Logs:** se registra el hash de la foto y el status, pero nunca las coordenadas exactas.

## Flujo resumido

```
POST /upload
  → guardar archivo
  → calcular pHash
  → buscar duplicados (SELECT WHERE user_id AND phash_distance ≤ 10)
  → si duplicado: status=duplicate, return
  → verify_photo(path)
  → si GemmaError: status=pending_review, return
  → si not is_outdoor: status=rejected, return
  → status=verified
  → mark_cleared(user_id, cell_id)   ← stub en 003
  → award_points(...)                ← stub en 003
  → return PhotoUploadResponse
```
