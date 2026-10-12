# Plan — 011 · Journal Screen

## Enfoque

### Proceso visual obligatorio

Usar primero **ui-ux-pro-max** para definir jerarquía, tarjetas, estados vacíos, etiquetas, tipografía y lectura rápida. Después usar **Impeccable** para revisar densidad, contraste, truncamiento, scroll, estados de carga/error y consistencia con el resto de la app.

Registrar ambas verificaciones y resolver sus hallazgos antes de cerrar la feature.

Lista paginada de fotos verificadas del usuario, cargada desde `GET /journal`. El backend sirve las fotos como archivos estáticos; el cliente hace lazy loading de thumbnails.

## Decisiones técnicas

- **`GET /journal`:** `SELECT * FROM photos WHERE user_id = ? AND status = 'verified' ORDER BY taken_at DESC LIMIT 20 OFFSET ?`. Devuelve `photo_url` (ruta relativa al servidor estático), `description`, `tags`, `taken_at`.
- **Servir fotos:** rutas de API con `user_id` verifican la propiedad y `status = verified` antes de devolver imagen original o thumbnail. Se evita exponer el directorio de uploads como contenido estático público.
- **Flutter:** `ListView.builder` con `CachedNetworkImage` para los thumbnails. Al llegar al final de la lista se carga la siguiente página (infinite scroll con `ScrollController`).
- **Vista de detalle:** `Hero` animation desde el thumbnail hacia `InteractiveViewer` a pantalla completa. Descripción y tags debajo de la foto.
- **Privacidad:** `taken_at` se muestra como fecha y hora local; sin coordenadas ni nombre de calle.
- **Estado vacío:** ilustración simple con texto "Sal y toma tu primera foto para empezar el diario".

## Decisiones visuales (ui-ux-pro-max)

- Consultado el sistema de diseño para Flutter: recomienda jerarquía minimalista de una columna, ritmo espacioso y baja decoración. La paleta genérica sugerida no se adopta; prevalecen los tokens Rooted Warmth de `spec/DESIGN.md` y la tipografía Literata ya instalada.
- Consulta Flutter enfocada en listas y accesibilidad: usar una lista virtualizada, estados de carga/error, claves estables para filas, semántica clara y Hero en transición a detalle.
- Las thumbnails cargan bajo demanda y reducen decodificación en memoria; la vista completa usa zoom accesible por gesto.

## Revisión de Impeccable

- La pantalla se revisará como UI Flutter nativa desde el código fuente: accesibilidad, imágenes, temas, navegación atrás, safe areas y adaptividad. No se usa `impeccable detect`, ya que la guía indica que no analiza código nativo Flutter.
- La revisión en simuladores/dispositivos y tamaños de texto dinámico queda pendiente de ejecución manual.

- Auditor?a fuente aplicada: safe areas de Scaffold/AppBar, ancho responsivo, lista virtualizada, carga/reintento/estado vac?o, guardia contra p?ginas solapadas, miniaturas con decodificaci?n reducida, estilos del tema y back nativo en detalle. Sin validaci?n en dispositivo.
