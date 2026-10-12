# Tasks — 011 · Journal Screen

## Backend

- [x] Crear `backend/app/routes/journal.py` con `GET /journal?user_id=X&page=N` (páginas desde 0, 20 entradas).
- [x] Devolver `photo_id`, URLs protegidas para foto y thumbnail, descripción, etiquetas y fecha/hora.
- [x] Servir original y thumbnail solo si el `user_id` coincide y la foto está verificada; no publicar el directorio `uploads/` como archivos estáticos.
- [x] Registrar la ruta del journal en `main.py`.

## Flutter — pantalla del diario

- [x] Crear `lib/screens/journal_screen.dart` y cargar su primera página al entrar al diario.
- [x] Implementar `ListView.builder` con carga de 20 entradas y paginación al acercarse al final.
- [x] Mostrar thumbnail `CachedNetworkImage` (84×84), descripción truncada, etiquetas y fecha/hora local.
- [x] Al pulsar una entrada, abrir `journal_detail_screen.dart` mediante `Navigator.push`.
- [x] Mostrar la foto original con `InteractiveViewer` + `Hero`, descripción y etiquetas en detalle.
- [x] Mostrar estado vacío motivador cuando el usuario no tiene fotos verificadas.
- [x] Añadir el diario al `IndexedStack` y habilitarlo en el menú.
- [x] Mostrar estados de error y reintento tanto al cargar la primera página como páginas siguientes.

## Verificación

- [ ] Subir 3+ fotos verificadas → aparecen en el diario ordenadas por fecha.
- [ ] Pulsar una foto → se abre la vista de detalle con descripción completa.
- [ ] Las coordenadas no aparecen en ningún lugar de la UI.
- [x] Usar ui-ux-pro-max antes de implementar las pantallas frontend; registrar las búsquedas y dirección en `plan.md`.
- [x] Revisar la implementación con criterios Impeccable para Flutter nativo y registrar sus límites en `plan.md`.
- [x] Resolver hallazgos fuente: evitar lista anidada, bloquear solicitudes de página solapadas, añadir loading/error/empty, keys estables, safe areas vía `Scaffold` y navegación de detalle con back nativo.
