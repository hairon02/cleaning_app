# Tasks — 006 · Grid Cells & Fog of War

## Backend — módulo cells

- [x] Crear `backend/app/cells.py`.
- [x] Implementar `latlon_to_cell(lat, lon, size_m=None) -> str` con `math.floor` y `cell_deg` calculado de `CELL_SIZE_M`.
- [x] Implementar `cell_to_bounds(cell_id) -> tuple[float, float, float, float]` (lat_min, lon_min, lat_max, lon_max) para que el cliente genere polígonos.
- [x] Implementar `mark_cleared(user_id, cell_id, conn) -> bool` (`INSERT OR IGNORE`; devuelve `True` si insertó).
- [x] Implementar `get_cleared_cells(user_id, bbox, conn) -> list[str]` con `SELECT DISTINCT cell_id FROM cells WHERE user_id = ?` filtrado por bbox.
- [x] Añadir validación de bbox máximo (5 km × 5 km) en el endpoint; devolver 400 si se excede.

## Backend — endpoint `/map`

- [x] Crear `backend/app/routes/map.py` con `GET /map?user_id=X&bbox=...`.
- [x] Parsear y validar el bbox (4 floats separados por coma).
- [x] Devolver `{"cleared": ["cell_id_1", ...], "total_cleared": N}`.
- [x] Registrar la ruta en `main.py`.

## Integración con feature 003

- [x] Reemplazar el stub `mark_cleared(...)` en `upload.py` con la llamada real a `cells.mark_cleared`.
- [x] Si `mark_cleared` devuelve `True` (celda nueva), pasar el flag a `award_points` para sumar `POINTS_NEW_CELL`.

## Flutter

- [x] Mantener el mapa sin overlay de niebla ni cuadrícula; el descubrimiento por celda se usa solo en el backend.

## Tests

- [x] `test_cells.py`: mismo punto → mismo id, punto en frontera, `mark_cleared` idempotente, `get_cleared_cells` con bbox.

## Verificación

- [x] `GET /map` devuelve lista de ids después de subir una foto verificada.
- [x] Confirmar que el mapa no muestra niebla ni progreso de celdas.
