# Tasks — 008 · Camera Capture Screen

## Configuración de permisos

- [ ] Añadir permisos de cámara y ubicación en `ios/Runner/Info.plist` (PWA en Safari los requiere).
- [ ] Añadir permisos en `AndroidManifest.xml` (por si se prueba en Android).
- [ ] Implementar solicitud de permisos al arrancar con `permission_handler`.
- [ ] Pantalla de error si permisos denegados, con instrucciones para activarlos.

## Pantalla de cámara

- [ ] Crear `lib/screens/camera_screen.dart`.
- [ ] Inicializar `CameraController` con cámara trasera y resolución `medium` en `initState`.
- [ ] Mostrar `CameraPreview` a pantalla completa con botón de disparo centrado en la parte inferior.
- [ ] Botón de disparo: llama a `controller.takePicture()`, obtiene GPS (`Geolocator.getCurrentPosition()`), muestra spinner.
- [ ] Deshabilitar el botón mientras se procesa para evitar dobles capturas.

## Upload y feedback

- [ ] Crear `lib/services/api_service.dart` con `uploadPhoto(XFile file, double lat, double lon, DateTime takenAt) -> PhotoResult`.
- [ ] `API_BASE_URL` leída de `--dart-define` (fallback a `http://localhost:8000` en desarrollo).
- [ ] `user_id` generado como UUID v4 y guardado en `SharedPreferences` al primer arranque.
- [ ] Mostrar `SnackBar` con el resultado: ✅ verde (verified + descripción corta), ♻️ amarillo (duplicate), ❌ rojo (rejected), ⏳ gris (pending_review).
- [ ] Si hay retos completados, añadirlos al mensaje del SnackBar.
- [ ] Timeout de 30 s en el request; mostrar error y botón de reintento si falla.

## Navegación

- [ ] Crear `lib/widgets/bottom_nav.dart` con 5 tabs: Cámara, Mapa, Retos & Ranking, Diario, (reservado).
- [ ] Integrar `BottomNavigationBar` en `lib/main.dart` con `IndexedStack` para mantener el estado de cada pantalla.

## Verificación

- [ ] La pantalla principal abre la cámara al iniciar la app.
- [ ] Capturar una foto → se sube → aparece feedback del resultado.
- [ ] El GPS y la hora del disparo se incluyen en el request (verificar en los logs del backend).
