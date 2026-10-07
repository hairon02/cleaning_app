# 011 · Ranking & Challenges Screen

## Qué hace

Pantalla combinada en Flutter que muestra el ranking global de puntos y los retos activos (diario y semanal) con su estado de cumplimiento para el usuario actual.

## Por qué existe

El ranking aporta motivación competitiva objetiva. Los retos con su estado visible le dan al usuario un objetivo concreto para su próxima salida.

## Criterios de aceptación

- [ ] Sección **Retos**: muestra el reto diario y el semanal activos (`GET /challenges`), con título, descripción y criterio visual.
- [ ] Cada reto muestra si el usuario ya lo completó hoy/esta semana (✅ o pendiente).
- [ ] Sección **Ranking**: lista de los 20 primeros con posición, nombre y puntos totales (`GET /ranking`).
- [ ] La posición del usuario actual se resalta aunque no esté en el top 20 (se muestra al final si es necesario).
- [ ] No se muestran ubicaciones de ningún usuario.
- [ ] Los puntos del reto diario son visiblemente menores que los del semanal (se muestran junto al título del reto).
- [ ] Ambas secciones se recargan al entrar en la pantalla (pull-to-refresh opcional).
- [ ] Si `GET /challenges` devuelve 503 (sin retos reviewed), se muestra un mensaje "No hay retos disponibles hoy".
