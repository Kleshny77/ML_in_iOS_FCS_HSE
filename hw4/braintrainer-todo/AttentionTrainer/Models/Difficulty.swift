import Foundation

enum DifficultyLevel: Int, CaseIterable, Identifiable {

    case level1 = 1
    case level2 = 2
    case level3 = 3
    case level4 = 4
    case level5 = 5
    case level6 = 6
    case level7 = 7
    case level8 = 8

    var id: Int { rawValue }

    var title: String {
        return "Уровень \(rawValue)"
    }

    var shortTitle: String {
        return "\(rawValue)"
    }

    var icon: String {
        switch rawValue {
        case 1...3: return "star"
        case 4...6: return "star.fill"
        case 7...8: return "flame.fill"
        default: return "star"
        }
    }

    var color: String {
        switch rawValue {
        case 1...3: return "green"
        case 4...6: return "orange"
        case 7...8: return "red"
        default: return "green"
        }
    }

    static var min: Int { 1 }

    static var max: Int { 8 }
}

struct DifficultyConfig {

    let level: DifficultyLevel

    var schulteGridSize: Int {

        return min(10, 3 + level.rawValue - 1)
    }

    var nBackN: Int {
        switch level.rawValue {
        case 1...3: return 1
        case 4...6: return 2
        case 7...8: return 3
        default: return 1
        }
    }

    var nBackInterval: Double {
        return max(0.9, 2.5 - Double(level.rawValue - 1) * 0.23)
    }

    var nBackIterations: Int {
        return 10 + level.rawValue * 2
    }

    var numbersColumnSize: Int {
        return 4 + level.rawValue
    }

    var numbersMatchingPairs: Int {
        return 2 + level.rawValue / 2
    }

    var numbersShowHints: Bool {
        return level.rawValue <= 4
    }

    var colorsColumnSize: Int {
        return 4 + level.rawValue
    }

    var colorsMatchingPairs: Int {
        return 2 + level.rawValue / 2
    }

    @available(*, deprecated, message: "Используйте numbersColumnSize или colorsColumnSize")
    var columnSize: Int {
        return 4 + level.rawValue
    }

    @available(*, deprecated, message: "Используйте numbersShowHints")
    var showCenterNumbers: Bool {
        return level.rawValue <= 4
    }

    @available(*, deprecated)
    var matchingPairsCount: Int {
        return 2 + (level.rawValue - 1) / 2
    }
}
