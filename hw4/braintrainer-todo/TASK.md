# Задание: Реализация системы адаптивной сложности

## Цель
Реализовать интеллектуальную систему выбора уровня сложности на основе результатов пользователя.

## Текущее состояние
В проекте есть заглушка `AdaptiveEngine`, которая всегда возвращает `.maintain` (оставить текущий уровень).

## Что нужно сделать

### 1. Анализ метрик (AdaptiveEngine.swift)

Реализовать метод `analyze()` который будет:
- Получать историю последних игр (параметр `recentResults`)
- Вычислять среднюю точность (`accuracy`)
- Вычислять средний счёт (`performanceScore`)
- Определять тренд (улучшается/ухудшается/стабильно)

**Формулы для реализации:**
```swift
// Средняя точность
let avgAccuracy = сумма всех accuracy / количество игр

// Средний performance
let avgPerformance = сумма всех performanceScore / количество игр

// Тренд (сравнение первой и второй половины)
let firstHalf = первые 50% результатов
let secondHalf = последние 50% результатов
if secondHalf > firstHalf + 10% → .improving
if secondHalf < firstHalf - 10% → .declining
else → .stable
```

### 2. Принятие решения о сложности

Реализовать логику выбора уровня:

**Повышение сложности (.upgrade):**
- Средняя точность >= 85% ИЛИ performance >= 80
- Игр на текущем уровне >= 3
- Тренд = improving или stable

**Понижение сложности (.downgrade):**
- Средняя точность < 50% ИЛИ performance < 45

**Сохранение (.maintain):**
- Все остальные случаи

### 3. Алгоритм выбора следующего уровня

```swift
func nextDifficulty(current: DifficultyLevel, recommendation: DifficultyRecommendation) -> DifficultyLevel {
    switch recommendation {
    case .upgrade:
        return min(current.rawValue + 1, DifficultyLevel.max)
    case .downgrade:
        return max(current.rawValue - 1, DifficultyLevel.min)
    case .maintain:
        return current
    }
}
```

## Подсказки

1. **Типы данных:**
   - `GameResult` содержит: accuracy, performanceScore, date, difficulty
   - `DifficultyRecommendation` имеет 3 случая: .upgrade, .downgrade, .maintain

2. **Граничные условия:**
   - Не повышать выше уровня 8
   - Не понижать ниже уровня 1
   - При мало данных (< 2 игр) всегда возвращать .maintain

3. **Пороговые значения (Thresholds):**
   - Можно вынести в отдельную структуру для удобства настройки
   - upgradeAccuracy: 0.85
   - upgradePerformance: 80.0
   - downgradeAccuracy: 0.50
   - downgradePerformance: 45.0

## Проверка

После реализации:
1. Если игрок 3 раза подряд играет с точностью >85% → уровень повышается
2. Если игрок играет с точностью <50% → уровень понижается
3. При средних результатах уровень не меняется

## Дополнительно (опционально)

- Добавить учёт времени реакции
- Реализовать разные пороги для разных игр
- Добавить взвешенное среднее (новые игры важнее старых)
