import Foundation
import SwiftUI
import Combine

class SchulteViewModel: ObservableObject {
    @Published var gridSize: Int = 5
    @Published var numbers: [Int] = []
    @Published var currentTarget: Int = 1
    @Published var selectedIndices: Set<Int> = []
    @Published var isGameActive = false
    @Published var elapsedTime: TimeInterval = 0
    @Published var wrongAttempts = 0
    @Published var isGameCompleted = false
    @Published var isReverseMode: Bool = false

    private var startTime: Date?
    private var timer: AnyCancellable?
    private var reactionTimes: [TimeInterval] = []
    private var lastSelectionTime: Date?
    private var currentLevel: DifficultyLevel = .level1

    var config: DifficultyConfig {
        DifficultyConfig(level: currentLevel)
    }

    func setup(difficulty: DifficultyLevel) {
        currentLevel = difficulty
        let config = DifficultyConfig(level: difficulty)
        gridSize = config.schulteGridSize

        isReverseMode = false
        resetGame()
    }

    func startGame() {
        generateGrid()
        isGameActive = true
        isGameCompleted = false

        currentTarget = isReverseMode ? numbers.count : 1
        startTime = Date()
        lastSelectionTime = startTime

        timer = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self, let start = self.startTime else { return }
                self.elapsedTime = Date().timeIntervalSince(start)
            }
    }

    func selectNumber(at index: Int) {
        guard isGameActive, !selectedIndices.contains(index) else { return }

        let selectedNumber = numbers[index]

        let now = Date()
        if let last = lastSelectionTime {
            reactionTimes.append(now.timeIntervalSince(last))
        }
        lastSelectionTime = now

        if selectedNumber == currentTarget {
            selectedIndices.insert(index)

            if isReverseMode {
                currentTarget -= 1

                if currentTarget < 1 {
                    completeGame()
                }
            } else {
                currentTarget += 1

                if currentTarget > numbers.count {
                    completeGame()
                }
            }
        } else {
            wrongAttempts += 1

            #if os(iOS)
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
            #endif
        }
    }

    private func completeGame() {
        timer?.cancel()
        isGameActive = false
        isGameCompleted = true
    }

    func resetGame() {
        timer?.cancel()
        isGameActive = false
        isGameCompleted = false
        selectedIndices.removeAll()

        currentTarget = isReverseMode ? (gridSize * gridSize) : 1
        elapsedTime = 0
        wrongAttempts = 0
        reactionTimes = []
        numbers = []
    }

    private func generateGrid() {
        let totalCells = gridSize * gridSize
        numbers = Array(1...totalCells).shuffled()
    }

    func getSessionMetrics() -> SessionMetrics? {
        guard isGameCompleted, let start = startTime else { return nil }

        let totalTime = Date().timeIntervalSince(start)
        let correct = numbers.count - 1
        let totalAttempts = correct + wrongAttempts
        let accuracy = totalAttempts > 0 ? Double(correct) / Double(totalAttempts) : 0
        let avgReaction = reactionTimes.isEmpty ? 0 : reactionTimes.reduce(0, +) / Double(reactionTimes.count)

        return SessionMetrics(
            totalTime: totalTime,
            correctAnswers: correct,
            incorrectAnswers: wrongAttempts,
            averageReactionTime: avgReaction,
            accuracy: accuracy
        )
    }
}
