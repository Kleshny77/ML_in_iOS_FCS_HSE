import Vision
import CoreML
import UIKit

final class ImageClassifier {

    private var visionModel: VNCoreMLModel?
    private let caloriePredictor = CalorieRegressor()

    init() {
        loadModel()
    }

    private func loadModel() {
        guard let modelURL = Bundle.main.url(forResource: "FoodClassifier", withExtension: "mlmodelc")
            ?? Bundle.main.url(forResource: "FoodClassifier", withExtension: "mlmodel") else { return }
        do {
            let config = MLModelConfiguration()
            let mlModel = try MLModel(contentsOf: modelURL, configuration: config)
            visionModel = try VNCoreMLModel(for: mlModel)
        } catch {
            print("Ошибка загрузки модели: \(error)")
        }
    }

    func classify(image: UIImage) async -> (classLabel: String, confidence: Float)? {
        guard let ciImage = CIImage(image: image),
              let model = visionModel else { return nil }

        return await withCheckedContinuation { continuation in
            let request = VNCoreMLRequest(model: model) { request, error in
                if let error = error {
                    print("Ошибка классификации: \(error)")
                    continuation.resume(returning: nil)
                    return
                }
                guard let results = request.results as? [VNClassificationObservation],
                      let top = results.first else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: (top.identifier.lowercased(), top.confidence))
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

    func calories(image: UIImage) async -> Int? {
        await caloriePredictor.predictCalories(image: image)
    }

    var isCalorieModelAvailable: Bool { caloriePredictor.isAvailable }
}
