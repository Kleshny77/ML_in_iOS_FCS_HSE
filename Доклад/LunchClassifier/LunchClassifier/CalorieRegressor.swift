import Vision
import CoreML
import UIKit

final class CalorieRegressor {

    private var visionModel: VNCoreMLModel?

    init() {
        loadModel()
    }

    private func loadModel() {
        do {
            let config = MLModelConfiguration()
            config.computeUnits = .all
            let coreMLModel = try CalorieClassifier(configuration: config)
            visionModel = try VNCoreMLModel(for: coreMLModel.model)
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
                guard let results = request.results as? [VNClassificationObservation],
                      let top = results.first,
                      let parsed = Self.parseCalorieClass(top.identifier) else {
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
