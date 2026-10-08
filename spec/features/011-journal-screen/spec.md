# 011 · Journal Screen

## Qué hace

Pantalla de diario en Flutter que muestra cronológicamente las fotos verificadas del usuario junto a la descripción y etiquetas generadas por Gemma.

## Por qué existe

El diario convierte las salidas en un registro personal, dándole valor narrativo a cada exploración más allá de los puntos.

## Criterios de aceptación

- [ ] `GET /journal?user_id=X&page=N` devuelve fotos verificadas del usuario, ordenadas por `taken_at` descendente, paginadas (20 por página).
- [ ] Cada entrada muestra: thumbnail de la foto, descripción de Gemma, lista de etiquetas, fecha y hora.
- [ ] Las coordenadas exactas **no** se muestran; solo se muestra el nombre aproximado de la celda o zona (opcional).
- [ ] Scroll infinito o botón "cargar más".
- [ ] Al pulsar una foto se abre una vista de detalle a pantalla completa con la foto y su descripción completa.
- [ ] Solo se muestran fotos con `status = verified` (no duplicadas ni rechazadas).
- [ ] Si no hay fotos aún, se muestra un estado vacío con mensaje motivador para salir.
