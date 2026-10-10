# Plan — 008 · Scoring & Points Ledger

## Enfoque

Módulo `scoring.py` sin estado propio: todas las operaciones son inserciones en `points_ledger`. El total se calcula siempre con `SUM` sobre el ledger. Los valores de puntos viven en `config.py`.

## Decisiones técnicas

- **`points_ledger`:** `(id, user_id, reason, amount, ref_id, created_at)`. `reason` es un `Enum` de Python. `ref_id` apunta al `photo_id` o `challenge_id` relacionado (nullable).
- **`award_points`:** inserta con `INSERT OR IGNORE`; el índice único sobre `user_id` + `reason` + `COALESCE(ref_id, '')` evita duplicados también cuando la referencia es nula.
- **Racha:** se calcula al otorgar `photo_verified`, usando días UTC de ese ledger. Si las dos fechas más recientes son consecutivas, se otorga una sola fila `streak_day` para la fecha más reciente. Perder la racha no genera débitos.
- **`GET /ranking`:** agrega el ledger por usuario, ordena por total y desempata por `user_id`; devuelve los primeros 20 con racha actual. El `display_name` viene de la tabla `users` (añadida en 001).
- **Valores en `config.py`** (ajustables antes del hackathon):
  - `POINTS_PHOTO_VERIFIED = 10`
  - `POINTS_NEW_CELL = 20`
  - `POINTS_DAILY_CHALLENGE = 15`
  - `POINTS_WEEKLY_CHALLENGE = 50`
  - `POINTS_STREAK_DAY = 5`
