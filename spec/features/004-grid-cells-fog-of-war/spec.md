# 004 · Grid Cells & Fog of War

## Qué hace

Convierte coordenadas GPS en un id de celda de cuadrícula, registra qué celdas están despejadas para cada usuario y expone el estado del mapa. La app Flutter pinta un overlay de niebla sobre las celdas no visitadas.

## Por qué existe

El mapa con niebla es la recompensa visible de salir: ver cómo se aclara el mapa motiva a explorar nuevas zonas. Sin este sistema no hay progresión espacial.

## Criterios de aceptación

- [ ] `backend/app/cells.py` expone `latlon_to_cell(lat, lon, size_m=200) -> str` que devuelve un id de celda reproducible (mismo punto → mismo id).
- [ ] El tamaño de celda por defecto es 200 m (ajustable via variable de entorno `CELL_SIZE_M`).
- [ ] `GET /map?user_id=X&bbox=lat_min,lon_min,lat_max,lon_max` devuelve lista de celdas despejadas dentro del bbox.
- [ ] Una celda se considera despejada si el usuario tiene al menos una foto con `status = verified` cuyo `cell_id` coincide.
- [ ] La tabla `cells` se actualiza automáticamente cuando una foto pasa a `verified` en el pipeline (feature 003).
- [ ] En Flutter, `flutter_map` muestra un `PolygonLayer` semitransparente (gris, 70 % opacidad) sobre todas las celdas no despejadas del bbox visible.
- [ ] `test_cells.py` verifica: mismo punto → mismo id, punto en frontera → id correcto, celda nueva se añade al despejar.
