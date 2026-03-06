#!/usr/bin/env python3

import io
import os
import pickle
from pathlib import Path

import pandas as pd
from PIL import Image

SCRIPT_DIR = Path(__file__).resolve().parent
OUT_DIR = SCRIPT_DIR.parent / "CalorieRegressionData5k"
DISHES_XLSX = SCRIPT_DIR / "dishes.xlsx"
IMAGES_PKL = SCRIPT_DIR / "dish_images.pkl"
MIN_CAL = 50
MAX_CAL = 1500
TARGET_SIZE = (299, 299)

def main():
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    print("Загрузка dishes.xlsx...")
    dishes = pd.read_excel(DISHES_XLSX, engine="openpyxl")
    dishes["dish_id"] = dishes["dish_id"].astype(str)

    print("Загрузка dish_images.pkl...")
    with open(IMAGES_PKL, "rb") as f:
        images_df = pickle.load(f)
    images_df["dish"] = images_df["dish"].astype(str)

    print("Объединение по dish_id...")
    merged = images_df.merge(
        dishes[["dish_id", "total_calories"]],
        left_on="dish",
        right_on="dish_id",
        how="inner",
    )

    merged = merged[
        (merged["total_calories"] >= MIN_CAL) & (merged["total_calories"] <= MAX_CAL)
    ]
    merged = merged.dropna(subset=["total_calories", "rgb_image"])
    print(f"После фильтра: {len(merged)} записей (калории {MIN_CAL}-{MAX_CAL})")

    saved = 0
    for idx, row in merged.iterrows():
        cal = int(round(row["total_calories"]))
        try:
            img = Image.open(io.BytesIO(row["rgb_image"])).convert("RGB")
            img = img.resize(TARGET_SIZE, Image.Resampling.LANCZOS)
            out_name = f"food-{cal}-{saved:05d}.jpg"
            img.save(OUT_DIR / out_name, "JPEG", quality=90)
            saved += 1
        except Exception as e:
            continue
        if saved % 500 == 0:
            print(f"  сохранено {saved}...")

    print(f"Готово: {saved} изображений в {OUT_DIR}")

if __name__ == "__main__":
    main()
