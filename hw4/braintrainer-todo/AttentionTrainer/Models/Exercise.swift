import Foundation

enum ExerciseType: String, CaseIterable, Identifiable {

    case schulte = "schulte"

    case nback = "nback"

    case numbers = "numbers"

    case colors = "colors"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .schulte: return "Таблица Шульте"
        case .nback: return "N-Back"
        case .numbers: return "Поиск чисел"
        case .colors: return "Поиск цветов"
        }
    }

    var description: String {
        switch self {
        case .schulte:
            return "Развитие периферийного зрения и скорости восприятия"
        case .nback:
            return "Тренировка рабочей памяти и концентрации"
        case .numbers:
            return "Поиск повторяющихся чисел с помощью периферийного зрения"
        case .colors:
            return "Поиск совпадающих цветов"
        }
    }

    var icon: String {
        switch self {
        case .schulte: return "grid"
        case .nback: return "brain"
        case .numbers: return "number"
        case .colors: return "paintpalette"
        }
    }

    var targetSkills: [String] {
        switch self {
        case .schulte:
            return ["Периферийное зрение", "Скорость восприятия"]
        case .nback:
            return ["Рабочая память", "Концентрация"]
        case .numbers:
            return ["Периферийное зрение", "Кратковременная память"]
        case .colors:
            return ["Периферийное зрение", "Визуальная обработка"]
        }
    }

    var detailedInstructions: String {
        switch self {
        case .schulte:
            return """
            **Правила игры**

            Найдите числа от 1 до максимального по порядку как можно быстрее.

            **Как играть:**
            • Нажимайте на числа в порядке возрастания (1, 2, 3...)
            • Используйте периферийное зрение — не задерживайте взгляд на одной цифре
            • Старайтесь видеть всё поле одновременно
            • Ошибки учитываются — старайтесь быть внимательным

            **Уровни сложности:**
            • Лёгкий: поле 5×5
            • Средний: поле 7×7
            • Сложный: поле 9×9

            **Совет:** Не водите глазами по каждой цифре. Расслабьте взгляд и «ловите» нужные числа боковым зрением.
            """
        case .nback:
            return """
            **Правила игры**

            Тренировка рабочей памяти. Нажимайте «Совпадение!», когда текущая буква совпадает с той, что была N шагов назад.

            **Как играть:**
            • Буквы появляются последовательно
            • Сравните текущую букву с буквой N шагов назад
            • При совпадении нажмите кнопку «Совпадение!»
            • Реагируйте быстро — у вас ограниченное время

            **Пример (2-back):**
            Последовательность: A → B → **C** → B → **C**
            Когда появится второе C (через 2 шага после первого) — это совпадение!

            **Уровни сложности:**
            • Лёгкий: 1-back (сравнение с предыдущей)
            • Средний: 2-back
            • Сложный: 3-back
            """
        case .numbers:
            return """
            **Правила игры**

            Найдите числа из центральной панели в левой и правой колонках.

            **Как играть:**
            • В центре показаны числа, которые нужно найти
            • Ищите эти числа в левой и правой колонках
            • Нажмите на число слева, затем на такое же справа
            • Найденная пара исчезает из центра

            **Важно:**
            • Сначала нажмите число в одной колонке
            • Затем нажмите такое же число в другой колонке
            • Ошибки штрафуются — выбирайте внимательно

            **Уровни сложности:**
            • Лёгкий: мало чисел, простые комбинации
            • Средний: больше чисел
            • Сложный: много чисел, сложные комбинации

            **Совет:** Используйте периферийное зрение. Не смотрите по очереди на каждое число — старайтесь видеть обе колонки сразу.
            """
        case .colors:
            return """
            **Правила игры**

            Найдите цвета, которые есть в обеих колонках — левой и правой.

            **Как играть:**
            • Сравните цвета в левой и правой колонках
            • Найдите цвета, которые присутствуют в обеих колонках
            • Нажмите на совпадающий цвет в любой колонке
            • Найдите все пары цветов

            **Важно:**
            • Цвет должен присутствовать и слева, и справа
            • Каждая пара засчитывается один раз
            • Ошибки штрафуются

            **Уровни сложности:**
            • Лёгкий: мало цветов, яркие оттенки
            • Средний: больше цветов, похожие оттенки
            • Сложный: много цветов, сложные оттенки

            **Совет:** Не фокусируйтесь на одной колонке. Расслабьте взгляд и сравнивайте цвета обеих колонок одновременно.
            """
        }
    }
}

struct ExerciseSession: Identifiable {

    let id = UUID()

    let exerciseType: ExerciseType

    let difficulty: DifficultyLevel

    let startTime: Date

    var endTime: Date?

    var metrics: SessionMetrics?

    var duration: TimeInterval? {
        guard let end = endTime else { return nil }
        return end.timeIntervalSince(startTime)
    }
}

struct SessionMetrics {

    let totalTime: TimeInterval

    let correctAnswers: Int

    let incorrectAnswers: Int

    let averageReactionTime: TimeInterval

    let accuracy: Double

    var totalAttempts: Int {
        correctAnswers + incorrectAnswers
    }

    var performanceScore: Double {
        let speedScore = min(1.0, 30.0 / totalTime)
        return (accuracy * 0.7 + speedScore * 0.3) * 100
    }
}
