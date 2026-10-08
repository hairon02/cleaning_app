# Plan — 011 · Journal Screen

## Enfoque

### Proceso visual obligatorio

Usar primero **ui-ux-pro-max** para definir jerarquía, tarjetas, estados vacíos, etiquetas, tipografía y lectura rápida. Después usar **Impeccable** para revisar densidad, contraste, truncamiento, scroll, estados de carga/error y consistencia con el resto de la app.

Registrar ambas verificaciones y resolver sus hallazgos antes de cerrar la feature.

Lista paginada de fotos verificadas del usuario, cargada desde `GET /journal`. El backend sirve las fotos como archivos estáticos; el cliente hace lazy loading de thumbnails.

## Decisiones técnicas

- **`GET /journal`:** `SELECT * FROM photos WHERE user_id = ? AND status = 'verified' ORDER BY taken_at DESC LIMIT 20 OFFSET ?`. Devuelve `photo_url` (ruta relativa al servidor estático), `description`, `tags`, `taken_at`.
- **Servir fotos:** FastAPI monta `uploads/` como `StaticFiles` en `/uploads/{user_id}/{filename}`. Las fotos se sirven con cache headers.
- **Flutter:** `ListView.builder` con `CachedNetworkImage` para los thumbnails. Al llegar al final de la lista se carga la siguiente página (infinite scroll con `ScrollController`).
- **Vista de detalle:** `Hero` animation desde el thumbnail hacia `InteractiveViewer` a pantalla completa. Descripción y tags debajo de la foto.
- **Privacidad:** `taken_at` se muestra como fecha y hora local; sin coordenadas ni nombre de calle.
- **Estado vacío:** ilustración simple con texto "Sal y toma tu primera foto para empezar el diario".
