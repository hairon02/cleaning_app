# Plan — 010 · Challenge Validation

## Enfoque

La app conserva el reto seleccionado al navegar del detalle a la cámara y envía su ID junto con la foto. El backend vuelve a consultar ese ID en los retos revisados activos para evitar confiar en criterios enviados por el cliente. Solo el reto solicitado se incluye en la misma llamada a Gemma que comprueba si la escena es exterior. Los resultados solo se puntúan después de que la foto queda `verified`.

## Decisiones técnicas

- **Prompt `challenge_check.txt`:** recibe únicamente el reto activo y pendiente solicitado por el cliente: ID, título y criterio visual. Pide el campo adicional `challenge_results` en el JSON de verificación, con un resultado sí/no por ID. El reason no se muestra al usuario.
- **Deduplicado:** antes de llamar a Gemma, se comprueba `SELECT 1 FROM points_ledger WHERE user_id = ? AND reason = ? AND ref_id = ?`. Si ya existe, se salta la validación.
- **Validación del ID:** el servidor confirma que el reto solicitado coincide con el reto diario o semanal seleccionado por el banco para la fecha actual y que el usuario no lo completó antes.
- **Fallo aislado:** un campo de retos mal formado se descarta sin invalidar el JSON base de verificación. Una falla general de Gemma sigue el comportamiento existente (`pending_review`).
- **Integración:** `get_challenge_to_validate(...)` valida un único ID antes de llamar a Gemma; `validate_challenges(...)` otorga puntos después de actualizar celdas y puntos base y devuelve `list[str]` con los títulos cumplidos.
- **Flujo de interfaz:** después de capturar, la cámara muestra un estado de análisis mientras espera la respuesta de `/upload`. Solo una respuesta verificada que incluya el reto seleccionado muestra éxito; errores y fotos que no cumplen permiten volver a capturar con el mismo reto.

## Consideración de rendimiento

El criterio del reto se evalúa en la misma llamada de visión que la foto. Esto agrega texto al prompt, pero evita una segunda inferencia y su latencia adicional.
