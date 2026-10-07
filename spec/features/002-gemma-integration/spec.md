# 002 · Gemma Integration

## Qué hace

Conecta el backend con Gemma 3n (local) para verificar si una imagen es un exterior natural y obtener una descripción estructurada. Incluye el set de evaluación y el script que mide el acierto del modelo.

## Por qué existe

Gemma es el núcleo de la mecánica: sin su veredicto, ninguna foto puede despejar niebla ni sumar puntos. Hay que validar que el modelo funciona y medir su acierto antes de construir encima.

## Criterios de aceptación

- [ ] `backend/app/pipeline/verify.py` expone `verify_photo(image_path: str) -> GemmaResult` con tipado completo.
- [ ] `GemmaResult` contiene: `is_outdoor: bool`, `description: str`, `tags: list[str]`, `time_of_day: str`, `weather: str`.
- [ ] El prompt está en `backend/prompts/verify.txt` (versionado); no está hardcodeado en el código.
- [ ] Si Gemma devuelve JSON inválido, hay un reintento automático; si falla de nuevo, se lanza `GemmaError`.
- [ ] `backend/eval/run.py` corre sobre las 20–30 fotos de `backend/eval/photos/` y imprime una tabla con `path`, `expected`, `got`, `ok`.
- [ ] El acierto ≥ 80 % sobre el set de evaluación (si no se llega, documentar los casos fallidos para ajustar el prompt).
- [ ] Un test unitario `test_verify.py` usa una foto fixture y comprueba que el JSON de salida es válido.
- [ ] El modelo se carga una sola vez al arrancar el proceso (no por petición).
