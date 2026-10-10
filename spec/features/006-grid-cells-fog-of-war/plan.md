# Plan — 006 · Grid Cells & Fog of War

## Enfoque

Módulo backend `cells.py` y tabla `cells` en SQLite. La lógica lat/lon → id de celda es determinista y la restricción `(user_id, cell_id)` permite detectar la primera foto verificada de cada zona. No se implementa ni se dibuja niebla en el cliente.

## Decisiones técnicas

- **Id de celda:** `f"{int(lat / cell_deg):+07d}_{int(lon / cell_deg):+07d}"`. `cell_deg` se calcula a partir de `CELL_SIZE_M` en el ecuador (≈ 200 m / 111 320 m·° ≈ 0.001797 °). Usar `math.floor` para que el punto de frontera caiga siempre en la misma celda.
- **Tabla `cells`:** `(user_id, cell_id, cleared_at)` con PRIMARY KEY `(user_id, cell_id)`. `INSERT OR IGNORE` para idempotencia.
- **`GET /map`:** recibe `bbox` como query param (`lat_min,lon_min,lat_max,lon_max`). Genera la lista completa de ids de celda dentro del bbox y devuelve cuáles están despejadas para el usuario. El cliente pinta niebla sobre las que no están en la lista.
- **Flutter:** sin overlay de niebla, cuadrícula ni contador de celdas. El mapa existente conserva solo el mapa base y sus pines de fotos.
- **Integración con 003:** `mark_cleared(user_id, cell_id)` hace `INSERT OR IGNORE INTO cells ...`; si insertó una fila nueva, devuelve `True` (celda nueva) para que scoring la puntúe.

## Riesgos

- Bbox muy grande → demasiadas celdas → respuesta lenta. Mitigación: limitar el bbox a 5 km × 5 km en el backend (≈ 625 celdas de 200 m).
