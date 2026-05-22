#!/usr/bin/env python3
"""
Полный пайплайн для CalorieClassifier (часть 2 доклада).

1) Nutrition5k — если в этой папке есть dishes.xlsx и dish_images.pkl
2) Hugging Face Food_Calorie_Dataset — скачивается автоматически
3) Сборка datasets/CalorieClassificationData для Create ML

Запуск из папки datasets/калории:
  python3 run_calorie_pipeline.py
"""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
DATASETS_DIR = SCRIPT_DIR.parent
REGRESSION_DIR = DATASETS_DIR / "CalorieRegressionData5k"
CLASSIFICATION_DIR = DATASETS_DIR / "CalorieClassificationData"

DISHES_XLSX = SCRIPT_DIR / "dishes.xlsx"
IMAGES_PKL = SCRIPT_DIR / "dish_images.pkl"


def run_step(name: str, script: Path) -> bool:
    print(f"\n{'=' * 60}\n{name}\n{'=' * 60}")
    result = subprocess.run([sys.executable, str(script)], cwd=SCRIPT_DIR)
    if result.returncode != 0:
        print(f"Ошибка в шаге: {name}")
        return False
    return True


def count_regression_images() -> int:
    if not REGRESSION_DIR.exists():
        return 0
    exts = {".jpg", ".jpeg", ".png"}
    return sum(1 for f in REGRESSION_DIR.iterdir() if f.suffix.lower() in exts)


def print_classification_summary() -> None:
    if not CLASSIFICATION_DIR.exists():
        print("CalorieClassificationData не создана.")
        return
    print(f"\nПапка для Create ML: {CLASSIFICATION_DIR}")
    total = 0
    for folder in sorted(CLASSIFICATION_DIR.iterdir()):
        if folder.is_dir():
            n = sum(1 for f in folder.iterdir() if f.is_file())
            total += n
            print(f"  {folder.name}: {n} фото")
    print(f"  Всего: {total} фото")


def main() -> int:
    print("CalorieClassifier — подготовка данных\n")

    if DISHES_XLSX.exists() and IMAGES_PKL.exists():
        if not run_step("Nutrition5k → CalorieRegressionData5k", SCRIPT_DIR / "prepare_calorie_regression_data.py"):
            return 1
    else:
        print(
            "Nutrition5k не найден (опционально).\n"
            f"  Положи в {SCRIPT_DIR}:\n"
            "    dishes.xlsx\n"
            "    dish_images.pkl\n"
            "  Скачать: https://github.com/google-research-datasets/Nutrition5k\n"
            "Продолжаем только с Hugging Face...\n"
        )

    before = count_regression_images()
    if not run_step("Hugging Face → CalorieRegressionData5k", SCRIPT_DIR / "download_extra_calorie_data.py"):
        return 1
    after = count_regression_images()
    print(f"\nИзображений в CalorieRegressionData5k: {after} (+{after - before} с HF)")

    if after == 0:
        print(
            "\nНет ни одного изображения. Проверь интернет и:\n"
            "  pip install datasets pillow pandas openpyxl"
        )
        return 1

    if not run_step("Балансировка → CalorieClassificationData", SCRIPT_DIR / "build_calorie_classification_folders.py"):
        return 1

    print_classification_summary()
    print(
        "\nГотово. В Create ML укажи Training Data:\n"
        f"  {CLASSIFICATION_DIR}\n"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
