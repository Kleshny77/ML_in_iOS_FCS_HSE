# LunchClassifier — классификатор обеда

iOS-приложение: фото еды → класс (pizza / sushi / burger) и калории. Две модели: **FoodClassifier** (тип блюда) и **CalorieClassifier** (калории по фото). Обе обучаются в **Create ML** (Image Classification).

---

## Запуск

1. Открой **LunchClassifier.xcodeproj** в Xcode.
2. Обучи обе модели по инструкции ниже и добавь **FoodClassifier.mlmodel** и **CalorieClassifier.mlmodel** в группу LunchClassifier в навигаторе.
3. Run на симуляторе или устройстве.

Без моделей приложение напишет, что модель не загружена.

---

## На каких данных обучать

| Модель | Папка с данными | Где лежит |
|--------|-----------------|-----------|
| **FoodClassifier** | **TrainingData** (Training), **ValidationData** (Validation) | `Доклад/datasets/` |
| **CalorieClassifier** | **CalorieClassificationData** (одна папка = Training; Validation можно Auto) | `Доклад/datasets/` |

- **TrainingData** / **ValidationData** — подпапки `pizza/`, `sushi/`, `burger/` с фото. Уже подготовлены в репо.
- **CalorieClassificationData** — подпапки **cal_100, cal_200, …, cal_1100** (шаг 100 ккал). Собраны из Nutrition5k с балансировкой. Калории в приложении **только из модели**; если CalorieClassifier не добавлен — показывается «—».

---

## Обучение в Create ML (по шагам)

### 1. FoodClassifier (тип блюда)

1. Открой **Create ML** (Xcode → Window → Developer Tools → Create ML, или приложение Create ML).
2. **New Document** → **Image Classification** → Next → имя **FoodClassifier** → Create.
3. **Training Data:** укажи папку **`datasets/TrainingData`** (внутри — pizza, sushi, burger).
4. **Validation Data:** укажи **`datasets/ValidationData`**.
5. Augmentation: включи **Flip**, **Rotate** (по желанию Crop, Expose).
6. **Train** → дождись окончания → **Output** → **Save** → сохрани как **FoodClassifier.mlmodel**.
7. Перетащи **FoodClassifier.mlmodel** в группу LunchClassifier в Xcode (Copy items, target LunchClassifier).

### 2. CalorieClassifier (калории)

1. В Create ML: **New Document** (или новый проект) → **Image Classification** → имя **CalorieClassifier**.
2. **Training Data:** укажи папку **`datasets/CalorieClassificationData`** (внутри — cal_100, cal_200, …, cal_1100).
3. **Validation:** оставь **Auto Split from Training Data**.
4. Augmentation: **Flip**, **Rotate** (для лучшего качества — также Crop, Expose). Iterations можно поставить 50–100.
5. **Train** → **Save** → **CalorieClassifier.mlmodel**.
6. Перетащи **CalorieClassifier.mlmodel** в группу LunchClassifier в Xcode.

Готово. Калории в приложении **только из модели**; без неё отображается «—».

---

## Откуда датасеты (для презентации)

