# Tasks — 006 · Grid Cells & Fog of War

## Backend — módulo cells

- [ ] Crear `backend/app/cells.py`.
- [ ] Implementar `latlon_to_cell(lat, lon, size_m=None) -> str` con `math.floor` y `cell_deg` calculado de `CELL_SIZE_M`.
- [ ] Implementar `cell_to_bounds(cell_id) -> tuple[float, float, float, float]` (lat_min, lon_min, lat_max, lon_max) para que el cliente genere polígonos.
- [ ] Implementar `mark_cleared(user_id, cell_id, conn) -> bool` (`INSERT OR IGNORE`; devuelve `True` si insertó).
- [ ] Implementar `get_cleared_cells(user_id, bbox, conn) -> list[str]` con `SELECT DISTINCT cell_id FROM cells WHERE user_id = ?` filtrado por bbox.
- [ ] Añadir validación de bbox máximo (5 km × 5 km) en el endpoint; devolver 400 si se excede.

## Backend — endpoint `/map`

- [ ] Crear `backend/app/routes/map.py` con `GET /map?user_id=X&bbox=...`.
- [ ] Parsear y validar el bbox (4 floats separados por coma).
- [ ] Devolver `{"cleared": ["cell_id_1", ...], "total_cleared": N}`.
- [ ] Registrar la ruta en `main.py`.

## Integración con feature 003

- [ ] Reemplazar el stub `mark_cleared(...)` en `upload.py` con la llamada real a `cells.mark_cleared`.
- [ ] Si `mark_cleared` devuelve `True` (celda nueva), pasar el flag a `award_points` para sumar `POINTS_NEW_CELL`.

## Flutter — pantalla del mapa (base)

- [ ] Crear `lib/screens/map_screen.dart` con `FlutterMap` + `TileLayer` de OSM.
- [ ] Implementar `cell_id → LatLngBounds` en Dart en `lib/utils/cells.dart` (misma lógica que el backend).
- [ ] Llamar a `GET /map?bbox=...` al entrar en la pantalla y al cambiar el viewport (debounce 500 ms).
- [ ] Pintar `PolygonLayer` con las celdas no despejadas (gris, 70 % opacidad).
- [ ] Mostrar contador de celdas en la esquina superior derecha.

## Tests

- [ ] `test_cells.py`: mismo punto → mismo id, punto en frontera, `mark_cleared` idempotente, `get_cleared_cells` con bbox.

## Verificación

- [ ] `GET /map` devuelve lista de ids después de subir una foto verificada.
- [ ] En la app Flutter, la celda de la foto se muestra despejada en el mapa.
- [ ] Usar ui-ux-pro-max antes de implementar la UI del mapa/niebla.
- [ ] Usar Impeccable después de implementar para auditar y pulir la UI.
- [ ] Registrar y resolver los hallazgos de ambas skills.
