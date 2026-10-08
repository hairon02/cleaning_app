# Roadmap

> Cada feature nueva se crea como `features/NNN-nombre-feature/` con `spec.md`, `plan.md` y `tasks.md` antes de tocar código.

---

## Hecho ✅

1. **001 · Project Scaffold** — Esqueleto inicial del repo: estructura de carpetas `backend/` + `app/` (Flutter), `schema.sql`, `db.py`, variables de entorno y pipeline CI mínimo (`ruff`, `pytest`). Incluye identidad anónima: un `user_id` generado por dispositivo más un apodo, sin login.
2. **002 · Gemma Integration** — Conexión local con Gemma 3n vía Ollama o `transformers`; prompt de verificación que devuelve JSON validado (`is_outdoor`, `description`, `tags`, `time_of_day`, `weather`). Incluye set de evaluación, script `eval/run.py` y suite de tests con reintentos y tolerancia a markdown.

---

## MVP — En orden de construcción 🔜

### Infraestructura base

3. **003 · Photo Upload & Verification Pipeline** — ✅ Endpoint `POST /upload`: recibe la foto, con latitud, longitud y hora tomadas por el cliente en el momento de la captura (API de geolocalización del navegador); el servidor guarda además su propia hora como referencia. Calcula pHash, detecta duplicados, llama a Gemma y guarda el resultado en `photos` con el estado correcto (`verified` | `rejected` | `duplicate` | `pending_review`). Es el núcleo de toda la mecánica. Nota: que las fotos vengan solo de la cámara lo impone la interfaz, no el servidor.

5. **005 · Camera Capture Screen** — Pantalla principal: cámara en tiempo real (sin galería), botón de captura, GPS y hora registrados en el momento, feedback visual mientras se sube y verifica la foto.

### Mapa y celdas

6. **006 · Grid Cells & Fog of War** — Módulo `cells.py` + endpoint `GET /map`: convierte lat/lon a id de celda, marca las celdas despejadas del usuario y devuelve el estado del mapa. En Flutter, `flutter_map` con OpenStreetMap pinta la niebla como overlay semitransparente sobre las celdas no visitadas.

7. **007 · Map Screen** — Pantalla del mapa con niebla: celdas despejadas propias, overlay de niebla en el resto, zoom y pan. Se abre desde la pantalla de cámara como recompensa.

--- Línea de corte: hasta aquí hay un producto demostrable ---

### Puntos y ranking

8. **008 · Scoring & Points Ledger** — Módulo `scoring.py`: reglas objetivas de puntos (foto verificada, celda nueva, reto cumplido, racha de días) escritas en el ledger. `GET /ranking` devuelve el top de usuarios. Sin votos ni puntuación de calidad.

### Retos

9. **009 · Challenge Bank & Daily/Weekly Selection** — Script offline de generación de retos con Gemma + validación JSON + filtro de seguridad (sin alturas, noche ni propiedad privada). `challenges.py` selecciona el reto del día y el semanal del banco `reviewed`. Endpoint `GET /challenges` expone ambos. Gemma nunca genera retos en vivo.

10. **010 · Challenge Validation** — El criterio visual del reto activo (diario o semanal) se envía dentro de la misma llamada de verificación a Gemma, sin una segunda llamada, para no duplicar la latencia. Si la foto cumple, el backend suma los puntos correspondientes. El reto semanal vale más que el diario.

### App móvil (Flutter PWA)

11. **011 · Journal, Ranking & Challenges Screens** — Diario cronológico de fotos verificadas con su descripción y etiquetas (solo lectura), ranking de puntos sin ubicaciones y retos activos (diario y semanal) con su estado de cumplimiento.

12. **012 · PWA Install Check** — Verificación final de que la app se instala y funciona como PWA en Safari. El túnel y el acceso desde el iPhone ya se resolvieron en el 002.

## Backlog / ideas 💡

_(Estas features se abordan solo si el MVP está completo antes de que cierre el hackathon.)_

- **Nearby Recommendations** — Candidatos reales de OpenStreetMap en celdas no visitadas; Gemma elige y explica 3. El backend descarta cualquier ID no presente en la lista de candidatos.
- **Offline Map Cache** — Tiles de OpenStreetMap descargados para usar el mapa sin conexión a internet.
- **Friend Ranking** — Ranking restringido a un grupo de amigos (sin mostrar ubicaciones).
- **Demo S3 Export** — Subida opcional de fotos de demostración a S3 solo al final, para el post del hackathon.

---

## Fuera de alcance 🚫

- Votos, puntuación de calidad por IA, mapa comunitario público.
- Recomendaciones a nivel estado o país.
- Login social, nube, APIs de IA de terceros.
- Retos creados por Gemma en vivo (solo del banco revisado).
- CLIP (se reconsidera solo si la evaluación muestra fallos concretos de Gemma).
