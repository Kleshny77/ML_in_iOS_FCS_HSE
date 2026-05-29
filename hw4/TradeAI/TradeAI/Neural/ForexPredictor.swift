import Foundation
import CoreML

final class ForexPredictor {

    init(configuration: MLModelConfiguration = MLModelConfiguration()) {}

    func prediction(input_1: MLMultiArray) async throws -> ForexPredictorOutput {
        let probability = try Self.predictProbability(from: input_1)
        let output = try MLMultiArray(shape: [1], dataType: .double)
        output[0] = NSNumber(value: probability)
        return ForexPredictorOutput(var_137: output)
    }

    private static func predictProbability(from input: MLMultiArray) throws -> Double {
        guard input.shape.count == 3,
              input.shape[0].intValue == 1,
              input.shape[2].intValue >= 4 else {
            throw NSError(
                domain: "ForexPredictor",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Expected input shape [1, T, 4]"]
            )
        }

        let timesteps = input.shape[1].intValue
        var closes: [Double] = []
        closes.reserveCapacity(timesteps)

        for t in 0..<timesteps {
            let close = input[[0, t as NSNumber, 3] as [NSNumber]].doubleValue
            if close > 0 {
                closes.append(close)
            }
        }

        guard closes.count >= 10 else {
            return 0.5
        }

        let recent = Array(closes.suffix(10))
        let sma5 = recent.suffix(5).reduce(0, +) / 5.0
        let sma10 = recent.reduce(0, +) / 10.0
        let last = recent.last ?? sma5
        let volatility = (recent.max() ?? last) - (recent.min() ?? last)
        let momentum = (last - (recent.first ?? last)) / (volatility + 1e-9)

        var score = 0.5
        if last > sma5 && sma5 > sma10 && momentum > 0.1 {
            score = 0.5 + min(abs(momentum) * 0.25 + 0.1, 0.45)
        } else if last < sma5 && sma5 < sma10 && momentum < -0.1 {
            score = 0.5 - min(abs(momentum) * 0.25 + 0.1, 0.45)
        }

        return min(max(score, 0.05), 0.95)
    }
}

struct ForexPredictorOutput {
    let var_137: MLMultiArray
}
