import Foundation

struct GameResult: Identifiable, Codable {

    let id: UUID

    let exerciseType: String

    let difficultyRaw: Int

    var difficulty: DifficultyLevel {
        DifficultyLevel(rawValue: difficultyRaw) ?? .level1
    }

    let date: Date

    let totalTime: Double

    let correctAnswers: Int

    let incorrectAnswers: Int

    let averageReactionTime: Double

    let accuracy: Double

    let performanceScore: Double

    init(from session: ExerciseSession) {
        self.id = session.id
        self.exerciseType = session.exerciseType.rawValue
        self.difficultyRaw = session.difficulty.rawValue
        self.date = session.startTime

        if let metrics = session.metrics {
            self.totalTime = metrics.totalTime
            self.correctAnswers = metrics.correctAnswers
            self.incorrectAnswers = metrics.incorrectAnswers
            self.averageReactionTime = metrics.averageReactionTime
            self.accuracy = metrics.accuracy
            self.performanceScore = metrics.performanceScore
        } else {

            self.totalTime = 0
            self.correctAnswers = 0
            self.incorrectAnswers = 0
            self.averageReactionTime = 0
            self.accuracy = 0
            self.performanceScore = 0
        }
    }

    var totalAttempts: Int {
        correctAnswers + incorrectAnswers
    }

    var resultCategory: ResultCategory {
        if accuracy < 0.5 || performanceScore < 40 {
            return .poor
        } else if accuracy >= 0.8 && performanceScore >= 75 {
            return .excellent
        } else if accuracy >= 0.65 && performanceScore >= 55 {
            return .good
        } else {
            return .average
        }
    }
}

enum ResultCategory: String {

    case poor = "Требует улучшения"

    case average = "Средний"

    case good = "Хороший"

    case excellent = "Отличный"

    var color: String {
        switch self {
        case .poor: return "red"
        case .average: return "yellow"
        case .good: return "blue"
        case .excellent: return "green"
        }
    }
}
