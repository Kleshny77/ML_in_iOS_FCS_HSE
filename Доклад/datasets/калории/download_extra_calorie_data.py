#!/usr/bin/env python3
import os
import re
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
os.environ.setdefault("HF_HOME", str(SCRIPT_DIR / ".hf_cache"))
OUT_DIR = SCRIPT_DIR.parent / "CalorieRegressionData5k"
MIN_CAL = 50
MAX_CAL = 1500
TARGET_SIZE = (299, 299)


def parse_total_calories(response: str) -> int | None:
    if not response:
        return None
    m = re.search(r"[Tt]otal [Cc]alories?:\s*(\d+)", response)
    return int(m.group(1)) if m else None


def main():
    try:
        from datasets import load_dataset
    except ImportError:
        print("Установите: pip install datasets")
        return

    from PIL import Image

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    print("Загрузка aryachakraborty/Food_Calorie_Dataset с Hugging Face...")
    ds = load_dataset("aryachakraborty/Food_Calorie_Dataset", split="train", cache_dir=SCRIPT_DIR / ".hf_cache")
    print(f"Загружено {len(ds)} записей.")

    saved = 0
    for i, row in enumerate(ds):
        response = row.get("Response") or row.get("response") or ""
        cal = parse_total_calories(response)
        if cal is None or not (MIN_CAL <= cal <= MAX_CAL):
            continue
        img = row.get("image")
        if img is None:
            continue
        try:
            if hasattr(img, "resize"):
                pil = img.convert("RGB")
            else:
                from PIL import Image as PILImage
                import io
                pil = PILImage.open(io.BytesIO(img.get("bytes", img))).convert("RGB")
            pil = pil.resize(TARGET_SIZE, Image.Resampling.LANCZOS)
            out_name = f"food-{cal}-hf-{saved:05d}.jpg"
            pil.save(OUT_DIR / out_name, "JPEG", quality=90)
            saved += 1
        except Exception:
            continue
        if saved % 50 == 0 and saved:
            print(f"  сохранено {saved}...")

    print(f"Готово: {saved} новых изображений в {OUT_DIR}")


if __name__ == "__main__":
    main()
