# Tasks — 007 · Challenge Validation

## Backend — prompts

- [ ] Crear `backend/prompts/challenge_check.txt` con el prompt que recibe `{visual_criterion}` y pide `{"meets_criterion": bool, "reason": str}`.
- [ ] Testear el prompt manualmente con 3–5 fotos y 2–3 criterios distintos antes de integrar.

## Backend — módulo de validación

- [ ] Crear `backend/app/pipeline/challenge_validator.py`.
- [ ] Implementar `validate_challenge(image_path, challenge, user_id, conn) -> bool` que llama a Gemma con el prompt específico y deduplicado.
- [ ] Implementar `validate_challenges(user_id, photo_id, image_path, conn) -> list[str]` que itera (diario, semanal) y devuelve títulos de los completados.
- [ ] Capturar excepciones de Gemma silenciosamente (log + return `[]`).

## Integración con feature 003

- [ ] Llamar a `validate_challenges(...)` en `upload.py` justo después de actualizar celdas y puntos base.
- [ ] Pasar los resultados a `award_points` para cada reto completado.
- [ ] Incluir `challenges_completed` en `PhotoUploadResponse` (ya estaba como stub).

## Tests

- [ ] `test_challenge_validation.py`: reto cumplido → puntos sumados + título en respuesta.
- [ ] Test de no repetición: subir la misma foto dos veces → el reto no se puntúa dos veces.
- [ ] Test de fallo de Gemma en validación: mockear `GemmaError` → upload sigue devolviendo `verified`, `challenges_completed=[]`.

## Verificación

- [ ] Subir una foto que cumpla el criterio del reto diario activo → `challenges_completed` contiene el título del reto.
- [ ] `pytest tests/test_challenge_validation.py` sin errores.
