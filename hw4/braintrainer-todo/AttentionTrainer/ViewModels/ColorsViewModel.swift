import Foundation
import SwiftUI
import Combine

class ColorsViewModel: ObservableObject {
    @Published var leftColors: [ColorOption] = []
    @Published var rightColors: [ColorOption] = []
    @Published var isGameActive = false
    @Published var isGameCompleted = false
    @Published var foundPairs: Set<String> = []
    @Published var elapsedTime: TimeInterval = 0
    @Published var wrongAttempts = 0

    private var columnSize: Int = 5
    private var currentLevel: DifficultyLevel = .level1
    private var startTime: Date?
    private var timer: Timer?
    private var reactionTimes: [TimeInterval] = []
    private var lastSelectionTime: Date?

    private let baseColors: [ColorOption] = [
        ColorOption(name: "red", color: .red),
        ColorOption(name: "blue", color: .blue),
        ColorOption(name: "green", color: .green),
        ColorOption(name: "yellow", color: .yellow),
        ColorOption(name: "purple", color: .purple),
        ColorOption(name: "orange", color: .orange),
        ColorOption(name: "pink", color: .pink),
        ColorOption(name: "cyan", color: .cyan),
        ColorOption(name: "mint", color: .mint),
        ColorOption(name: "indigo", color: .indigo),
        ColorOption(name: "teal", color: .teal),
        ColorOption(name: "brown", color: .brown)
    ]

    private let mediumColors: [ColorOption] = [
        ColorOption(name: "lime", color: Color(red: 0.6, green: 0.9, blue: 0.2)),
        ColorOption(name: "navy", color: Color(red: 0, green: 0.2, blue: 0.6)),
        ColorOption(name: "olive", color: Color(red: 0.5, green: 0.6, blue: 0.2)),
        ColorOption(name: "maroon", color: Color(red: 0.6, green: 0.1, blue: 0.2)),
        ColorOption(name: "coral", color: Color(red: 1.0, green: 0.5, blue: 0.4)),
        ColorOption(name: "gold", color: Color(red: 1.0, green: 0.8, blue: 0)),
        ColorOption(name: "salmon", color: Color(red: 1.0, green: 0.6, blue: 0.5)),
        ColorOption(name: "turquoise", color: Color(red: 0.3, green: 0.9, blue: 0.8)),
        ColorOption(name: "violet", color: Color(red: 0.6, green: 0.3, blue: 0.9)),
        ColorOption(name: "beige", color: Color(red: 0.9, green: 0.8, blue: 0.6))
    ]

    private let hardColors: [ColorOption] = [

        ColorOption(name: "crimson", color: Color(red: 0.9, green: 0.1, blue: 0.2)),
        ColorOption(name: "scarlet", color: Color(red: 1.0, green: 0.15, blue: 0.0)),
        ColorOption(name: "ruby", color: Color(red: 0.9, green: 0.05, blue: 0.15)),

        ColorOption(name: "azure", color: Color(red: 0.0, green: 0.5, blue: 1.0)),
        ColorOption(name: "sapphire", color: Color(red: 0.1, green: 0.3, blue: 0.8)),
        ColorOption(name: "cerulean", color: Color(red: 0.0, green: 0.6, blue: 0.9)),

        ColorOption(name: "emerald", color: Color(red: 0.1, green: 0.8, blue: 0.4)),
        ColorOption(name: "jade", color: Color(red: 0.0, green: 0.7, blue: 0.4)),
        ColorOption(name: "forest", color: Color(red: 0.1, green: 0.5, blue: 0.2)),

        ColorOption(name: "amber", color: Color(red: 1.0, green: 0.75, blue: 0.0)),
        ColorOption(name: "peach", color: Color(red: 1.0, green: 0.7, blue: 0.5)),
        ColorOption(name: "apricot", color: Color(red: 1.0, green: 0.65, blue: 0.4)),

        ColorOption(name: "magenta", color: Color(red: 0.9, green: 0.2, blue: 0.8)),
        ColorOption(name: "lavender", color: Color(red: 0.8, green: 0.6, blue: 0.9)),
        ColorOption(name: "plum", color: Color(red: 0.7, green: 0.4, blue: 0.7))
    ]

    var availableColors: [ColorOption] {
        switch currentLevel.rawValue {
        case 1...3:
            return baseColors
        case 4...6:
            return baseColors + mediumColors
        case 7...8:
            return baseColors + mediumColors + hardColors
        default:
            return baseColors
        }
    }

