# Tasks — 009 · Challenge Bank & Daily/Weekly Selection

## Preparación offline (antes del hackathon)

- [x] Crear `backend/prompts/challenge_gen.txt` con el prompt de generación (con ejemplos buenos y malos).
- [x] Crear `backend/app/challenge_filter.py` con la lista de palabras clave prohibidas y la función `is_safe(challenge) -> bool`.
- [x] Crear `backend/scripts/gen_challenges.py` que llama a Gemma por lotes, valida JSON, aplica el filtro e inserta sin duplicar títulos.
- [x] Correr `gen_challenges.py` y generar al menos 14 retos diarios y 4 semanales; todos quedaron revisados antes de publicarse.
- [x] Revisar manualmente los retos en la DB y marcar `reviewed = 1` en los 18 retos seguros y visualmente verificables.

## Backend — módulo challenges

- [x] Crear `backend/app/challenges.py`.
- [x] Implementar `get_active_challenges(conn) -> tuple[Challenge | None, Challenge | None]` con selección determinista por fecha.
- [x] Definir `Challenge(BaseModel)` con `id`, `title`, `description`, `visual_criterion`, `period`, `difficulty`, `points`.
- [x] Confirmar que el campo `points` existente en `schema.sql` se llena con los valores configurados por período.

## Backend — endpoint `/challenges`

- [x] Crear `backend/app/routes/challenges.py` con `GET /challenges?user_id=X`.
- [x] Añadir campo `completed_by_user: bool` a la respuesta (la consulta del ledger queda lista para feature 010).
- [x] Devolver 503 si no hay retos reviewed de algún tipo.
- [x] Registrar la ruta en `main.py`.

## Tests

- [x] `test_challenges.py`: selección determinista (misma fecha → mismo id), solo reviewed son elegidos, 503 si no hay reviewed; filtro de seguridad e inserción idempotente.

## Verificación

- [x] `GET /challenges` devuelve un reto diario y uno semanal.
- [x] `pytest tests/test_challenges.py` sin errores.
