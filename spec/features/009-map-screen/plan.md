# Plan — 009 · Map Screen

## Enfoque

Pantalla Flutter con `flutter_map` que combina tiles de OpenStreetMap como base y un `PolygonLayer` generado en el cliente para la niebla. El backend solo devuelve ids de celdas despejadas; el cliente genera los polígonos.

## Decisiones técnicas

- **`flutter_map` + `TileLayer`:** tiles de `https://tile.openstreetmap.org/{z}/{x}/{y}.png` con atribución requerida.
- **Generación de polígonos:** el cliente calcula el bbox del viewport (via `MapController.camera.visibleBounds`), genera todos los ids de celdas dentro del bbox, llama a `GET /map?bbox=...` y pinta niebla en las celdas no despejadas. Las despejadas se dejan sin overlay.
- **`cell_id → LatLngBounds`:** función inversa a `latlon_to_cell` que reconstruye las esquinas del polígono de la celda a partir del id. Se implementa en Dart en `lib/utils/cells.dart`.
- **Actualización del mapa:** se recarga al entrar en la pantalla y al hacer pan/zoom significativo (debounce de 500 ms para no hacer spam al backend).
- **Contador de celdas:** `GET /map` devuelve también `total_cleared` (count de celdas despejadas del usuario, sin bbox). Se muestra como `Text` en la esquina superior derecha.
- **Sin otras ubicaciones:** el endpoint no devuelve datos de otros usuarios.
- **Sin conexión:** `cached_network_image` para tiles. Si falla, fondo gris. Los polígonos de niebla siguen funcionando.
