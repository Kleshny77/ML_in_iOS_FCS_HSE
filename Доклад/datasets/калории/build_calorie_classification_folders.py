#!/usr/bin/env python3

import random
import shutil
from pathlib import Path

SRC = Path(__file__).resolve().parent.parent / "CalorieRegressionData5k"
OUT = Path(__file__).resolve().parent.parent / "CalorieClassificationData"

BIN_STEP = 100
CAL_MIN, CAL_MAX = 50, 1500
MAX_PER_CLASS = 450
MIN_PER_CLASS = 180


def get_bins():
    bins = []
    for i in range(12):
        lo, hi = 50 + i * 100, 50 + (i + 1) * 100
        bins.append((lo, hi, (i + 1) * 100))
    bins.append((1250, CAL_MAX, 1300))
    return bins


def get_bin_label(cal: int) -> int:
    for lo, hi, label in get_bins():
        if lo <= cal < hi:
            return label
    return get_bins()[-1][2]


def main():
    if not SRC.exists():
        print(f"Нет папки {SRC}")
        return
    random.seed(42)
    OUT.mkdir(parents=True, exist_ok=True)
    for d in OUT.iterdir():
        if d.is_dir():
            shutil.rmtree(d)

    by_label: dict[int, list[Path]] = {}
    for f in SRC.iterdir():
        if f.suffix.lower() not in (".jpg", ".jpeg", ".png"):
            continue
        parts = f.stem.split("-")
        if len(parts) < 2:
            continue
        try:
            cal = int(parts[1])
        except ValueError:
            continue
        label = get_bin_label(cal)
        by_label.setdefault(label, []).append(f)

    print("Шаг 100 ккал, классы:", [f"cal_{b[2]}" for b in get_bins()])
    print("До балансировки:", {f"cal_{k}": len(v) for k, v in sorted(by_label.items())})

    total = 0
    for label, paths in sorted(by_label.items()):
        folder_name = f"cal_{label}"
        dest_dir = OUT / folder_name
        dest_dir.mkdir(exist_ok=True)
        if len(paths) > MAX_PER_CLASS:
            chosen = random.sample(paths, MAX_PER_CLASS)
        else:
            chosen = list(paths)
        while len(chosen) < MIN_PER_CLASS:
            chosen.append(random.choice(paths))
        for i, src in enumerate(chosen):
            name = f"food-{label}-{i:04d}{src.suffix}"
            shutil.copy2(src, dest_dir / name)
            total += 1
        print(f"  {folder_name}: {len(chosen)} примеров")

    print(f"\nГотово: {total} файлов в {OUT}")


if __name__ == "__main__":
    main()
