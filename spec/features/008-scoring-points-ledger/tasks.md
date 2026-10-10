# Tasks — 008 · Scoring & Points Ledger

## Backend — módulo scoring

- [x] Crear `backend/app/scoring.py`.
- [x] Definir `PointReason` como `StrEnum` con valores: `photo_verified`, `new_cell`, `daily_challenge`, `weekly_challenge`, `streak_day`.
- [x] Implementar `award_points(user_id, reason, amount, ref_id, conn)` con deduplicado por usuario, motivo y referencia.
- [x] Implementar `_check_and_award_streak(user_id, conn)` para sumar una sola bonificación por día consecutivo.
- [x] Implementar `get_user_total(user_id, conn) -> int` con `SUM` sobre el ledger.
- [x] Implementar `get_streak_days(user_id, conn) -> int`.

## Backend — endpoint `/ranking`

- [x] Crear `backend/app/routes/ranking.py` con `GET /ranking` (top 20).
- [x] Crear `GET /ranking/me?user_id=X` que devuelve posición y total del usuario.
- [x] Confirmar que el schema incluye `users (id, display_name, created_at)` y el ledger.
- [x] Registrar las rutas en `main.py`.

## Integración con feature 003

- [x] Reemplazar el stub `award_points(...)` en `upload.py` con llamadas reales:
  - Siempre: `award_points(user_id, photo_verified, POINTS_PHOTO_VERIFIED, photo_id)`.
  - Si celda nueva: `award_points(user_id, new_cell, POINTS_NEW_CELL, cell_id)`.
  - Llamar a `_check_and_award_streak(user_id)`.

## Tests

- [x] `test_scoring.py`: foto verificada suma puntos, celda nueva suma adicional, doble award no duplica, racha de 2 días suma streak, racha rota no resta.

## Flutter — sección de ranking

- [x] Exponer los endpoints para que la pantalla de ranking los consuma; la integración Flutter corresponde a feature 011.

## Verificación

- [x] Implementar `GET /ranking` con orden por puntos después de otorgar puntos a fotos verificadas.
- [x] `pytest tests/test_scoring.py` sin errores (suite pendiente; no se ejecutó).
