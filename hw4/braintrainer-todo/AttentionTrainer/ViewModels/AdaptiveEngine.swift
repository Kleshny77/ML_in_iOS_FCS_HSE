import Foundation
import Combine

private struct AdaptiveThresholds {
    static let upgradeAccuracy: Double = 0.85
    static let upgradePerformance: Double = 80.0
    static let downgradeAccuracy: Double = 0.50
    static let downgradePerformance: Double = 45.0
    static let minGamesForAnalysis = 2
    static let minGamesAtLevelForUpgrade = 3
    static let trendDeltaPoints: Double = 10.0
}

class AdaptiveEngine: ObservableObject {

    @Published var currentRecommendation: DifficultyRecommendation = .maintain
    @Published var analysisResult: AnalysisResult?

    func analyze(
        exercise: ExerciseType,
        recentResults: [GameResult],
        currentLevel: DifficultyLevel? = nil
    ) -> DifficultyRecommendation {
        guard !recentResults.isEmpty else {
            currentRecommendation = .maintain
            analysisResult = nil
            return .maintain
        }

        let level = currentLevel ?? recentResults.last?.difficulty ?? .level1
        let sessionsAtLevel = recentResults.filter { $0.difficulty == level }.count

        let avgAccuracy = recentResults.map(\.accuracy).reduce(0, +) / Double(recentResults.count)
        let avgPerformance = recentResults.map(\.performanceScore).reduce(0, +) / Double(recentResults.count)
        let avgReactionTime = recentResults.map(\.averageReactionTime).reduce(0, +) / Double(recentResults.count)
        let trend = calculateTrend(recentResults)

        analysisResult = AnalysisResult(
            averageAccuracy: avgAccuracy,
            averagePerformance: avgPerformance,
            averageReactionTime: avgReactionTime,
            trend: trend,
            sessionsAnalyzed: recentResults.count
        )

        let recommendation: DifficultyRecommendation
        if shouldDowngrade(accuracy: avgAccuracy, performance: avgPerformance) {

            recommendation = .downgrade(level)
        } else if recentResults.count >= AdaptiveThresholds.minGamesForAnalysis,
                  shouldUpgrade(
                      accuracy: avgAccuracy,
                      performance: avgPerformance,
                      sessions: sessionsAtLevel,
                      trend: trend
                  ) {
            recommendation = .upgrade(level)
        } else {
            recommendation = .maintain
        }

        currentRecommendation = recommendation
        return recommendation
    }

    private func calculateTrend(_ results: [GameResult]) -> PerformanceTrend {
        guard results.count >= 3 else { return .stable }

        let midpoint = results.count / 2
        let firstHalf = results.prefix(midpoint).map(\.performanceScore)
        let secondHalf = results.suffix(results.count - midpoint).map(\.performanceScore)

        guard !firstHalf.isEmpty, !secondHalf.isEmpty else { return .stable }

        let firstAvg = firstHalf.reduce(0, +) / Double(firstHalf.count)
        let secondAvg = secondHalf.reduce(0, +) / Double(secondHalf.count)
        let difference = secondAvg - firstAvg

        if difference > AdaptiveThresholds.trendDeltaPoints {
            return .improving
        }
        if difference < -AdaptiveThresholds.trendDeltaPoints {
            return .declining
        }
        return .stable
    }

    private func shouldUpgrade(
        accuracy: Double,
        performance: Double,
        sessions: Int,
        trend: PerformanceTrend
    ) -> Bool {
        let enoughSessions = sessions >= AdaptiveThresholds.minGamesAtLevelForUpgrade
        let highMetrics = accuracy >= AdaptiveThresholds.upgradeAccuracy
            || performance >= AdaptiveThresholds.upgradePerformance
        let goodTrend = trend == .improving || trend == .stable
        return enoughSessions && highMetrics && goodTrend
    }

    private func shouldDowngrade(accuracy: Double, performance: Double) -> Bool {
        accuracy < AdaptiveThresholds.downgradeAccuracy
            || performance < AdaptiveThresholds.downgradePerformance
    }

    func nextDifficulty(
        for exercise: ExerciseType,
        current: DifficultyLevel,
        in stats: UserStats
    ) -> DifficultyLevel {
        let recentResults = Array(stats.results(for: exercise, last: 5))
        let recommendation = analyze(
            exercise: exercise,
            recentResults: recentResults,
            currentLevel: current
        )
        return applyRecommendation(recommendation, to: current)
    }

    private func applyRecommendation(
        _ recommendation: DifficultyRecommendation,
        to current: DifficultyLevel
    ) -> DifficultyLevel {
        switch recommendation {
        case .upgrade:
            let nextRaw = min(current.rawValue + 1, DifficultyLevel.max)
            return DifficultyLevel(rawValue: nextRaw) ?? current
        case .downgrade:
            let nextRaw = max(current.rawValue - 1, DifficultyLevel.min)
            return DifficultyLevel(rawValue: nextRaw) ?? current
        case .maintain:
            return current
        }
    }
}

enum DifficultyRecommendation: Equatable {
    case upgrade(DifficultyLevel)
    case downgrade(DifficultyLevel)
    case maintain

    var description: String {
        switch self {
        case .upgrade:
            return "Рекомендуется повысить сложность"
        case .downgrade:
            return "Рекомендуется понизить сложность"
        case .maintain:
            return "Текущий уровень оптимален"
        }
    }

    var color: String {
        switch self {
        case .upgrade: return "green"
        case .downgrade: return "orange"
        case .maintain: return "blue"
        }
    }
}

enum PerformanceTrend {
    case improving
    case stable
    case declining

    var icon: String {
        switch self {
        case .improving: return "arrow.up.forward"
        case .stable: return "arrow.right"
        case .declining: return "arrow.down.forward"
        }
    }

    var title: String {
        switch self {
        case .improving: return "Улучшается"
        case .stable: return "Стабильно"
        case .declining: return "Снижается"
        }
    }
}

struct AnalysisResult {
    let averageAccuracy: Double
    let averagePerformance: Double
    let averageReactionTime: TimeInterval
    let trend: PerformanceTrend
    let sessionsAnalyzed: Int

    var formattedAccuracy: String {
        String(format: "%.1f%%", averageAccuracy * 100)
    }

    var formattedPerformance: String {
        String(format: "%.1f", averagePerformance)
    }

    var formattedReactionTime: String {
        String(format: "%.2f с", averageReactionTime)
    }
}
