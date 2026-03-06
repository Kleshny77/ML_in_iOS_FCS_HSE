#!/usr/bin/env python3
import os
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
os.environ.setdefault("HF_HOME", str(SCRIPT_DIR / ".hf_cache"))
TRAIN_DIR = SCRIPT_DIR / "TrainingData"
VALID_DIR = SCRIPT_DIR / "ValidationData"

TARGET_CLASSES = {"pizza": "pizza", "sushi": "sushi", "hamburger": "burger"}


def main():
    try:
        from datasets import load_dataset
    except ImportError:
        print("Установите: pip install datasets pillow")
        return

    from PIL import Image

    for d in (TRAIN_DIR, VALID_DIR):
        for sub in TARGET_CLASSES.values():
            (d / sub).mkdir(parents=True, exist_ok=True)

    print("Загрузка ethz/food101 с Hugging Face (может занять время, ~5 GB)...")
    ds_train = load_dataset("ethz/food101", split="train", cache_dir=SCRIPT_DIR / ".hf_cache", trust_remote_code=False)
    ds_valid = load_dataset("ethz/food101", split="validation", cache_dir=SCRIPT_DIR / ".hf_cache", trust_remote_code=False)
    id2name = ds_train.features["label"].names

    def process_split(ds, out_dir: Path, prefix: str):
        added = {"pizza": 0, "sushi": 0, "burger": 0}
        for i in range(len(ds)):
            row = ds[i]
            label_id = row["label"]
            name = id2name[label_id]
            if name not in TARGET_CLASSES:
                continue
            our_class = TARGET_CLASSES[name]
            img = row.get("image")
            if img is None:
                continue
            if not isinstance(img, Image.Image):
                img = Image.open(img).convert("RGB")
            out_path = out_dir / our_class / f"{prefix}_{i}.jpg"
            img.save(out_path, "JPEG", quality=90)
            added[our_class] += 1
        return added

    print("Извлечение train (pizza, sushi, hamburger->burger)...")
    t = process_split(ds_train, TRAIN_DIR, "food101")
    print(f"  Добавлено: pizza={t['pizza']}, sushi={t['sushi']}, burger={t['burger']}")

    print("Извлечение validation...")
    v = process_split(ds_valid, VALID_DIR, "food101_val")
    print(f"  Добавлено: pizza={v['pizza']}, sushi={v['sushi']}, burger={v['burger']}")

    print("Готово.")


if __name__ == "__main__":
    main()
