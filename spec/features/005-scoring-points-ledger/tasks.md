# Tasks — 005 · Scoring & Points Ledger

## Backend — módulo scoring

- [ ] Crear `backend/app/scoring.py`.
- [ ] Definir `PointReason` como `StrEnum` con valores: `photo_verified`, `new_cell`, `daily_challenge`, `weekly_challenge`, `streak_day`.
- [ ] Implementar `award_points(user_id, reason, amount, ref_id, conn)` con deduplicado (`INSERT OR IGNORE` con constraint UNIQUE en `user_id + reason + ref_id`).
- [ ] Implementar `_check_and_award_streak(user_id, conn)` que calcula la racha y llama a `award_points` si corresponde.
- [ ] Implementar `get_user_total(user_id, conn) -> int` con `SUM` sobre el ledger.
- [ ] Implementar `get_streak_days(user_id, conn) -> int`.

## Backend — endpoint `/ranking`

- [ ] Crear `backend/app/routes/ranking.py` con `GET /ranking` (top 20).
- [ ] Crear `GET /ranking/me?user_id=X` que devuelve posición y total del usuario.
- [ ] Añadir tabla `users (id, display_name, created_at)` al schema si no está ya.
- [ ] Registrar las rutas en `main.py`.

## Integración con feature 003

- [ ] Reemplazar el stub `award_points(...)` en `upload.py` con llamadas reales:
  - Siempre: `award_points(user_id, photo_verified, POINTS_PHOTO_VERIFIED, photo_id)`.
  - Si celda nueva: `award_points(user_id, new_cell, POINTS_NEW_CELL, cell_id)`.
  - Llamar a `_check_and_award_streak(user_id)`.

## Tests

- [ ] `test_scoring.py`: foto verificada suma puntos, celda nueva suma adicional, doble award no duplica, racha de 2 días suma streak, racha rota no resta.

## Flutter — sección de ranking

- [ ] Añadir llamada a `GET /ranking` en la pantalla de ranking (feature 011 la integrará).

## Verificación

- [ ] `GET /ranking` devuelve usuarios ordenados por puntos tras subir fotos verificadas.
- [ ] `pytest tests/test_scoring.py` sin errores.