**Пицца, суши, бургер (FoodClassifier):**
- Готовые данные лежат в репо: **`Доклад/datasets/TrainingData`** и **`Доклад/datasets/ValidationData`** (внутри подпапки `pizza/`, `sushi/`, `burger/` с фото).
- **Откуда скачивал (ссылки для презентации):**
  - **archive-2** (pizza, sushi, steak → использованы pizza и sushi): [Pizza, Steak and Sushi | Kaggle](https://www.kaggle.com/datasets/evilspirit05/pizza-steak-sushi)
  - **archive-3** (Pizza, burgers, Softdrinks, файл `Training_set_food.csv`): [Food Recognition - Burger, Pizza & Coke | Kaggle](https://www.kaggle.com/datasets/manishkc06/food-classification-burger-pizza-coke)  
- **Food-101** (только pizza, sushi, hamburger→burger): [ethz/food101 | Hugging Face](https://huggingface.co/datasets/ethz/food101) — добавляется скриптом **`download_food101_pizza_sushi_burger.py`** (см. ниже).  
  Из этих источников отобраны классы pizza, sushi, burger и разложены по папкам. Сырые архивы Kaggle лежат в **`datasets/archive-2`** и **`datasets/archive-3`**.

**Калории (CalorieClassifier):**
- **Nutrition5k** — таблица `dishes.xlsx` и картинки в `dish_images.pkl`. Скачать: [Nutrition5k (GitHub)](https://github.com/google-research-datasets/Nutrition5k). Файлы положить в **`datasets/калории/`**, затем запустить скрипты `prepare_calorie_regression_data.py` и `build_calorie_classification_folders.py` — получится папка **CalorieClassificationData**.
- Дополнительно: датасет с Hugging Face [aryachakraborty/Food_Calorie_Dataset](https://huggingface.co/datasets/aryachakraborty/Food_Calorie_Dataset) — скрипт **`download_extra_calorie_data.py`** в `datasets/калории/`.

---

## Добавить больше данных для FoodClassifier (дообучение)

Чтобы усилить модель по классам pizza / sushi / burger, можно добавить данные из **Food-101** (101 класс, из них берём только pizza, sushi, hamburger→burger):

1. Перейди в **`datasets`** (из корня репо: `cd Доклад/datasets`; из Доклад: `cd datasets`).
2. Создай venv и установи зависимости, затем запусти скрипт:
   ```bash
   python3 -m venv .venv_food && source .venv_food/bin/activate
   pip install datasets pillow
   HF_HOME=.hf_cache python3 download_food101_pizza_sushi_burger.py
   ```
3. Скрипт скачает Food-101 с Hugging Face и **добавит** в **TrainingData** и **ValidationData** по 750 train и 250 validation изображений на каждый класс (pizza, sushi, burger). Итого +2250 train, +750 validation.
4. Заново обучи **FoodClassifier** в Create ML на обновлённых папках **TrainingData** и **ValidationData**.

Скрипт: **`Доклад/datasets/download_food101_pizza_sushi_burger.py`**.

---

## Как собрать CalorieClassificationData

Данные для калорий готовятся из **Nutrition5k** (таблица + картинки в `datasets/калории/`).

1. Положи в **`datasets/калории/`** файлы **dishes.xlsx** и **dish_images.pkl** (скачать Nutrition5k).
2. В терминале перейди в **`datasets/калории`** (из корня репо: `cd Доклад/datasets/калории`; из Доклад: `cd datasets/калории`). Выполни:
   ```bash
   pip install pandas openpyxl Pillow
   python3 prepare_calorie_regression_data.py
   python3 build_calorie_classification_folders.py
   ```
3. Появится папка **`datasets/CalorieClassificationData`** с подпапками cal_100, cal_200, …, cal_1100 (шаг 100 ккал, сбалансированные классы). Её указываешь в Create ML для CalorieClassifier.

**Добавить данные с Hugging Face (дообучение):**  
Перейди в папку со скриптами (из **корня репо** — `cd Доклад/datasets/калории`, если уже в **Доклад** — `cd datasets/калории`), затем:
```bash
python3 -m venv .venv && source .venv/bin/activate
pip install datasets pillow
python3 download_extra_calorie_data.py
python3 build_calorie_classification_folders.py
```
Скрипты лежат в `Доклад/datasets/калории/`. Скрипт скачивает датасет, дописывает файлы в CalorieRegressionData5k и пересобирает CalorieClassificationData. Потом заново обучи CalorieClassifier в Create ML на обновлённой папке.

---

## Структура проекта

```
LunchClassifier/
├── LunchClassifier.xcodeproj
├── LunchClassifier/          ← исходники
│   ├── LunchClassifierApp.swift
│   ├── ContentView.swift
│   ├── ImageClassifier.swift
│   ├── CalorieRegressor.swift
│   ├── FoodClassifier.mlmodel    ← добавить после обучения
│   ├── CalorieClassifier.mlmodel ← добавить после обучения
│   └── ...
├── README.md                 ← этот файл
└── PRESENTATION.md           ← текст для доклада
```

---

Презентация на 5–7 мин: **PRESENTATION.md**.
