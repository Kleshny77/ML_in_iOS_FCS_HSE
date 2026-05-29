import Foundation
import SwiftUI
import Combine

class NBackViewModel: ObservableObject {
    @Published var currentStimulus: String = ""
    @Published var stimulusHistory: [String] = []
    @Published var isGameActive = false
    @Published var currentIteration = 0
    @Published var correctAnswers = 0
    @Published var wrongAnswers = 0
    @Published var missedAnswers = 0
    @Published var isGameCompleted = false

    var n: Int = 2
    var interval: Double = 2.0
    var totalIterations: Int = 15

    private var timer: AnyCancellable?
    private var stimuli: [String] = []
    private var expectedMatches: Set<Int> = []
    private var userResponses: Set<Int> = []
    private var startTime: Date?
    private var reactionTimes: [TimeInterval] = []
    private var stimulusStartTime: Date?

    private let letters = Array("ABCDEFGHJKLMNPQRSTUVWXYZ")

    func setup(difficulty: DifficultyLevel) {
        let config = DifficultyConfig(level: difficulty)
        n = config.nBackN
        interval = config.nBackInterval
        totalIterations = config.nBackIterations
    }

    func startGame() {
        generateStimuli()
        isGameActive = true
        isGameCompleted = false
        currentIteration = 0
        correctAnswers = 0
        wrongAnswers = 0
        missedAnswers = 0
        userResponses.removeAll()
        reactionTimes = []
        startTime = Date()

        showNextStimulus()
    }

    func userResponded() {
        guard isGameActive, currentIteration > 0 else { return }

        let responseTime = Date()
        if let stimulusStart = stimulusStartTime {
            reactionTimes.append(responseTime.timeIntervalSince(stimulusStart))
        }

        let isMatch = expectedMatches.contains(currentIteration - 1)

        if isMatch && !userResponses.contains(currentIteration - 1) {
            correctAnswers += 1
            userResponses.insert(currentIteration - 1)
            #if os(iOS)
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            #endif
        } else if !isMatch {
            wrongAnswers += 1
            #if os(iOS)
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
            #endif
        }
    }

    private func showNextStimulus() {
        guard currentIteration < totalIterations else {
            completeGame()
            return
        }

        currentStimulus = stimuli[currentIteration]
        stimulusHistory.append(currentStimulus)
        stimulusStartTime = Date()
        currentIteration += 1

        timer = Just(())
            .delay(for: .seconds(interval), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.checkMissedResponse()
                self?.showNextStimulus()
            }
    }

    private func checkMissedResponse() {

        let previousIndex = currentIteration - 2
        if previousIndex >= 0 {
            let wasMatch = expectedMatches.contains(previousIndex)
            let userResponded = userResponses.contains(previousIndex)

            if wasMatch && !userResponded {
                missedAnswers += 1
            }
        }
    }

    private func completeGame() {
        timer?.cancel()
        isGameActive = false
        isGameCompleted = true
        checkMissedResponse()
    }

    func resetGame() {
        timer?.cancel()
        isGameActive = false
        isGameCompleted = false
        currentStimulus = ""
        stimulusHistory.removeAll()
        currentIteration = 0
        correctAnswers = 0
        wrongAnswers = 0
        missedAnswers = 0
        userResponses.removeAll()
    }

    private func generateStimuli() {
        stimuli = []
        expectedMatches.removeAll()

        for i in 0..<totalIterations {
            if i >= n && Double.random(in: 0...1) < 0.3 {

                stimuli.append(stimuli[i - n])
                expectedMatches.insert(i)
            } else {

                stimuli.append(String(letters.randomElement()!))
            }
        }
    }

    func getSessionMetrics() -> SessionMetrics? {
        guard isGameCompleted, let start = startTime else { return nil }

        let totalTime = Date().timeIntervalSince(start)
        let totalCorrect = correctAnswers
        let totalWrong = wrongAnswers + missedAnswers
        let totalAttempts = totalCorrect + totalWrong
        let accuracy = totalAttempts > 0 ? Double(totalCorrect) / Double(totalAttempts) : 0
        let avgReaction = reactionTimes.isEmpty ? 0 : reactionTimes.reduce(0, +) / Double(reactionTimes.count)

        return SessionMetrics(
            totalTime: totalTime,
            correctAnswers: totalCorrect,
            incorrectAnswers: totalWrong,
            averageReactionTime: avgReaction,
            accuracy: accuracy
        )
    }
}
