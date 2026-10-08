# Tasks — 002 · Gemma Integration

## Verificación previa (confirmar antes de implementar)

- [x] Confirmar si `ollama pull gemma3:4b` (o `e2b`) acepta imágenes en la versión instalada de Ollama.
- [x] Si Ollama no soporta visión con Gemma 3n → cambiar `GEMMA_BACKEND=transformers` y verificar que el modelo carga en VRAM.
- [x] Anotar el tag exacto del modelo (e.g., `gemma3:4b`) en `.env.example`.

## Módulo `verify.py`

- [x] Crear `backend/app/pipeline/__init__.py` y `backend/app/pipeline/verify.py`.
- [x] Definir `GemmaResult(BaseModel)` con campos: `is_outdoor`, `description`, `tags`, `time_of_day`, `weather`.
- [x] Definir `GemmaError(Exception)`.
- [x] Implementar `_call_ollama(image_path, prompt)` usando `ollama` Python client o `httpx` a `localhost:11434`.
- [x] Implementar `_call_transformers(image_path, prompt)` como alternativa.
- [x] Implementar `verify_photo(image_path: str) -> GemmaResult` con lógica de reintento.
- [x] Cargar el modelo una sola vez al importar el módulo (no por petición).

## Prompts

- [x] Crear `backend/prompts/verify.txt` con el system prompt que pide JSON estricto.
- [x] Testear el prompt con 3–5 fotos manualmente antes de correr la evaluación completa.
- [x] Iterar el prompt si Gemma añade texto fuera del JSON ("Claro, aquí va...").

## Set de evaluación

- [x] Reunir 20–30 fotos en `backend/eval/photos/` categorizadas: exterior natural, interior, captura de pantalla, foto de una pantalla.
- [x] Crear `backend/eval/labels.json` con el resultado esperado por foto (`is_outdoor: true/false`).
- [x] Crear `backend/eval/run.py` que itera las fotos, llama a `verify_photo` y calcula precisión/recall.
- [x] Correr `python -m eval.run` y documentar el resultado en `backend/eval/results.md`.

## Tests

- [x] Crear `backend/tests/test_verify.py` con una foto fixture (exterior) y verificar que `GemmaResult` es válido.
- [x] Test de reintento: mockear Gemma para que falle la primera vez y tenga éxito en la segunda.
- [x] Test de fallo total: mockear Gemma para que siempre falle y verificar que se lanza `GemmaError`.

## Verificación

- [x] Acierto ≥ 80 % sobre el set de evaluación (o documentar por qué no se llega y cómo se mejora).
- [x] `pytest tests/test_verify.py` sin errores.

