# 009 · Challenge Bank & Daily/Weekly Selection

## Qué hace

Script offline que usa Gemma para generar un banco de retos, los valida y los filtra. El backend selecciona automáticamente el reto del día y el semanal del banco. Ningún reto se crea en vivo para el usuario.

## Por qué existe

Los retos le dan dirección a las salidas. Generarlos por adelantado y revisarlos a mano garantiza que son seguros, claros y validables con una foto, sin añadir latencia al flujo principal.

## Criterios de aceptación

- [x] `backend/scripts/gen_challenges.py` llama a Gemma con `backend/prompts/challenge_gen.txt` y genera N retos en JSON (`title`, `description`, `visual_criterion`, `period`, `difficulty`).
- [x] El script valida cada reto contra el esquema JSON y aplica un filtro de seguridad: descarta retos con palabras clave de alturas, noche o propiedad privada.
- [x] Los retos generados se insertan en `challenges` con `reviewed = false`; el script no los aprueba automáticamente.
- [x] Solo los retos con `reviewed = true` (marcados a mano) pueden mostrarse.
- [x] `backend/app/challenges.py` expone `get_active_challenges(conn)` que devuelve el reto diario y semanal reviewed para la fecha actual. La selección es determinista: misma fecha → mismo reto.
- [x] `GET /challenges` devuelve el reto diario y el semanal activos (sin `reviewed` en la respuesta).
- [x] Si no hay retos reviewed suficientes, el endpoint devuelve 503 con mensaje claro.
- [x] `test_challenges.py` verifica: selección determinista, solo reviewed son seleccionados, período correcto.
