import json
import logging
from pathlib import Path
from typing import Any, Callable, Optional

from app.pipeline.verify import GemmaError, verify_photo

logger = logging.getLogger("eval")


def run_evaluation(
    photos_dir: Optional[Path] = None,
    labels_file: Optional[Path] = None,
    backend_caller: Optional[Callable[[str, str], str]] = None,
) -> dict[str, Any]:
    eval_dir = Path(__file__).resolve().parent
    if photos_dir is None:
        photos_dir = eval_dir / "photos"
    if labels_file is None:
        labels_file = eval_dir / "labels.json"

    if not labels_file.exists():
        print(f"Error: {labels_file} no encontrado.")
        return {}

    labels: dict[str, dict[str, Any]] = json.loads(labels_file.read_text(encoding="utf-8"))
    if not labels:
        print("El archivo labels.json está vacío.")
        return {}

    total = 0
    correct = 0
    results: list[dict[str, Any]] = []

    print("\nIniciando evaluación de Gemma...")
    print(f"{'Imagen':<30} | {'Esperado':<10} | {'Obtenido':<10} | {'Resultado':<6}")
    print("-" * 65)

    for filename, meta in labels.items():
        photo_path = photos_dir / filename
        expected = meta["is_outdoor"]
        total += 1

        if not photo_path.exists():
            print(f"{filename:<30} | {str(expected):<10} | {'FALTA':<10} | ❌ (archivo no existe)")
            results.append({
                "filename": filename,
                "expected": expected,
                "got": None,
                "ok": False,
                "error": "File not found",
            })
            continue

        try:
            verif = verify_photo(str(photo_path), backend_caller=backend_caller)
            got = verif.is_outdoor
            ok = (got == expected)
            if ok:
                correct += 1
            status_str = "✅" if ok else "❌"
            print(f"{filename:<30} | {str(expected):<10} | {str(got):<10} | {status_str}")
            results.append({
                "filename": filename,
                "expected": expected,
                "got": got,
                "ok": ok,
                "details": verif.model_dump(),
            })
        except GemmaError as err:
            print(f"{filename:<30} | {str(expected):<10} | {'ERROR':<10} | ❌ ({err})")
            results.append({
                "filename": filename,
                "expected": expected,
                "got": None,
                "ok": False,
                "error": str(err),
            })

    accuracy = (correct / total * 100.0) if total > 0 else 0.0
    print("-" * 65)
    print(f"Total: {total} | Aciertos: {correct} | Accuracy: {accuracy:.1f}%\n")

    return {
        "total": total,
        "correct": correct,
        "accuracy": accuracy,
        "results": results,
    }


if __name__ == "__main__":
    run_evaluation()
