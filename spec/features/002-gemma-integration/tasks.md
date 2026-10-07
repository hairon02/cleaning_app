# Tasks — 002 · Gemma Integration

## Verificación previa (confirmar antes de implementar)

- [ ] Confirmar si `ollama pull gemma3n:e4b` (o `e2b`) acepta imágenes en la versión instalada de Ollama.
- [ ] Si Ollama no soporta visión con Gemma 3n → cambiar `GEMMA_BACKEND=transformers` y verificar que el modelo carga en VRAM.
- [ ] Anotar el tag exacto del modelo (e.g., `gemma3n:e4b`) en `.env.example`.

## Módulo `verify.py`

- [ ] Crear `backend/app/pipeline/__init__.py` y `backend/app/pipeline/verify.py`.
- [ ] Definir `GemmaResult(BaseModel)` con campos: `is_outdoor`, `description`, `tags`, `time_of_day`, `weather`.
- [ ] Definir `GemmaError(Exception)`.
- [ ] Implementar `_call_ollama(image_path, prompt)` usando `ollama` Python client o `httpx` a `localhost:11434`.
- [ ] Implementar `_call_transformers(image_path, prompt)` como alternativa.
- [ ] Implementar `verify_photo(image_path: str) -> GemmaResult` con lógica de reintento.
- [ ] Cargar el modelo una sola vez al importar el módulo (no por petición).

## Prompts

- [ ] Crear `backend/prompts/verify.txt` con el system prompt que pide JSON estricto.
- [ ] Testear el prompt con 3–5 fotos manualmente antes de correr la evaluación completa.
- [ ] Iterar el prompt si Gemma añade texto fuera del JSON ("Claro, aquí va...").

## Set de evaluación

- [ ] Reunir 20–30 fotos en `backend/eval/photos/` categorizadas: exterior natural, interior, captura de pantalla, foto de una pantalla.
- [ ] Crear `backend/eval/labels.json` con el resultado esperado por foto (`is_outdoor: true/false`).
- [ ] Crear `backend/eval/run.py` que itera las fotos, llama a `verify_photo` y calcula precisión/recall.
- [ ] Correr `python -m eval.run` y documentar el resultado en `backend/eval/results.md`.

## Tests

- [ ] Crear `backend/tests/test_verify.py` con una foto fixture (exterior) y verificar que `GemmaResult` es válido.
- [ ] Test de reintento: mockear Gemma para que falle la primera vez y tenga éxito en la segunda.
- [ ] Test de fallo total: mockear Gemma para que siempre falle y verificar que se lanza `GemmaError`.

## Verificación

- [ ] Acierto ≥ 80 % sobre el set de evaluación (o documentar por qué no se llega y cómo se mejora).
- [ ] `pytest tests/test_verify.py` sin errores.
