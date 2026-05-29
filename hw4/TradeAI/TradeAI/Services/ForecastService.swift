import Foundation
import CoreML

enum ForecastDirection: String {
    case up = "BUY"
    case down = "SELL"
    case neutral = "HOLD"
}

struct ForecastResult: Sendable {
    let direction: ForecastDirection
    let confidence: Double
    let timeHorizon: Int
    let timestamp: Date
}

protocol ForecastServiceProtocol: Sendable {
    func predict(for instrument: String, candles: [V2Candle]) async throws -> ForecastResult
}

final class ForecastService: ForecastServiceProtocol, @unchecked Sendable {

    private let model: ForexPredictor?

    init() {
        let configuration = MLModelConfiguration()
        configuration.computeUnits = .all
        self.model = try? ForexPredictor(configuration: configuration)
    }

    func predict(for instrument: String, candles: [V2Candle]) async throws -> ForecastResult {
        guard let model = model else {
            return fastHeuristicPrediction(candles: candles)
        }

        guard candles.count >= 20 else {
            throw ForecastError.insufficientData
        }

        let inputArray = try createInputArray(candles: candles)
        let prediction = try await model.prediction(input_1: inputArray)

        let output = prediction.var_137
        let direction = interpretOutput(output)
        let confidence = extractConfidence(output)

        return ForecastResult(
            direction: direction,
            confidence: confidence,
            timeHorizon: 6,
            timestamp: Date()
        )
    }

    private func fastHeuristicPrediction(candles: [V2Candle]) -> ForecastResult {
        let recent = Array(candles.suffix(10))
        let closes = recent.compactMap { $0.parsedClose }
        guard closes.count >= 10 else {
            return ForecastResult(direction: .neutral, confidence: 0.5, timeHorizon: 6, timestamp: Date())
        }

        let sma5 = closes.suffix(5).reduce(0, +) / 5.0
        let sma10 = closes.reduce(0, +) / 10.0
        let last = closes.last ?? sma5

        let volatility = closes.max()! - closes.min()!
        let momentum = (last - closes.first!) / (volatility + 1e-9)

        let direction: ForecastDirection
        if last > sma5 && sma5 > sma10 && momentum > 0.1 {
            direction = .up
        } else if last < sma5 && sma5 < sma10 && momentum < -0.1 {
            direction = .down
        } else {
            direction = .neutral
        }

        let confidence = min(abs(momentum) * 2.0 + 0.5, 0.95)

        return ForecastResult(
            direction: direction,
            confidence: confidence,
            timeHorizon: 6,
            timestamp: Date()
        )
    }

    private func createInputArray(candles: [V2Candle]) throws -> MLMultiArray {
        let array = try MLMultiArray(shape: [1, 20, 4], dataType: .double)

        let recent = Array(candles.suffix(20))
        for (t, candle) in recent.enumerated() {
            guard let o = candle.parsedOpen,
                  let h = candle.parsedHigh,
                  let l = candle.parsedLow,
                  let c = candle.parsedClose else { continue }

            array[[0, t as NSNumber, 0] as [NSNumber]] = NSNumber(value: o)
            array[[0, t as NSNumber, 1] as [NSNumber]] = NSNumber(value: h)
            array[[0, t as NSNumber, 2] as [NSNumber]] = NSNumber(value: l)
            array[[0, t as NSNumber, 3] as [NSNumber]] = NSNumber(value: c)
        }

        return array
    }

    private func interpretOutput(_ output: MLMultiArray) -> ForecastDirection {
        let value = output[[0] as [NSNumber]].doubleValue
        if value > 0.6 {
            return .up
        } else if value < 0.4 {
            return .down
        } else {
            return .neutral
        }
    }

    private func extractConfidence(_ output: MLMultiArray) -> Double {
        let value = output[[0] as [NSNumber]].doubleValue
        return abs(value - 0.5) * 2.0
    }
}

enum ForecastError: Error {
    case modelNotLoaded
    case insufficientData
    case invalidOutputShape
}