    func setup(difficulty: DifficultyLevel) {
        let config = DifficultyConfig(level: difficulty)
        currentLevel = difficulty
        columnSize = config.colorsColumnSize
    }

    func startGame() {
        generateColors()
        isGameActive = true
        isGameCompleted = false
        foundPairs.removeAll()
        wrongAttempts = 0
        elapsedTime = 0
        startTime = Date()
        lastSelectionTime = startTime

        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let start = self.startTime else { return }
            self.elapsedTime = Date().timeIntervalSince(start)
        }
    }

    func selectColor(_ color: ColorOption, fromSide: Side) {
        guard isGameActive, !foundPairs.contains(color.name) else { return }

        let now = Date()
        if let last = lastSelectionTime {
            reactionTimes.append(now.timeIntervalSince(last))
        }
        lastSelectionTime = now

        let isInLeft = leftColors.contains { $0.name == color.name }
        let isInRight = rightColors.contains { $0.name == color.name }

        if isInLeft && isInRight {
            foundPairs.insert(color.name)

            #if os(iOS)
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            #endif

            checkCompletion()
        } else {
            wrongAttempts += 1

            #if os(iOS)
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
            #endif
        }
    }

    private func checkCompletion() {
        let leftNames = Set(leftColors.map { $0.name })
        let rightNames = Set(rightColors.map { $0.name })
        let totalPairs = leftNames.intersection(rightNames).count

        if foundPairs.count >= totalPairs {
            completeGame()
        }
    }

    private func completeGame() {
        timer?.invalidate()
        isGameActive = false
        isGameCompleted = true
    }

    func resetGame() {
        timer?.invalidate()
        isGameActive = false
        isGameCompleted = false
        leftColors = []
        rightColors = []
        foundPairs.removeAll()
        elapsedTime = 0
        wrongAttempts = 0
        reactionTimes = []
    }

    private func generateColors() {
        let config = DifficultyConfig(level: currentLevel)
        let shuffledColors = availableColors.shuffled()

        let maxPairs = columnSize / 2
        let requestedPairs = config.colorsMatchingPairs
        let pairCount = min(requestedPairs, maxPairs, availableColors.count / 3)

        let pairs = Array(shuffledColors.prefix(pairCount))

        let nonPairColors = Array(shuffledColors.suffix(from: pairCount))

        var uniquePool = nonPairColors
        if uniquePool.count < columnSize - pairCount {

            var extraIndex = 0
            while uniquePool.count < (columnSize - pairCount) * 2 {
                let color = pairs[extraIndex % pairs.count]

                uniquePool.append(ColorOption(name: "\(color.name)_variant_\(extraIndex)", color: color.color))
                extraIndex += 1
            }
        }

        let leftUniqueCount = columnSize - pairCount
        let leftUnique = Array(uniquePool.prefix(leftUniqueCount))

        let rightStart = leftUniqueCount
        let rightUniqueCount = columnSize - pairCount
        var rightUnique: [ColorOption] = []

        for i in 0..<rightUniqueCount {
            let index = (rightStart + i) % uniquePool.count

            if i < leftUniqueCount && uniquePool[index].name == leftUnique[i].name {
                let altIndex = (index + leftUniqueCount) % uniquePool.count
                rightUnique.append(uniquePool[altIndex])
            } else {
                rightUnique.append(uniquePool[index])
            }
        }

        leftColors = pairs + leftUnique
        rightColors = pairs + rightUnique

        leftColors.shuffle()
        rightColors.shuffle()

        let leftNames = Set(leftColors.map { $0.name })
        let rightNames = Set(rightColors.map { $0.name })
        let commonNames = leftNames.intersection(rightNames)

        if commonNames.count > columnSize / 2 {

            let reducedLevel = DifficultyLevel(rawValue: max(1, currentLevel.rawValue - 1)) ?? .level1
            let originalLevel = currentLevel
            currentLevel = reducedLevel
            generateColors()
            currentLevel = originalLevel
        }
    }

    func getSessionMetrics() -> SessionMetrics? {
        guard isGameCompleted, let start = startTime else { return nil }

        let totalTime = Date().timeIntervalSince(start)
        let correct = foundPairs.count
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

    enum Side {
        case left, right
    }
}

struct ColorOption: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let color: Color
}
