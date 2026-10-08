# Tasks — 007 · Map Screen

## Backend

- [ ] Añadir campo `total_cleared` (int) a la respuesta de `GET /map` con el count total de celdas del usuario (sin filtro de bbox).

## Flutter — utilidades

- [ ] Crear `lib/utils/cells.dart` con `latLonToCell(lat, lon, sizeDeg) -> String` en Dart (misma lógica que el backend).
- [ ] Implementar `cellToBounds(cellId, sizeDeg) -> LatLngBounds` que reconstruye los 4 vértices del polígono.
- [ ] Implementar `getCellsInBbox(LatLngBounds bbox, sizeDeg) -> List<String>` que genera todos los ids dentro del bbox.

## Flutter — pantalla del mapa

- [ ] Crear `lib/screens/map_screen.dart`.
- [ ] Mostrar `FlutterMap` con `TileLayer` de OSM y atribución requerida.
- [ ] Centrar el mapa en la última posición conocida (o posición actual via Geolocator) al entrar.
- [ ] Llamar a `GET /map?user_id=X&bbox=...` al entrar y al mover el mapa (debounce 500 ms via `Timer`).
- [ ] Calcular celdas no despejadas = `getCellsInBbox(viewport)` − `cleared` devueltas por el backend.
- [ ] Pintar `PolygonLayer` con las celdas no despejadas en `Colors.grey.withOpacity(0.7)`.
- [ ] Mostrar contador de celdas despejadas en `Positioned` esquina superior derecha.
- [ ] Añadir la pantalla al `IndexedStack` del `BottomNavigationBar` (feature 008).

## Verificación

- [ ] Al abrir el mapa tras subir una foto verificada, la celda correspondiente aparece despejada.
- [ ] Al desplazarse a una zona nueva, el mapa recarga las celdas del nuevo bbox.
- [ ] El contador muestra el número correcto de celdas despejadas.
- [ ] Usar ui-ux-pro-max antes de implementar la pantalla del mapa.
- [ ] Usar Impeccable después de implementar para auditar y pulir la pantalla.
- [ ] Registrar y resolver los hallazgos de ambas skills.
