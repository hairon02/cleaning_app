# 005 · Scoring & Points Ledger

## Qué hace

Define las reglas objetivas de puntos, las escribe en el ledger y expone el ranking. El total de puntos de cada usuario se obtiene sumando su ledger, nunca de un campo editable.

## Por qué existe

El ranking motiva la exploración continuada y hace la app competitiva para el hackathon. Las reglas deben ser simples, objetivas y resistentes a manipulación.

## Criterios de aceptación

- [ ] `backend/app/scoring.py` expone `award_points(user_id, reason, amount, ref_id)` que inserta una fila en `points_ledger`.
- [ ] Eventos que suman puntos (valores en `backend/app/config.py`, ajustables):
  - `photo_verified` — foto válida: **10 pts**.
  - `new_cell` — celda nunca visitada: **20 pts** adicionales.
  - `daily_challenge` — reto diario completado: **15 pts**.
  - `weekly_challenge` — reto semanal completado: **50 pts**.
  - `streak_day` — racha de días consecutivos: **5 pts/día** (desde el día 2).
- [ ] Perder una racha **nunca** resta puntos.
- [ ] `GET /ranking` devuelve los 20 primeros usuarios con `user_id`, `display_name`, `total_points`, `streak_days`. Sin mostrar ubicaciones.
- [ ] `GET /ranking/me?user_id=X` devuelve la posición y puntos del usuario autenticado.
- [ ] `test_scoring.py` cubre: foto verificada suma, celda nueva suma adicional, racha acumula, racha rota no resta.
