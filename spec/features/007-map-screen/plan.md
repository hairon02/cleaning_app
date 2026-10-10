# Plan — 007 · Map Screen

La pantalla usa `mapbox_maps_flutter` para el mapa base, cámara y gestos, y
widgets Flutter superpuestos para los pines. El backend devuelve
las fotos verificadas del usuario dentro del
viewport, con miniaturas cacheables, además de tres fotos de prueba en Puebla.
El cliente ancla cada miniatura a la coordenada de captura y reduce los
solapamientos según el zoom.

## Decisiones técnicas

- **Mapa base:** estilo Mapbox indicado por `MAPBOX_STYLE_ID`, con estilo
  Streets como fallback. La escala y los controles de logo/atribución están
  ocultos en la presentación actual.
- **Sin desbloqueo visual:** no se pintan niebla, cuadrícula, celdas ni progreso
  de descubrimiento encima del mapa. El mapa no muestra contador de celdas.
- **Fotos por viewport:** `GET /map` consulta fotos verificadas del mismo
  usuario dentro del bbox; miniaturas de 240 × 320 px con cache HTTP.
- **Densidad progresiva:** al alejar el zoom quedan fotos representativas por
  zona; al acercarse aparecen progresivamente más pines en su coordenada real.
- **Gestos:** se permite pan y zoom, pero no rotación.
- **Demo:** tres imágenes de evaluación se sirven como pines en Puebla, sin
  insertarse como fotos reales ni alterar el ledger.
- **Actualización:** se recarga al entrar y al terminar pan/zoom, con debounce
  de 500 ms; el endpoint admite viewports de hasta 50 km por lado.

## Verificación de diseño

La pantalla actual conserva el estilo de mapa configurado en Mapbox y usa pines
Flutter personalizados. La sustitución por un estilo vectorial propio queda
pospuesta junto con la feature 006.
