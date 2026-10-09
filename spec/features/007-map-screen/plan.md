# Plan — 007 · Map Screen

La pantalla usa `flutter_map` para cámara/gestos y pines, con MapLibre como
renderer de un estilo vectorial local sobre los tiles de OpenFreeMap. El estilo
se diseña para Clearing: tierra cálida, vegetación verde, agua azul y calles
pastel; no incluye capas de edificios ni símbolos o etiquetas. El backend devuelve
las fotos verificadas del usuario dentro del
viewport, con miniaturas cacheables, además de tres fotos de prueba en Puebla.
El cliente ancla cada miniatura a la coordenada de captura y reduce los
solapamientos según el zoom.

## Decisiones técnicas

- **Mapa base:** estilo MapLibre vectorial local, alimentado por OpenFreeMap;
  capas explícitas para agua, vegetación, áreas verdes y calles. No se dibujan
  edificios, rótulos ni señalizaciones, evitando depender de tiles rasterizados.
  La atribución de OpenFreeMap y OpenStreetMap permanece visible.
- **Sin desbloqueo visual:** no se pintan niebla, cuadrícula, celdas ni progreso
  de descubrimiento encima del mapa. El mapa no muestra contador de celdas.
- **Fotos por viewport:** `GET /map` consulta fotos verificadas del mismo
  usuario dentro del bbox; miniaturas de 240 × 320 px con cache HTTP.
- **Densidad progresiva:** al alejar el zoom quedan fotos representativas por
  zona; al acercarse aparecen progresivamente más pines en su coordenada real,
  con transición fade de 220 ms entre grupos.
- **Gestos:** se permite pan y zoom, pero no rotación.
- **Demo:** tres imágenes de evaluación se sirven como pines en Puebla, sin
  insertarse como fotos reales ni alterar el ledger.
- **Actualización:** se recarga al entrar y al terminar pan/zoom, con debounce
  de 500 ms; el endpoint admite viewports de hasta 50 km por lado.

## Verificación de diseño

La búsqueda de ui-ux-pro-max no encontró una receta cartográfica específica para
Flutter; se respetó la referencia `mapaexample.md` con una paleta propia: verde
para vegetación, azul para agua y carreteras crema/coral sin amarillo. MapLibre
renderiza los vectores y mantiene `flutter_map` como dueño de la cámara, gestos
y pines, para no rehacer el comportamiento ya existente.
