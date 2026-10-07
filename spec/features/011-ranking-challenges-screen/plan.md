# Plan — 011 · Ranking & Challenges Screen

## Enfoque

Pantalla Flutter con dos secciones en un `CustomScrollView`: retos activos arriba (tarjetas) y ranking debajo (lista). Ambas secciones se recargan en paralelo al entrar.

## Decisiones técnicas

- **Dos `FutureBuilder` paralelos:** `Future.wait([getChallenges(), getRanking()])` al entrar en la pantalla. No se bloquea uno por el otro.
- **Tarjetas de reto:** `Card` con título, descripción, criterio visual y puntos. Icono ✅ si el usuario ya lo completó (se comprueba en el backend añadiendo `completed_by_user: bool` a la respuesta de `GET /challenges?user_id=X`).
- **Lista de ranking:** `ListView` con `ListTile` para cada posición. El usuario actual se resalta con `color: Theme.primary`. Si el usuario no está en el top 20, se añade como último elemento con su posición real.
- **Pull-to-refresh:** `RefreshIndicator` sobre el `CustomScrollView`.
- **Puntos visibles en el reto:** el diario muestra "15 pts" y el semanal "50 pts" junto al título, dejando clara la diferencia de valor.
- **503 handling:** si `GET /challenges` devuelve 503, se muestra `Center(child: Text("No hay retos disponibles hoy"))` en lugar de las tarjetas.
