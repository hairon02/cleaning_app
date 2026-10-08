# Plan — 008 · Scoring & Points Ledger

## Enfoque

Módulo `scoring.py` sin estado propio: todas las operaciones son inserciones en `points_ledger`. El total se calcula siempre con `SUM` sobre el ledger. Los valores de puntos viven en `config.py`.

## Decisiones técnicas

- **`points_ledger`:** `(id, user_id, reason, amount, ref_id, created_at)`. `reason` es un `Enum` de Python. `ref_id` apunta al `photo_id` o `challenge_id` relacionado (nullable).
- **`award_points`:** `INSERT INTO points_ledger (user_id, reason, amount, ref_id, created_at) VALUES (...)`. Idempotente: antes de insertar comprueba que no existe ya una fila con el mismo `user_id` + `reason` + `ref_id` (evita doble contabilidad si el pipeline se llama dos veces).
- **Racha:** se calcula al hacer `award_points` de `photo_verified`. Se hace `SELECT DISTINCT date(created_at) FROM points_ledger WHERE user_id = ? ORDER BY 1 DESC LIMIT 2` para ver si ayer hubo actividad. Si la racha es ≥ 2 días, se añade otra fila `streak_day`.
- **`GET /ranking`:** `SELECT user_id, SUM(amount) AS total FROM points_ledger GROUP BY user_id ORDER BY total DESC LIMIT 20`. El `display_name` viene de la tabla `users` (añadida en 001).
- **Valores en `config.py`** (ajustables antes del hackathon):
  - `POINTS_PHOTO_VERIFIED = 10`
  - `POINTS_NEW_CELL = 20`
  - `POINTS_DAILY_CHALLENGE = 15`
  - `POINTS_WEEKLY_CHALLENGE = 50`
  - `POINTS_STREAK_DAY = 5`
