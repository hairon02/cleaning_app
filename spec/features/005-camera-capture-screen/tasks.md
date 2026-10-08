# Tasks — 005 · Camera Capture Screen

## Configuración de permisos

- [x] Añadir permisos de cámara y ubicación en `ios/Runner/Info.plist`.
- [x] Añadir permisos en `AndroidManifest.xml`.
- [x] Implementar solicitud de permisos al arrancar con `permission_handler`.
- [x] Pantalla de error si permisos denegados, con instrucciones para activarlos.

## Pantalla de cámara

- [x] Crear `lib/screens/camera_screen.dart`.
- [x] Inicializar `CameraController` con cámara trasera y resolución `medium`.
- [x] Mostrar `CameraPreview` a pantalla completa con botón de disparo inferior.
- [x] Capturar foto, obtener GPS y hora, y mostrar spinner durante el proceso.
- [x] Deshabilitar el botón mientras se procesa para evitar dobles capturas.

## Upload y feedback

- [x] Crear `lib/services/api_service.dart` para subir la foto como multipart.
- [x] Leer `API_BASE_URL` de `--dart-define`, con fallback local.
- [x] Generar y persistir `user_id` UUID v4 en `SharedPreferences`.
- [x] Mostrar feedback para `verified`, `duplicate`, `rejected` y `pending_review`.
- [x] Mostrar retos completados cuando la respuesta los incluya.
- [x] Aplicar timeout de 30 s y permitir reintentar.

## Navegación

- [x] Crear `lib/widgets/bottom_nav.dart` con Cámara, Mapa, Retos, Ranking y Diario.
- [x] Integrar `BottomNavigationBar` mediante `IndexedStack` en `main.dart`.

## Verificación

- [x] La pantalla principal abre la cámara al iniciar la app.
- [x] Verificación manual en un dispositivo con cámara y GPS reales.

## Proceso de diseño y revisión

- [x] Usar ui-ux-pro-max para definir/verificar la dirección visual y las reglas Flutter de la pantalla.
- [x] Usar Impeccable para auditar y pulir la implementación en sus estados principales.
- [x] Registrar y resolver los hallazgos de ambas skills antes de cerrar la feature.
- [x] Estado final verificado: permisos, cámara, GPS, hora, subida, feedback, navegación, prueba manual y revisión visual completados.
