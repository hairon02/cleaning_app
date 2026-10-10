# 007 · Map Screen

## Qué hace

Pantalla de mapa en Flutter con el mapa base a color y fotos verificadas del usuario como pines de ubicación. Cada pin muestra una miniatura vertical con borde claro y punta inferior anclada a las coordenadas exactas de captura. El usuario puede hacer zoom y pan.

## Por qué existe

El mapa es el diario geográfico de la exploración: al desplazarse se cargan las fotos de esa zona; al acercarse, los pines cercanos se separan y aparecen más miniaturas. Debe moverse con fluidez, cargar miniaturas ligeras y mantener cada pin en su coordenada real.

### Dirección visual y comportamiento

- Usar el estilo de mapa Mapbox configurado en la app como mapa base a color.
- Representar cada foto como miniatura vertical de 62 × 72 dp, con marco blanco fino, sombra suave y punta centrada hacia la coordenada de captura.
- Al alejar el zoom, conservar algunas fotos representativas por zona; al acercarse, revelar progresivamente más pines sin mover sus coordenadas.
- Desvanecer suavemente el grupo anterior de pines al cambiar la densidad y bloquear la rotación del mapa.
- Consultar fotos por bbox al terminar pan/zoom, con debounce de 500 ms y miniaturas cacheables de hasta 240 × 320 px.

## Criterios de aceptación

- [x] Usa Mapbox para dibujar el mapa base configurado en la app.
- [x] Al entrar en la pantalla, se llama a `GET /map?bbox=...` con el bbox del viewport actual.
- [x] El mapa base permanece a color; no se pinta cuadrícula, máscaras circulares ni niebla gris sobre tiles.
- [x] Cada foto verificada aparece como pin con miniatura y punta hacia la ubicación capturada.
- [x] Al alejar el zoom permanecen algunas fotos; al acercarse aparecen progresivamente más fotos sin desplazar su ubicación.
- [x] Los cambios de densidad se animan con fade y la rotación está desactivada.
- [x] El resto del bbox se mantiene como mapa base a color, sin cuadrícula ni máscara.
- [x] Cuando el usuario termina pan o zoom, se recarga el bbox con debounce de 500 ms.
- [x] El mapa se centra inicialmente en la última posición conocida del usuario.
- [x] No se muestran celdas ni fotos de otros usuarios.
- [x] No muestra progreso de celdas ni áreas desbloqueadas; solo fotos ubicadas sobre el mapa base.
- [x] El mapa base permanece a color y se ocultan la escala y los controles de marca/atribución solicitados.
