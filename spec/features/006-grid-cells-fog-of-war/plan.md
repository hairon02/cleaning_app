# Plan — 006 · Grid Cells & Fog of War

## Enfoque

### Proceso visual obligatorio

Usar primero **ui-ux-pro-max** para definir jerarquía, contraste, tokens, responsive, controles de zoom/pan y accesibilidad del mapa y la niebla. Después usar **Impeccable** para auditar la interfaz implementada y corregir legibilidad, targets táctiles, navegación y rendimiento en Web/PWA y móvil.

Registrar ambas verificaciones y resolver sus hallazgos antes de cerrar la feature.

Módulo `cells.py` puramente funcional (sin estado propio) + tabla `cells` en SQLite. La lógica de conversión lat/lon → id de celda es determinista y testeada de forma aislada.

## Decisiones técnicas

- **Id de celda:** `f"{int(lat / cell_deg):+07d}_{int(lon / cell_deg):+07d}"`. `cell_deg` se calcula a partir de `CELL_SIZE_M` en el ecuador (≈ 200 m / 111 320 m·° ≈ 0.001797 °). Usar `math.floor` para que el punto de frontera caiga siempre en la misma celda.
- **Tabla `cells`:** `(user_id, cell_id, cleared_at)` con PRIMARY KEY `(user_id, cell_id)`. `INSERT OR IGNORE` para idempotencia.
- **`GET /map`:** recibe `bbox` como query param (`lat_min,lon_min,lat_max,lon_max`). Genera la lista completa de ids de celda dentro del bbox y devuelve cuáles están despejadas para el usuario. El cliente pinta niebla sobre las que no están en la lista.
- **Flutter overlay:** `PolygonLayer` con un `Polygon` por celda no despejada, color `Colors.grey.withOpacity(0.7)`. Las celdas se generan en el cliente a partir de los ids del bbox.
- **Integración con 003:** `mark_cleared(user_id, cell_id)` hace `INSERT OR IGNORE INTO cells ...`; si insertó una fila nueva, devuelve `True` (celda nueva) para que scoring la puntúe.

## Riesgos

- Bbox muy grande → demasiadas celdas → respuesta lenta. Mitigación: limitar el bbox a 5 km × 5 km en el backend (≈ 625 celdas de 200 m).
