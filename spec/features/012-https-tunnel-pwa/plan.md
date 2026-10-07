# Plan — 012 · HTTPS Tunnel & PWA Install

## Enfoque

Dos pasos independientes: (A) servir el build de Flutter desde FastAPI y (B) exponer el backend por HTTPS para el iPhone. Se documenta tanto Cloudflare Tunnel (sin certificado local) como mkcert (sin dependencia de Cloudflare).

## Decisiones técnicas

- **`StaticFiles` en FastAPI:** `app.mount("/", StaticFiles(directory="app/build/web", html=True), name="static")`. Debe ir **después** de todos los routers de la API.
- **`flutter build web`:** añadir `--base-href /` si hay problemas de rutas. El build se genera en `app/build/web/`.
- **Opción A — Cloudflare Tunnel:** `cloudflared tunnel --url http://localhost:8000`. Genera una URL `https://*.trycloudflare.com` válida. Sin cuenta requerida para el demo. Hay que actualizar la URL base en la app al cambiar de sesión.
- **Opción B — mkcert:** `mkcert -install && mkcert localhost 192.168.x.x`. Certificado instalado en la laptop. Uvicorn arranca con `--ssl-keyfile` y `--ssl-certfile`. El perfil del certificado raíz se instala en el iPhone (Settings → Profile). URL estable mientras la IP no cambie.
- **`manifest.json`:** Flutter genera uno por defecto; se personaliza en `app/web/manifest.json` con `name`, `short_name`, `theme_color` (verde del tema), `background_color`, y los iconos del proyecto.
- **Variable de entorno `API_BASE_URL`:** la app Flutter la lee de `--dart-define=API_BASE_URL=https://...` al hacer `flutter build web`. Se documenta en el README.

## Comandos en el README

```bash
# Build Flutter
cd app && flutter build web --dart-define=API_BASE_URL=https://TU_URL

# Opción A: Cloudflare Tunnel
cloudflared tunnel --url http://localhost:8000

# Opción B: mkcert
mkcert -install
mkcert localhost 192.168.x.x
uvicorn app.main:app --host 0.0.0.0 --ssl-keyfile localhost+1-key.pem --ssl-certfile localhost+1.pem
```
