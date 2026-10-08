# Plan — 009 · Challenge Bank & Daily/Weekly Selection

## Enfoque

Dos piezas separadas: un script offline de generación (se corre una vez antes del hackathon) y un módulo de selección determinista para el runtime. El runtime nunca llama a Gemma.

## Decisiones técnicas

- **Script `gen_challenges.py`:** llama a `verify.py` con el prompt `challenge_gen.txt`. Genera retos en lotes de 10 y los inserta en `challenges` con `reviewed = false`. Se puede re-correr sin duplicar (deduplicado por título).
- **Filtro de seguridad:** lista de palabras clave en `backend/app/challenge_filter.py` (e.g., "roof", "cliff", "private", "night", "dark"). Si el título o criterio contienen alguna, el reto se descarta.
- **Revisión manual:** el flujo esperado es: correr el script → revisar la tabla `challenges` en SQLite → marcar `reviewed = 1` en los retos aprobados. Se puede hacer con `sqlite3` CLI o con un script auxiliar.
- **Selección determinista:** `get_active_challenges()` usa `date.today().toordinal() % count_reviewed` para elegir el reto del día. Para el semanal, `date.today().isocalendar().week % count_reviewed_weekly`. Mismo día → mismo reto para todos los usuarios.
- **Endpoint `GET /challenges`:** llama a `get_active_challenges()` y serializa. Si hay menos de 1 reto reviewed de algún tipo, devuelve 503.

## Prompt `challenge_gen.txt`

Pedirá a Gemma un JSON con `title`, `description`, `visual_criterion` (condición observable en una foto), `period` (`daily`|`weekly`), `difficulty` (`easy`|`medium`|`hard`). El prompt incluirá ejemplos buenos y malos para guiar la generación.
