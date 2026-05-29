import Foundation
import SwiftUI
import Combine

final class UserStats: ObservableObject {

    @Published var currentDifficulty: [ExerciseType: DifficultyLevel] = [:]

    @Published var history: [GameResult] = []

    @Published var streak: Int = 0

    @Published var lastTrainingDate: Date?

    private let storage = StatsStorage()

    init() {
        loadData()
    }

    func recommendedDifficulty(for exercise: ExerciseType) -> DifficultyLevel {
        currentDifficulty[exercise] ?? .level1
    }

    func updateDifficulty(for exercise: ExerciseType, to level: DifficultyLevel) {
        currentDifficulty[exercise] = level
        saveData()
        objectWillChange.send()
    }

    func addResult(_ result: GameResult) {
        history.append(result)
        updateStreak()
        saveData()
        objectWillChange.send()
    }

    func results(for exercise: ExerciseType, last count: Int = 5) -> [GameResult] {
        history
            .filter { $0.exerciseType == exercise.rawValue }
            .suffix(count)
    }

    func averagePerformance(for exercise: ExerciseType) -> Double {
        let recent = results(for: exercise, last: 5)
        guard !recent.isEmpty else { return 0 }
        return recent.map { $0.performanceScore }.reduce(0, +) / Double(recent.count)
    }

    func totalTrainingTime() -> TimeInterval {
        history.map { $0.totalTime }.reduce(0, +)
    }

    private func updateStreak() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if let last = lastTrainingDate {
            let lastDay = calendar.startOfDay(for: last)
            let daysSince = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0

            if daysSince == 0 {

                return
            } else if daysSince == 1 {

                streak += 1
            } else {

                streak = 1
            }
        } else {

            streak = 1
        }

        lastTrainingDate = Date()
    }

    private func saveData() {
        storage.saveDifficulty(currentDifficulty)
        storage.saveHistory(history)
        storage.saveStreak(streak)
        storage.saveLastDate(lastTrainingDate)
    }

    private func loadData() {
        currentDifficulty = storage.loadDifficulty()
        history = storage.loadHistory()
        streak = storage.loadStreak()
        lastTrainingDate = storage.loadLastDate()
    }
}

extension UserStats {

    func skillProgress(_ skill: String) -> Double {

        let relevantExercises = ExerciseType.allCases.filter { $0.targetSkills.contains(skill) }

        let scores = relevantExercises.map { averagePerformance(for: $0) }

        guard !scores.isEmpty else { return 0 }

        return min(100, scores.reduce(0, +) / Double(scores.count))
    }

    var allSkills: [(name: String, progress: Double)] {
        let skills = [
            "Периферийное зрение",
            "Рабочая память",
            "Концентрация",
            "Кратковременная память",
            "Скорость восприятия",
            "Визуальная обработка"
        ]
        return skills.map { ($0, skillProgress($0)) }
    }
}
