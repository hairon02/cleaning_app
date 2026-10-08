# Resultados de Evaluación — Gemma 3n

## Resumen

- **Modelo evaluado:** `gemma3:4b`
- **Backend:** Ollama (`http://localhost:11434/api/generate`)
- **Fecha de ejecución:** 2026-10-07
- **Objetivo de acierto:** ≥ 80%

## Registro de pruebas

El script `eval/run.py` compara las imágenes de prueba contra `eval/labels.json`.
Al momento de desplegar el servidor Ollama local con el modelo Gemma 3n, se ejecuta:
```bash
python -m eval.run
```

Para entornos CI y sin modelo descargado, la suite `pytest backend/tests/test_verify.py` valida la robustez de parsing, desinfección de markdown, esquema Pydantic y los reintentos automáticos ante respuestas malformadas.
