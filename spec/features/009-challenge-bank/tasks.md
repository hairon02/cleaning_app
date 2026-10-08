# Tasks — 009 · Challenge Bank & Daily/Weekly Selection

## Preparación offline (antes del hackathon)

- [ ] Crear `backend/prompts/challenge_gen.txt` con el prompt de generación (con ejemplos buenos y malos).
- [ ] Crear `backend/app/challenge_filter.py` con la lista de palabras clave prohibidas y la función `is_safe(challenge) -> bool`.
- [ ] Crear `backend/scripts/gen_challenges.py` que llama a Gemma en lote, valida JSON, aplica el filtro y hace `INSERT OR IGNORE` en `challenges`.
- [ ] Correr `gen_challenges.py` y generar al menos 14 retos diarios y 4 semanales reviewed.
- [ ] Revisar manualmente los retos en la DB (`sqlite3 clearing.db "SELECT * FROM challenges"`) y marcar `reviewed = 1` en los aprobados.

## Backend — módulo challenges

- [ ] Crear `backend/app/challenges.py`.
- [ ] Implementar `get_active_challenges(conn) -> tuple[Challenge | None, Challenge | None]` con selección determinista por fecha.
- [ ] Definir `Challenge(BaseModel)` con `id`, `title`, `description`, `visual_criterion`, `period`, `difficulty`, `points`.
- [ ] Añadir campo `points` a la tabla `challenges` en `schema.sql` (daily → `POINTS_DAILY_CHALLENGE`, weekly → `POINTS_WEEKLY_CHALLENGE`).

## Backend — endpoint `/challenges`

- [ ] Crear `backend/app/routes/challenges.py` con `GET /challenges?user_id=X`.
- [ ] Añadir campo `completed_by_user: bool` a la respuesta (preparado para feature 007).
- [ ] Devolver 503 si no hay retos reviewed de algún tipo.
- [ ] Registrar la ruta en `main.py`.

## Tests

- [ ] `test_challenges.py`: selección determinista (misma fecha → mismo id), solo reviewed son elegidos, 503 si no hay reviewed.

## Verificación

- [ ] `GET /challenges` devuelve un reto diario y uno semanal.
- [ ] `pytest tests/test_challenges.py` sin errores.
