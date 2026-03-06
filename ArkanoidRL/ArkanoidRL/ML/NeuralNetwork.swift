import Foundation

struct NeuralNetworkState: Codable {
    let inputSize: Int
    let hiddenSize: Int
    let weights: [[Double]]
    let biases: [Double]
    let experienceBuffer: [Experience]
    let recentErrors: [Double]
    let explorationRate: Double
}

final class ReinforcementNeuralNetwork {
    private var weights: [[Double]]
    private var biases: [Double]
    private let learningRate: Double = 0.05
    private let discountFactor: Double = 0.95

    private var experienceBuffer: [Experience] = []
    private let maxBufferSize = 500
    private var recentErrors: [Double] = []

    init(inputSize: Int, hiddenSize: Int = 8) {
        weights = Array(repeating: Array(repeating: 0.0, count: hiddenSize), count: inputSize)
        biases = Array(repeating: 0.0, count: hiddenSize)
        initializeWeights(inputSize: inputSize, hiddenSize: hiddenSize)
    }

    init(state: NeuralNetworkState) {
        let inputSize = max(state.inputSize, state.weights.count)
        let hiddenSize = max(state.hiddenSize, state.biases.count)

        let hasValidShape =
            !state.weights.isEmpty &&
            state.weights.count == inputSize &&
            state.weights.allSatisfy { $0.count == hiddenSize } &&
            state.biases.count == hiddenSize

        if hasValidShape {
            weights = state.weights
            biases = state.biases
            experienceBuffer = Array(state.experienceBuffer.suffix(maxBufferSize))
            recentErrors = Array(state.recentErrors.suffix(100))
        } else {
            weights = Array(repeating: Array(repeating: 0.0, count: hiddenSize), count: inputSize)
            biases = Array(repeating: 0.0, count: hiddenSize)
            initializeWeights(inputSize: inputSize, hiddenSize: hiddenSize)
        }
    }

    private func initializeWeights(inputSize: Int, hiddenSize: Int) {
        let scale = sqrt(2.0 / Double(inputSize + hiddenSize))
        for i in 0..<inputSize {
            for j in 0..<hiddenSize {
                weights[i][j] = Double.random(in: -scale...scale)
            }
        }

        for j in 0..<hiddenSize {
            biases[j] = Double.random(in: -0.1...0.1)
        }
    }

    func predict(inputs: [Double]) -> Double {
        var hiddenOutputs = [Double](repeating: 0, count: biases.count)

        for j in 0..<biases.count {
            var sum = biases[j]
            for i in 0..<inputs.count {
                sum += inputs[i] * weights[i][j]
            }
            hiddenOutputs[j] = max(0, sum)
        }

        var output: Double = 0
        for j in 0..<hiddenOutputs.count {
            output += hiddenOutputs[j] * 0.1
        }

        return 1.0 / (1.0 + exp(-output))
    }

    func trainOnExperience() {
        guard !experienceBuffer.isEmpty else { return }

        let batchSize = min(32, experienceBuffer.count)
        var batchIndices = Set<Int>()
        while batchIndices.count < batchSize {
            batchIndices.insert(Int.random(in: 0..<experienceBuffer.count))
        }

        for index in batchIndices {
            let experience = experienceBuffer[index]

            let currentQ = predict(inputs: experience.state)
            let nextQ = predict(inputs: experience.nextState)
            let targetQ = experience.reward + discountFactor * nextQ

            let error = targetQ - currentQ
            let gradient = error * currentQ * (1 - currentQ)

            for i in 0..<weights.count {
                for j in 0..<weights[i].count {
                    weights[i][j] += learningRate * gradient * experience.state[i]
                }
            }

            for j in 0..<biases.count {
                biases[j] += learningRate * gradient * 0.1
            }

            recentErrors.append(abs(error))
            if recentErrors.count > 100 {
                recentErrors.removeFirst()
            }
        }

        normalizeWeights()
    }

    private func normalizeWeights() {
        let maxWeight = 3.0
        for i in 0..<weights.count {
            for j in 0..<weights[i].count {
                if weights[i][j] > maxWeight {
                    weights[i][j] = maxWeight
                } else if weights[i][j] < -maxWeight {
                    weights[i][j] = -maxWeight
                }
            }
        }
    }

    func addExperience(state: [Double], action: Double, reward: Double, nextState: [Double]) {
        experienceBuffer.append(
            Experience(
                state: state,
                action: action,
                reward: reward,
                nextState: nextState
            )
        )

        if experienceBuffer.count > maxBufferSize {
            experienceBuffer.removeFirst(100)
        }
    }

    func calculateError() -> Double {
        guard !recentErrors.isEmpty else { return 1.0 }
        return recentErrors.reduce(0, +) / Double(recentErrors.count)
    }

    func resetTrainingData() {
        experienceBuffer.removeAll()
        recentErrors.removeAll()
    }

    func getExperienceCount() -> Int {
        experienceBuffer.count
    }

    func makeState(explorationRate: Double) -> NeuralNetworkState {
        NeuralNetworkState(
            inputSize: weights.count,
            hiddenSize: biases.count,
            weights: weights,
            biases: biases,
            experienceBuffer: experienceBuffer,
            recentErrors: recentErrors,
            explorationRate: explorationRate
        )
    }
}
