# Tasks — 010 · Challenge Validation

## Backend — prompts

- [x] Crear `backend/prompts/challenge_check.txt` con el fragmento de prompt que recibe criterios e incluye resultados sí/no en la respuesta de verificación.
- [ ] Confirmar manualmente la respuesta de Gemma con 3–5 fotos; la ejecución local intentada agotó el timeout de Ollama.

## Backend — módulo de validación

- [x] Crear `backend/app/pipeline/challenge_validator.py`.
- [x] Implementar selección de retos pendientes, deduplicada por usuario y reto, y pasar sus criterios a la llamada de verificación existente.
- [x] Implementar `validate_challenges(user_id, challenges, results, conn) -> list[str]` para puntuar resultados diarios/semanales una sola vez.
- [x] Aislar resultados de reto inválidos para que no descarten la verificación principal de la foto.

## Integración con feature 003

- [x] Llamar a `validate_challenges(...)` en `upload.py` justo después de actualizar celdas y puntos base.
- [x] Pasar los resultados a `award_points` para cada reto completado.
- [x] Incluir `challenges_completed` en `PhotoUploadResponse` (ya estaba como stub).

## Tests

- [x] `test_challenge_validation.py`: retos cumplidos → puntos diarios/semanales sumados, deduplicación e IDs no esperados ignorados.
- [x] Test de no repetición: los puntos del mismo reto se otorgan solo una vez.
- [x] Test de resultado inválido/vacío de reto: conserva la verificación de la foto y no suma puntos de reto.

## Verificación

- [x] Subir una foto verificada que cumpla el criterio diario → `challenges_completed` contiene el título y el ledger suma los puntos.
- [x] `pytest tests/test_challenge_validation.py` sin errores.
