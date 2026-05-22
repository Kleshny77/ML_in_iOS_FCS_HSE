# LunchClassifier

Фото еды → тип блюда (pizza / sushi / burger) и калории на порцию.

## Запуск

1. Открой `LunchClassifier.xcodeproj` в Xcode.
2. В проекте должны быть `FoodClassifier.mlmodel` и `CalorieClassifier.mlmodel` (калории уже в репозитории).
3. Run на симуляторе или iPhone → «Выбрать фото».

Калории показываются только если блюдо распознано с уверенностью ≥ 80%.

## Модели

| Файл | Назначение |
|------|------------|
| `FoodClassifier.mlmodel` | Класс блюда |
| `CalorieClassifier.mlmodel` | Диапазон калорий (`cal_500` → 500 ккал) |

Переобучение: Create ML, Image Classification. Скрипты подготовки данных — `../datasets/калории/`.

## Презентация

`../классификатор обеда.pdf`
