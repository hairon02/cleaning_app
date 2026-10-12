# Plan — 010 · Challenge Validation

## Enfoque

La selección de retos se ejecuta antes de verificar la foto para incluir sus criterios en la misma solicitud a Gemma que comprueba si la escena es exterior. Los resultados solo se puntúan después de que la foto queda `verified`.

## Decisiones técnicas

- **Prompt `challenge_check.txt`:** recibe los IDs, títulos y criterios visuales de los retos pendientes. Pide el campo adicional `challenge_results` en el JSON de verificación, con un resultado sí/no por ID. El reason no se muestra al usuario.
- **Deduplicado:** antes de llamar a Gemma, se comprueba `SELECT 1 FROM points_ledger WHERE user_id = ? AND reason = ? AND ref_id = ?`. Si ya existe, se salta la validación.
- **Orden de evaluación:** primero el reto diario, luego el semanal. Ambos se pueden cumplir con la misma foto.
- **Fallo aislado:** un campo de retos mal formado se descarta sin invalidar el JSON base de verificación. Una falla general de Gemma sigue el comportamiento existente (`pending_review`).
- **Integración:** `get_challenges_to_validate(...)` filtra los retos ya completados antes de llamar a Gemma; `validate_challenges(...)` otorga puntos después de actualizar celdas y puntos base y devuelve `list[str]` con los títulos cumplidos.

## Consideración de rendimiento

El criterio del reto se evalúa en la misma llamada de visión que la foto. Esto agrega texto al prompt, pero evita una segunda inferencia y su latencia adicional.
