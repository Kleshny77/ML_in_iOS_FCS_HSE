import Foundation

class StatsStorage {
    private let defaults = UserDefaults.standard

    private enum Keys {
        static let difficulty = "user_difficulty"
        static let history = "game_history"
        static let streak = "training_streak"
        static let lastDate = "last_training_date"
    }

    func saveDifficulty(_ difficulty: [ExerciseType: DifficultyLevel]) {
        let dict = difficulty.reduce(into: [String: Int]()) { result, pair in
            result[pair.key.rawValue] = pair.value.rawValue
        }
        defaults.set(dict, forKey: Keys.difficulty)
    }

    func loadDifficulty() -> [ExerciseType: DifficultyLevel] {
        guard let dict = defaults.dictionary(forKey: Keys.difficulty) as? [String: Int]
        else { return [:] }

        var result: [ExerciseType: DifficultyLevel] = [:]
        for (key, value) in dict {
            if let type = ExerciseType(rawValue: key),
               let level = DifficultyLevel(rawValue: value) {
                result[type] = level
            }
        }
        return result
    }

    func saveHistory(_ history: [GameResult]) {
        if let encoded = try? JSONEncoder().encode(history) {
            defaults.set(encoded, forKey: Keys.history)
        }
    }

    func loadHistory() -> [GameResult] {
        guard let data = defaults.data(forKey: Keys.history),
              let decoded = try? JSONDecoder().decode([GameResult].self, from: data)
        else { return [] }
        return decoded
    }

    func saveStreak(_ streak: Int) {
        defaults.set(streak, forKey: Keys.streak)
    }

    func loadStreak() -> Int {
        defaults.integer(forKey: Keys.streak)
    }

    func saveLastDate(_ date: Date?) {
        if let date = date {
            defaults.set(date.timeIntervalSince1970, forKey: Keys.lastDate)
        } else {
            defaults.removeObject(forKey: Keys.lastDate)
        }
    }

    func loadLastDate() -> Date? {
        let interval = defaults.double(forKey: Keys.lastDate)
        return interval > 0 ? Date(timeIntervalSince1970: interval) : nil
    }

    func clearAll() {
        defaults.removeObject(forKey: Keys.difficulty)
        defaults.removeObject(forKey: Keys.history)
        defaults.removeObject(forKey: Keys.streak)
        defaults.removeObject(forKey: Keys.lastDate)
    }
}
