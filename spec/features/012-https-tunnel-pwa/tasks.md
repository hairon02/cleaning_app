# Tasks — 012 · HTTPS Tunnel & PWA Install

## Backend — servir Flutter

- [ ] En `main.py`, montar `StaticFiles(directory="app/build/web", html=True)` en `"/"`.
- [ ] Asegurarse de que el mount de `StaticFiles` va **después** de todos los routers de la API.
- [ ] Verificar que `GET /` sirve el `index.html` de Flutter correctamente.

## Flutter — build web

- [ ] Personalizar `app/web/manifest.json`: `name`, `short_name`, colores del tema, iconos (mínimo 192×192 y 512×512).
- [ ] Crear icono de la app (placeholder verde con hoja si no hay diseño final).
- [ ] Confirmar que `API_BASE_URL` se lee de `String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:8000')`.
- [ ] Correr `flutter build web --dart-define=API_BASE_URL=https://TU_URL` sin errores.

## Opción A — Cloudflare Tunnel

- [ ] Instalar `cloudflared` (winget o descarga directa).
- [ ] Verificar que `cloudflared tunnel --url http://localhost:8000` genera una URL `https://*.trycloudflare.com`.
- [ ] Hacer el build de Flutter con esa URL y verificar que la PWA funciona desde el iPhone.

## Opción B — mkcert (alternativa sin dependencia de Cloudflare)

- [ ] Instalar `mkcert` y correr `mkcert -install`.
- [ ] Generar certificado para `localhost` y la IP local: `mkcert localhost 192.168.x.x`.
- [ ] Instalar el perfil de CA raíz en el iPhone (Settings → General → VPN & Device Management).
- [ ] Arrancar Uvicorn con `--ssl-keyfile` y `--ssl-certfile`.

## Verificación en iPhone

- [ ] Abrir la URL HTTPS en Safari → la app carga sin advertencia de certificado.
- [ ] "Add to Home Screen" → la app se instala como PWA con el icono correcto.
- [ ] Abrir la PWA instalada → la cámara y el GPS funcionan (requieren HTTPS).
- [ ] Subir una foto desde el iPhone → el backend la procesa y devuelve resultado.

## Documentación

- [ ] Actualizar `README.md` raíz con los comandos exactos de ambas opciones y cómo hacer el build de Flutter.
