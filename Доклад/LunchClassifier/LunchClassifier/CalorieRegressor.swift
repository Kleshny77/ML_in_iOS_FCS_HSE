import Vision
import CoreML
import UIKit

final class CalorieRegressor {

    private var visionModel: VNCoreMLModel?

    init() {
        loadModel()
    }

    private func loadModel() {
        guard let url = Bundle.main.url(forResource: "CalorieClassifier", withExtension: "mlmodelc")
            ?? Bundle.main.url(forResource: "CalorieClassifier", withExtension: "mlmodel") else { return }
        do {
            let config = MLModelConfiguration()
            let mlModel = try MLModel(contentsOf: url, configuration: config)
            visionModel = try VNCoreMLModel(for: mlModel)
        } catch {
            print("CalorieRegressor: модель не загружена (\(error))")
        }
    }

    private static func parseCalorieClass(_ identifier: String) -> Int? {
        let prefix = "cal_"
        guard identifier.hasPrefix(prefix),
              let num = Int(identifier.dropFirst(prefix.count)) else { return nil }
        return max(0, num)
    }

    func predictCalories(image: UIImage) async -> Int? {
        guard let ciImage = CIImage(image: image),
              let model = visionModel else { return nil }

        return await withCheckedContinuation { continuation in
            let request = VNCoreMLRequest(model: model) { request, error in
                if error != nil {
                    continuation.resume(returning: nil)
                    return
                }
                guard let results = request.results, let first = results.first as? VNClassificationObservation,
                      let parsed = Self.parseCalorieClass(first.identifier) else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: parsed)
            }
            request.imageCropAndScaleOption = .centerCrop
            let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(returning: nil)
            }
        }
    }

    var isAvailable: Bool { visionModel != nil }
}
