# 006 · Grid Cells & Fog of War

## Qué hace

Convierte las coordenadas GPS de una foto verificada en una celda y registra si ese usuario ya había tomado una foto en esa zona. Esta comprobación backend permite dar puntos por primera visita. La app no dibuja niebla ni cuadrícula.

## Por qué existe

La celda permite comprobar de forma objetiva que una foto verificada corresponde a una zona nueva para el usuario. La cuadrícula es interna al backend; el mapa sigue mostrando únicamente el mapa base y los pines de fotos.

## Criterios de aceptación

- [x] `backend/app/cells.py` expone `latlon_to_cell(lat, lon, size_m=200) -> str` que devuelve un id de celda reproducible (mismo punto → mismo id).
- [x] El tamaño de celda por defecto es 200 m (ajustable vía variable de entorno `CELL_SIZE_M`).
- [x] `mark_cleared(user_id, cell_id, conn)` registra de forma idempotente la primera visita de cada usuario.
- [x] Una celda cuenta como nueva solo después de que la foto pasa a `verified` en el pipeline.
- [x] Si la celda es nueva, el backend otorga los puntos adicionales definidos por la feature 008.
- [x] La app no pinta overlay de niebla ni cuadrícula; la celda solo se usa para lógica backend.
- [x] `test_cells.py` cubre conversión determinista, frontera, idempotencia y filtro por bbox.
