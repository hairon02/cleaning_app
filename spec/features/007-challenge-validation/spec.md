# 007 · Challenge Validation

## Qué hace

Al procesar una foto verificada, el backend comprueba si cumple el criterio visual del reto activo (diario o semanal) y, si es así, suma los puntos correspondientes y marca el reto como completado para ese usuario.

## Por qué existe

Sin esta pieza, los retos son solo texto decorativo. La validación cierra el ciclo: salir → foto verificada → reto cumplido → puntos.

## Criterios de aceptación

- [ ] Al completar el pipeline de la feature 003 con resultado `verified`, se evalúa automáticamente si la foto cumple el reto diario y/o semanal activos.
- [ ] La evaluación usa `verify_photo` con un prompt específico al criterio del reto (en `backend/prompts/challenge_check.txt`), no con el prompt general de verificación.
- [ ] El campo `visual_criterion` del reto es la condición de sí/no que se pasa al prompt.
- [ ] Si Gemma confirma que la foto cumple el criterio, se inserta en `points_ledger` con `reason = daily_challenge` o `weekly_challenge`.
- [ ] Un usuario no puede completar el mismo reto más de una vez (deduplicado por `user_id` + `challenge_id`).
- [ ] La respuesta de `POST /upload` incluye `challenges_completed: list[str]` con los títulos de los retos cumplidos (vacío si ninguno).
- [ ] Si Gemma falla en la validación del reto, se omite la validación (no aborta el upload ni la verificación principal).
- [ ] `test_challenge_validation.py` cubre: reto cumplido suma puntos, reto no repetible, fallo de Gemma no bloquea.
