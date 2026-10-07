# Tasks — 010 · Journal Screen

## Backend

- [ ] Crear `backend/app/routes/journal.py` con `GET /journal?user_id=X&page=N`.
- [ ] Devolver lista de `JournalEntry`: `photo_id`, `photo_url`, `description`, `tags`, `taken_at`.
- [ ] `photo_url` es la ruta relativa al servidor estático (`/uploads/{user_id}/{filename}`).
- [ ] Asegurarse de que `StaticFiles` está montado en `main.py` para servir `uploads/`.
- [ ] Registrar la ruta del journal en `main.py`.

## Flutter — pantalla del diario

- [ ] Crear `lib/screens/journal_screen.dart`.
- [ ] Implementar `ListView.builder` con carga de la primera página al entrar.
- [ ] Implementar scroll infinito: al llegar al final de la lista, llamar `GET /journal?page=N+1`.
- [ ] Cada entrada: `CachedNetworkImage` como thumbnail (cuadrado, 80×80), descripción truncada a 2 líneas, chips de tags, fecha formateada.
- [ ] Al pulsar una entrada → `Navigator.push` a `lib/screens/journal_detail_screen.dart`.
- [ ] `journal_detail_screen.dart`: foto a pantalla completa con `InteractiveViewer` + `Hero`, descripción completa y tags debajo.
- [ ] Estado vacío: ilustración + texto motivador si `page=0` y la lista está vacía.
- [ ] Añadir la pantalla al `IndexedStack` del `BottomNavigationBar`.

## Verificación

- [ ] Subir 3+ fotos verificadas → aparecen en el diario ordenadas por fecha.
- [ ] Pulsar una foto → se abre la vista de detalle con descripción completa.
- [ ] Las coordenadas no aparecen en ningún lugar de la UI.
