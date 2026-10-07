# 008 · Camera Capture Screen

## Qué hace

Pantalla principal de la app Flutter: muestra la cámara en tiempo real, captura la foto (sin galería), registra GPS y hora en ese momento y sube la foto al backend mostrando feedback del resultado.

## Por qué existe

Es el punto de entrada de toda la mecánica. La cámara como pantalla principal refuerza que el valor ocurre afuera, no frente a la pantalla.

## Criterios de aceptación

- [ ] Al abrir la app, la pantalla inicial es la cámara (no un menú ni un mapa).
- [ ] Se usa `camera` package de Flutter; no se permite seleccionar de la galería.
- [ ] GPS y hora se obtienen en el momento del disparo (no del EXIF): `geolocator` + `DateTime.now()`.
- [ ] Si el GPS no está disponible, se muestra un error y no se permite capturar.
- [ ] Tras capturar, se muestra un indicador de carga mientras el backend procesa.
- [ ] La respuesta se muestra como un banner: ✅ verificada + descripción breve, ♻️ duplicada, ❌ rechazada, ⏳ en revisión.
- [ ] Si el backend no responde en 30 s, se muestra un error y se permite reintentar.
- [ ] Barra de navegación inferior con iconos hacia: Mapa, Retos, Ranking, Diario.
- [ ] La UI respeta las zonas seguras de iOS (notch, home indicator).
