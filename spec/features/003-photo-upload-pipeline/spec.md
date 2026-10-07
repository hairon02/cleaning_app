# 003 · Photo Upload & Verification Pipeline

## Qué hace

Endpoint `POST /upload` que recibe una foto desde la app, registra GPS y hora, calcula el hash perceptual, detecta duplicados y llama a Gemma para verificar. Guarda la foto en `photos` con el estado resultante.

## Por qué existe

Es el núcleo de toda la mecánica del juego: sin este pipeline no hay fotos verificadas, no hay celdas despejadas y no hay puntos.

## Criterios de aceptación

- [ ] `POST /upload` acepta `multipart/form-data` con campos: `file` (imagen), `lat` (float), `lon` (float), `taken_at` (ISO 8601).
- [ ] El backend guarda la imagen en `backend/uploads/{user_id}/{uuid}.jpg` (fuera de git).
- [ ] El pHash se calcula con `imagehash` + Pillow y se guarda en `photos.phash`.
- [ ] Si el pHash está a distancia ≤ 10 de una foto previa del mismo usuario, la foto queda en estado `duplicate` y la respuesta lo indica.
- [ ] Si pasa la detección de duplicados, se llama a `verify_photo` de la feature 002.
- [ ] La respuesta incluye: `photo_id`, `status`, `description` (si verified), `tags` (si verified).
- [ ] El endpoint nunca devuelve 500 por fallo de Gemma: en ese caso el status es `pending_review`.
- [ ] `test_upload.py` cubre: foto válida → verified, foto duplicada → duplicate, Gemma falla → pending_review, foto de pantalla → rejected.
- [ ] Las coordenadas exactas **no** se registran en logs.
