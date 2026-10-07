# Tasks — 011 · Ranking & Challenges Screen

## Backend

- [ ] Añadir `completed_by_user: bool` a la respuesta de `GET /challenges?user_id=X` (query a `points_ledger` por `user_id + challenge_id`).
- [ ] Verificar que `GET /ranking` y `GET /ranking/me` están disponibles (de feature 005).

## Flutter — pantalla de retos y ranking

- [ ] Crear `lib/screens/ranking_screen.dart`.
- [ ] Usar `CustomScrollView` con dos `SliverList` / `SliverToBoxAdapter`: primero retos, luego ranking.
- [ ] Sección **Retos**: llamar a `GET /challenges?user_id=X` en `initState`.
  - [ ] Tarjeta para el reto diario: título, descripción, criterio visual, "15 pts", estado ✅/pendiente.
  - [ ] Tarjeta para el reto semanal: igual con "50 pts".
  - [ ] Si 503 → mostrar `"No hay retos disponibles hoy"`.
- [ ] Sección **Ranking**: llamar a `GET /ranking` en `initState` (en paralelo con challenges via `Future.wait`).
  - [ ] `ListTile` con posición, nombre y puntos.
  - [ ] El usuario actual resaltado con `color: Theme.of(context).primaryColor`.
  - [ ] Si el usuario no está en el top 20, añadirlo al final con su posición real (`GET /ranking/me`).
- [ ] `RefreshIndicator` sobre el `CustomScrollView`.
- [ ] Añadir la pantalla al `IndexedStack` del `BottomNavigationBar`.

## Verificación

- [ ] Los retos activos se muestran con su estado de cumplimiento correcto.
- [ ] El ranking muestra los puntos actualizados después de subir fotos.
- [ ] Pull-to-refresh actualiza ambas secciones.
