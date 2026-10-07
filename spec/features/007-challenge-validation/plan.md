# Plan — 007 · Challenge Validation

## Enfoque

Hook que se engancha al final del pipeline de upload (feature 003), después de que la foto es `verified`. Llama a Gemma con un prompt específico del reto en lugar del prompt general.

## Decisiones técnicas

- **Prompt `challenge_check.txt`:** recibe `{visual_criterion}` como variable. Pide a Gemma que responda `{"meets_criterion": true/false, "reason": "..."}`. El reason se guarda para depuración pero no se muestra al usuario.
- **Deduplicado:** antes de llamar a Gemma, se comprueba `SELECT 1 FROM points_ledger WHERE user_id = ? AND reason = ? AND ref_id = ?`. Si ya existe, se salta la validación.
- **Orden de evaluación:** primero el reto diario, luego el semanal. Ambos se pueden cumplir con la misma foto.
- **Fallo silencioso:** si `GemmaError` o timeout, se loguea y se continúa. El upload ya devolvió `verified`; el reto queda pendiente.
- **Integración:** `validate_challenges(user_id, photo_id, gemma_result)` se llama desde `routes/upload.py` justo después de actualizar las celdas y los puntos base. Devuelve `list[str]` con los títulos de los retos cumplidos.

## Consideración de rendimiento

Validar el reto implica una segunda llamada a Gemma (con imagen). En hardware con GTX 1650 Ti esto puede añadir 5–15 s. Si el tiempo de respuesta es inaceptable, se puede hacer la validación del reto en background (tarea async) y notificar al cliente por polling o websocket. Para el MVP se acepta la latencia extra.
