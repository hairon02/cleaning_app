# Plan — 008 · Camera Capture Screen

## Enfoque

Pantalla Flutter que usa `camera` package para mostrar el viewfinder y `geolocator` para registrar la posición. Todo el estado de captura se gestiona en un `ChangeNotifier` dedicado.

## Decisiones técnicas

- **`CameraController`:** se inicializa en `initState` con la cámara trasera y resolución `medium`. Se libera en `dispose`.
- **Sin galería:** no se usa `image_picker`. El único origen de la foto es `CameraController.takePicture()`.
- **GPS en el momento del disparo:** se llama a `Geolocator.getCurrentPosition()` justo antes de `takePicture()`. Si el GPS tarda más de 5 s, se muestra un spinner y se espera (no se cancela la foto).
- **Upload:** `http.MultipartRequest` a `POST /upload` con los campos `lat`, `lon`, `taken_at` y el archivo. El `user_id` viene de un `SharedPreferences` (guest id generado al primer arranque, suficiente para el hackathon).
- **Feedback de resultado:** `SnackBar` con duración de 4 s. Colores: verde (verified), amarillo (duplicate/pending), rojo (rejected). Si hay retos cumplidos, se menciona en el mensaje.
- **Navegación:** `BottomNavigationBar` con 5 tabs: Cámara (home), Mapa, Retos, Ranking, Diario.
- **Permisos:** se solicitan cámara y ubicación al primer arranque con `permission_handler`. Si se deniegan, se muestra una pantalla de error con instrucciones.
