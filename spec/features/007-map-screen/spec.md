# 007 · Map Screen

## Qué hace

Pantalla del mapa en Flutter que muestra las celdas despejadas del usuario y un overlay de niebla semitransparente sobre el resto. El usuario puede hacer zoom y pan.

## Por qué existe

El mapa es la recompensa visual de explorar: ver cómo se aclara el territorio motiva a seguir saliendo. Debe cargarse rápido y ser legible en segundos.

## Criterios de aceptación

- [ ] Usa `flutter_map` con tiles de OpenStreetMap como capa base.
- [ ] Al entrar en la pantalla, se llama a `GET /map?bbox=...` con el bbox del viewport actual.
- [ ] Las celdas despejadas del usuario se pintan sin overlay (mapa visible).
- [ ] El resto del bbox se cubre con un `PolygonLayer` gris semitransparente (70 % de opacidad).
- [ ] Cuando el usuario hace pan o zoom significativo, se recarga el bbox del mapa.
- [ ] El mapa se centra inicialmente en la última posición conocida del usuario.
- [ ] No se muestran celdas ni ubicaciones de otros usuarios.
- [ ] Si no hay conexión a internet (tiles), se muestra un fondo gris con las celdas despejadas del usuario igualmente visibles.
- [ ] La pantalla incluye un contador de celdas despejadas en una esquina ("42 zonas exploradas").
