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
        print(f"Error: {labels_file} not found.")
        return {}

    labels: dict[str, dict[str, Any]] = json.loads(labels_file.read_text(encoding="utf-8"))
    if not labels:
        print("The labels.json file is empty.")
        return {}

    image_files = sorted(
        p for p in photos_dir.iterdir()
        if p.is_file() and p.suffix.lower() in {".jpg", ".jpeg", ".png", ".webp"}
    )
    image_names = {p.name for p in image_files}
    missing_labels = sorted(image_names - set(labels))
    stale_labels = sorted(set(labels) - image_names)
    if missing_labels or stale_labels:
        raise ValueError(
            "Evaluation labels must match photos exactly. "
            f"Missing labels: {missing_labels}; stale labels: {stale_labels}"
        )

    total = 0
    correct = 0
    true_positive = false_positive = false_negative = 0
    results: list[dict[str, Any]] = []

    print("\nStarting Gemma evaluation...")
    print(f"{'Path':<30} | {'Expected':<10} | {'Got':<10} | {'OK':<6}")
    print("-" * 65)

    for filename, meta in labels.items():
        photo_path = photos_dir / filename
        # Keep labels readable while accepting the common JPEG extension
        # variant used by the supplied fixtures.
        if not photo_path.exists() and photo_path.suffix.lower() == ".jpg":
            jpeg_path = photo_path.with_suffix(".jpeg")
            if jpeg_path.exists():
                photo_path = jpeg_path
        expected = meta["is_outdoor"]
        total += 1

        if not photo_path.exists():
            print(f"{filename:<30} | {str(expected):<10} | {'Missing':<10} | FAIL (file not found)")
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
            if expected and got:
                true_positive += 1
            elif not expected and got:
                false_positive += 1
            elif expected and not got:
                false_negative += 1
            status_str = "OK" if ok else "FAIL"
            print(f"{filename:<30} | {str(expected):<10} | {str(got):<10} | {status_str}")
            results.append({
                "filename": filename,
                "expected": expected,
                "got": got,
                "ok": ok,
                "details": verif.model_dump(),
            })
        except GemmaError as err:
            print(f"{filename:<30} | {str(expected):<10} | {'ERROR':<10} | FAIL ({err})")
            results.append({
                "filename": filename,
                "expected": expected,
                "got": None,
                "ok": False,
                "error": str(err),
            })

    accuracy = (correct / total * 100.0) if total > 0 else 0.0
    precision = (
        true_positive / (true_positive + false_positive)
        if true_positive + false_positive else 0.0
    )
    recall = (
        true_positive / (true_positive + false_negative)
        if true_positive + false_negative else 0.0
    )
    print("-" * 65)
    print(
        f"Total: {total} | Correct: {correct} | Accuracy: {accuracy:.1f}% | "
        f"Precision: {precision:.3f} | Recall: {recall:.3f}\n"
    )

    return {
        "total": total,
        "correct": correct,
        "accuracy": accuracy,
        "precision": precision,
        "recall": recall,
        "results": results,
    }


if __name__ == "__main__":
    run_evaluation()
