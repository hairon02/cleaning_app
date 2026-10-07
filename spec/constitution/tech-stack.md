# Tech stack y convenciones

## Tecnologías

- **Lenguaje:** Python 3.11+ (backend, con type hints) y Dart (app Flutter).
- **Framework / runtime:** FastAPI + Uvicorn (backend). Flutter Web instalada como PWA en iPhone; el backend sirve el build. `flutter_map` con tiles de OpenStreetMap para el mapa.
- **IA:** un solo modelo, Gemma 3n (E2B o E4B), 100% local. Se sirve con Ollama o con `transformers` según cuál acepte imágenes en esta máquina (por confirmar). Anti-duplicados con hash perceptual (`imagehash` + Pillow), sin modelo.
- **Base de datos:** SQLite (módulo `sqlite3` de la stdlib, SQL explícito, sin ORM).
- **Tests:** pytest para el backend (puntos, celdas, duplicados, validación de la salida de Gemma). Un set de evaluación manual de 20-30 fotos (paisajes, interiores, capturas, fotos de pantalla) mide el acierto de Gemma. En Flutter, `flutter_test` solo para lógica sencilla.
- **Despliegue:** 100% local en la laptop (i5-10300H, 16 GB RAM, GTX 1650 Ti 4 GB). El iPhone accede por un túnel HTTPS (Cloudflare Tunnel o mkcert). Sin nube para inferencia ni datos. S3 solo como extra opcional al final, para fotos de demo.

## Archivos / módulos clave

- `backend/app/main.py` — app FastAPI; monta la API y sirve el build de Flutter.
- `backend/app/routes/` — endpoints (`/upload`, `/map`, `/ranking`, `/challenges`, `/recommendations`).
- `backend/app/challenges.py` y `backend/prompts/challenge_gen.txt` — selección diaria y generación del banco de retos.
- `backend/app/pipeline/verify.py` — llamada a Gemma: verifica exterior natural y genera descripción/etiquetas en JSON validado.
- `backend/app/pipeline/phash.py` — hash perceptual y detección de duplicados.
- `backend/app/cells.py` — conversión de lat/lon a celda de cuadrícula y lógica de niebla.
- `backend/app/scoring.py` — reglas de puntos (foto verificada, celda nueva, reto, racha).
- `backend/app/recommend.py` — _(opcional)_ candidatos de OpenStreetMap y ranking con Gemma.
- `backend/app/db.py` y `backend/schema.sql` — conexión SQLite y esquema.
- `backend/prompts/` — prompts de Gemma, versionados como archivos de texto.
- `backend/eval/` — fotos de evaluación y script que mide el acierto.
- `backend/uploads/` — fotos subidas (fuera de git).
- `app/` — proyecto Flutter (cámara, geolocalización, mapa con niebla, diario, ranking).

## Comandos

- `uvicorn app.main:app --reload --host 0.0.0.0` — arranca el backend local (desde `backend/`).
- `flutter run -d chrome` — app en desarrollo; `flutter build web` — genera el build que sirve FastAPI.
- `pytest` — ejecuta los tests del backend.
- `python -m eval.run` — mide el acierto de Gemma sobre el set de evaluación (por crear).
- `ruff check .` — revisa el estilo de Python.
- `ollama serve` — servidor de modelos local (si se usa Ollama; verificar el tag exacto de Gemma).
- `cloudflared tunnel --url http://localhost:8000` — expone el backend por HTTPS para el iPhone.

## Modelo de datos / dominio

- `photos` — `user_id`, ruta, `lat`, `lon`, `taken_at`, `cell_id`, `phash`, `gemma_json` (respuesta validada), `status` (`verified` | `rejected` | `duplicate` | `pending_review`).
- `cells` — celdas de cuadrícula derivadas del GPS redondeado (tamaño por definir). Una celda está **despejada** para un usuario si tiene al menos una foto `verified` suya. El resto del mapa se dibuja en gris.
- `challenges` — `period` (`daily` | `weekly`), título, `criterio_visual` (condición de sí/no que Gemma pueda validar), dificultad y `reviewed` (solo los revisados a mano pueden mostrarse). La app elige uno por día de este banco. Los puntos del diario son menores que los del semanal.
- `points_ledger` — registro de movimientos de puntos. El total se calcula sumando el ledger, nunca es un campo editable.
- **Regla clave:** solo las fotos `verified` despejan celdas y suman puntos. Una foto con `phash` casi idéntico al de otra previa pasa a `duplicate`.
- **Puntos por reglas objetivas:** foto verificada, celda nueva, reto cumplido, racha de días. Valores por definir. Sin votos ni puntuación de calidad por IA.
- **Recomendaciones (opcional):** los lugares salen siempre de candidatos reales de OpenStreetMap en celdas no despejadas; Gemma solo elige y explica.

## Convenciones

- Python en `snake_case`; Dart con `lowerCamelCase` y clases en `PascalCase`. Código y nombres en inglés; texto de la interfaz en inglés también, solo para la carpeta `/spec` seria en español.
- Tests en `backend/tests/`, un archivo por módulo (`test_scoring.py`, etc.).
- Entradas de la API validadas con modelos Pydantic. Errores con `HTTPException` y códigos claros.
- La salida de Gemma se valida contra un esquema JSON. Si falla, un reintento y, si vuelve a fallar, la foto queda en `pending_review`; el upload nunca debe romperse por el modelo.
- En recomendaciones, el backend rechaza cualquier ID que Gemma devuelva y que no estuviera en la lista de candidatos.
- Las fotos se toman con la cámara en el momento (no desde la galería); GPS y hora se registran en esa captura, no desde el EXIF.
- Un solo modelo cargado en GPU a la vez (4 GB de VRAM).
- Los retos se generan con Gemma por adelantado, se validan contra un esquema JSON y un filtro de seguridad en el backend (sin lugares altos, de noche, ni propiedad privada), y se revisan a mano antes de marcarse `reviewed`. Gemma nunca crea retos en vivo para el usuario.

## Estilo visual

- El estilo visual está definido en `spec/DESIGN.md`.

## Límites duros

- No enviar fotos, ubicaciones ni metadatos a servicios de terceros. La inferencia es siempre local (sin APIs de OpenAI, Gemini u otras). Las únicas salidas a internet permitidas son los tiles de OpenStreetMap y, si se implementan las recomendaciones, consultas a Overpass con un área aproximada, nunca con fotos.
- No añadir dependencias sin avisar.
- No añadir votos ni puntuación de calidad por IA al ranking; el ranking no debe premiar el tiempo en pantalla.
- No aceptar fotos de la galería como válidas para puntos.
- No subir `.env*`, `uploads/` ni bases de datos al repositorio.
- No registrar coordenadas exactas en logs.
- No mostrar la ubicación de un usuario a otros usuarios.
- No mostrar un reto que no esté marcado `reviewed`.
