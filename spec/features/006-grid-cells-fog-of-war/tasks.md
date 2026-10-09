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

## Flutter — pantalla del mapa (base)

- [x] Crear `lib/screens/map_screen.dart` con `FlutterMap` + `TileLayer` de OSM.
- [x] Implementar `cell_id → LatLngBounds` en Dart en `lib/utils/cells.dart` (misma lógica que el backend).
- [x] Llamar a `GET /map?bbox=...` al entrar en la pantalla y al cambiar el viewport (debounce 500 ms).
- [x] Pintar `PolygonLayer` con las celdas no despejadas (gris, 70 % opacidad).
- [x] Mostrar contador de celdas en la esquina superior derecha.

## Tests

- [x] `test_cells.py`: mismo punto → mismo id, punto en frontera, `mark_cleared` idempotente, `get_cleared_cells` con bbox.

## Verificación

- [x] `GET /map` devuelve lista de ids después de subir una foto verificada.
- [ ] En la app Flutter, la celda de la foto se muestra despejada en el mapa.
- [x] Usar ui-ux-pro-max antes de implementar la UI del mapa/niebla.
- [x] Usar Impeccable después de implementar para auditar y pulir la UI.
- [x] Registrar y resolver los hallazgos de ambas skills.
