# Данные для LunchClassifier

| Папка | Назначение |
|-------|------------|
| **TrainingData** | Обучение FoodClassifier (pizza, sushi, burger). В Create ML — Training Data. |
| **ValidationData** | Валидация FoodClassifier. В Create ML — Validation Data. |
| **CalorieClassificationData** | Обучение CalorieClassifier (cal_100, cal_200, …, cal_1100 — шаг 100 ккал). В Create ML — Training Data. Собирается скриптами из папки `калории/`. |

Как собрать CalorieClassificationData и как обучать модели — **LunchClassifier/README.md**.  
Добавить данные из Food-101 (pizza, sushi, burger): скрипт **`download_food101_pizza_sushi_burger.py`** в этой папке — см. LunchClassifier/README.md, раздел «Добавить больше данных для FoodClassifier».
