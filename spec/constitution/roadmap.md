# Roadmap

> Cada feature nueva se crea como `features/NNN-nombre-feature/` con `spec.md`, `plan.md` y `tasks.md` antes de tocar código.

---

## Hecho ✅

3. **003 · Photo Upload & Verification Pipeline** — Endpoint `POST /upload`: recibe la foto, guarda el archivo y sus metadatos, calcula pHash, detecta duplicados, llama a Gemma y persiste el estado (`verified` | `rejected` | `duplicate` | `pending_review`).

1. **001 · Project Scaffold** — Esqueleto inicial del repo: estructura de carpetas `backend/` + `app/` (Flutter), `schema.sql`, `db.py`, variables de entorno y pipeline CI mínimo (`ruff`, `pytest`). Incluye identidad anónima: un `user_id` generado por dispositivo más un apodo, sin login.
2. **002 · Gemma Integration** — Conexión local con Gemma 3n vía Ollama o `transformers`; prompt de verificación que devuelve JSON validado (`is_outdoor`, `description`, `tags`, `time_of_day`, `weather`). Incluye set de evaluaci6ón, script `eval/run.py` y suite de tests con reintentos y tolerancia a markdown.
7. **007 · Map Screen** — Pantalla de mapa interactivo con fotos verificadas del usuario como pines con miniaturas, carga por viewport, selección progresiva según zoom y fotos demo de Puebla. El mapa se centra en la última ubicación disponible y no muestra niebla ni celdas.
8. **008 · Scoring & Points Ledger** — Ledger idempotente de puntos por fotos verificadas, celdas nuevas y días consecutivos; endpoints `/api/ranking` y `/api/ranking/me` exponen los totales y rachas sin ubicaciones.
9. **009 · Challenge Bank & Daily/Weekly Selection** — Banco de retos generado offline con Gemma, filtro de seguridad y revisión manual; `/api/challenges` selecciona de forma determinista un reto diario y uno semanal.

---

## MVP — En orden de construcción 🔜

### Infraestructura base


5. **005 · Camera Capture Screen** — Pantalla principal: cámara en tiempo real (sin galería), botón de captura, GPS y hora registrados en el momento, feedback visual mientras se sube y verifica la foto.

### Mapa

La pantalla de mapa 007 está completada y figura en «Hecho». El sistema de celdas y niebla 006 queda al final del backlog, sin bloquear las demás features del MVP.

--- Línea de corte: hasta aquí hay un producto demostrable ---

### Retos

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
- **006 · Grid Cells & Fog of War** — La conversión y registro de zonas nuevas en backend ya se usan para puntuar fotos verificadas (feature 008). No se implementará niebla visual; el mapa conserva fotos sobre el mapa base.

---

## Fuera de alcance 🚫

- Votos, puntuación de calidad por IA, mapa comunitario público.
- Recomendaciones a nivel estado o país.
- Login social, nube, APIs de IA de terceros.
- Retos creados por Gemma en vivo (solo del banco revisado).
- CLIP (se reconsidera solo si la evaluación muestra fallos concretos de Gemma).
