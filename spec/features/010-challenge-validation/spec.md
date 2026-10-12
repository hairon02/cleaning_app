# 010 · Challenge Validation

## Qué hace

Al procesar una foto verificada, el backend comprueba si cumple el criterio visual del reto activo (diario o semanal) y, si es así, suma los puntos correspondientes y marca el reto como completado para ese usuario.

## Por qué existe

Sin esta pieza, los retos son solo texto decorativo. La validación cierra el ciclo: salir → foto verificada → reto cumplido → puntos.

## Criterios de aceptación

- [x] Al completar el pipeline de la feature 003 con resultado `verified`, se evalúa automáticamente si la foto cumple el reto diario y/o semanal activos.
- [x] La evaluación extiende el prompt de verificación con `backend/prompts/challenge_check.txt` dentro de la misma llamada a Gemma.
- [x] El campo `visual_criterion` del reto es la condición de sí/no que se pasa al prompt.
- [x] Si Gemma confirma que la foto cumple el criterio, se inserta en `points_ledger` con `reason = daily_challenge` o `weekly_challenge`.
- [x] Un usuario no puede completar el mismo reto más de una vez (deduplicado por `user_id` + `challenge_id`).
- [x] La respuesta de `POST /upload` incluye `challenges_completed: list[str]` con los títulos de los retos cumplidos (vacío si ninguno).
- [x] Si el resultado de reto es inválido o no está disponible, se omite ese puntaje y se conserva la verificación principal de la foto.
- [x] `test_challenge_validation.py` cubre: reto cumplido suma puntos, reto no repetible y resultados vacíos o no coincidentes.
