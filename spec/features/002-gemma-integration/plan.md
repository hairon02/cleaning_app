# Plan — 002 · Gemma Integration

## Enfoque

Encapsular toda la interacción con Gemma en un módulo único (`verify.py`) con interfaz tipada. El backend de inferencia (Ollama vs. `transformers`) se elige en tiempo de arranque vía variable de entorno para no duplicar lógica.

## Decisiones técnicas

- **Abstracción del backend:** `verify.py` llama a `_call_ollama(...)` o `_call_transformers(...)` según `GEMMA_BACKEND`. El modelo se carga una sola vez al importar el módulo.
- **Prompt versionado:** `backend/prompts/verify.txt` contiene el system prompt con marcador `{image_b64}`. Se lee en tiempo de arranque, no en cada petición.
- **Esquema JSON de salida:** se valida con `pydantic.BaseModel` (`GemmaResult`). Si el JSON de Gemma falla la validación, se reintenta hasta `GEMMA_MAX_RETRIES` veces con el mensaje de error incluido en el prompt.
- **Evaluación desacoplada:** `eval/run.py` no importa `main.py`; llama directamente a `verify_photo`. Las fotos del set de evaluación están en `eval/photos/` (fuera de git salvo unos pocos fixtures de test).
- **GPU único:** con Ollama, el modelo queda cargado en VRAM entre llamadas. Con `transformers`, se usa `device="cuda"` si disponible.

## Prompt base (`verify.txt`)

El prompt pedirá a Gemma que responda **solo** en JSON con las claves `is_outdoor`, `description`, `tags`, `time_of_day`, `weather`. Se testeará que frases como "Claro, aquí va..." no aparezcan en la salida.

## Riesgos

- Gemma 3n puede no aceptar imágenes en Ollama en la versión instalada → plan B: `transformers` con `AutoModelForVision2Seq`.
- VRAM insuficiente con E4B → bajar a E2B.
- Acierto < 80 % → iterar el prompt; documentar los casos fallidos para el post.
