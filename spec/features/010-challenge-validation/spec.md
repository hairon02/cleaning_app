# 010 · Challenge Validation

## Qué hace

Al procesar una foto iniciada desde un reto, el backend comprueba si cumple el criterio visual del reto seleccionado y, si es así, suma los puntos correspondientes y marca el reto como completado para ese usuario.

## Por qué existe

Sin esta pieza, los retos son solo texto decorativo. La validación cierra el ciclo: salir → foto verificada → reto cumplido → puntos.

## Criterios de aceptación

- [x] Al completar el pipeline de la feature 003 con resultado `verified`, se evalúa el reto seleccionado por el usuario.
- [x] Al pulsar `Take Photo` en el detalle de un reto, la app conserva y envía su `challenge_id` junto con la foto.
- [x] El backend valida que el reto enviado exista, esté revisado, sea uno de los retos activos y no esté completado por ese usuario; solo entonces envía su criterio a Gemma.
- [x] Una foto sin `challenge_id` se verifica normalmente sin evaluar retos.
- [x] Un `challenge_id` inválido, inactivo o ya completado no otorga puntos ni permite evaluar otro reto automáticamente.
- [x] La evaluación extiende el prompt de verificación con `backend/prompts/challenge_check.txt` dentro de la misma llamada a Gemma.
- [x] El campo `visual_criterion` del reto es la condición de sí/no que se pasa al prompt.
- [x] Si Gemma confirma que la foto cumple el criterio, se inserta en `points_ledger` con `reason = daily_challenge` o `weekly_challenge`.
- [x] Un usuario no puede completar el mismo reto más de una vez (deduplicado por `user_id` + `challenge_id`).
- [x] La respuesta de `POST /upload` incluye `challenges_completed: list[str]` con los títulos de los retos cumplidos (vacío si ninguno).
- [x] Si el resultado de reto es inválido o no está disponible, se omite ese puntaje y se conserva la verificación principal de la foto.
- [x] Después de capturar, la app muestra una pantalla en inglés con progreso mientras el backend analiza la foto.
- [x] Si se verifica y completa el reto seleccionado, se muestra una animación de éxito y se vuelve automáticamente a Challenges.
- [x] Si la foto no completa el reto o falla la carga/verificación, se muestra un estado de error con una acción para volver a Camera y reintentar el mismo reto.
- [x] `test_challenge_validation.py` cubre: reto cumplido suma puntos, reto no repetible y resultados vacíos o no coincidentes.
