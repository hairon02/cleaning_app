# 012 · HTTPS Tunnel & PWA Install

## Qué hace

Configura el acceso seguro desde el iPhone al backend local mediante HTTPS (Cloudflare Tunnel o mkcert), sirve el build de Flutter desde FastAPI y verifica la instalación como PWA en Safari.

## Por qué existe

Sin HTTPS el iPhone bloquea la cámara y la geolocalización. Sin la instalación como PWA la experiencia es degradada. Este paso conecta el backend con el dispositivo real de demo.

## Criterios de aceptación

- [ ] El backend sirve el build de Flutter en `GET /` y rutas estáticas (`StaticFiles` en FastAPI apuntando a `app/build/web/`).
- [ ] `flutter build web` genera el build sin errores.
- [ ] El iPhone accede al backend por HTTPS (sin advertencia de certificado) mediante Cloudflare Tunnel **o** mkcert instalado en el dispositivo.
- [ ] La app funciona correctamente instalada como PWA desde Safari (Add to Home Screen).
- [ ] La cámara y la geolocalización funcionan en la PWA instalada (requieren HTTPS).
- [ ] El `manifest.json` de Flutter incluye nombre, iconos y colores del tema de la app.
- [ ] El `README.md` raíz documenta los dos pasos (Cloudflare Tunnel y mkcert) con los comandos exactos.
- [ ] La demo funciona en la misma red Wi-Fi (laptop ↔ iPhone) y opcionalmente con el iPhone como punto de acceso.
