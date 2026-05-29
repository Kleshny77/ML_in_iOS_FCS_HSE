import Foundation
import CoreML

protocol PricePredictionServiceProtocol {
    func predictPrice(for property: PropertyInput) async throws -> Double
}

enum PredictionError: LocalizedError {
    case modelLoadFailed
    case predictionFailed(String)
    case invalidInput
    
    var errorDescription: String? {
        switch self {
        case .modelLoadFailed:
            return "Не удалось загрузить ML-модель"
        case .predictionFailed(let message):
            return "Ошибка предсказания: \(message)"
        case .invalidInput:
            return "Некорректные входные данные"
        }
    }
}

final class PricePredictionService: PricePredictionServiceProtocol {
    
    static let shared = PricePredictionService()
    
    private var model: HousePricePredictor?
    
    private init() {
        loadModel()
    }
    
    private func loadModel() {
        do {
            let config = MLModelConfiguration()
            config.computeUnits = .all
            model = try HousePricePredictor(configuration: config)
        } catch {
            print("⚠️ Не удалось загрузить ML-модель: \(error)")
            model = nil
        }
    }
    
    func predictPrice(for property: PropertyInput) async throws -> Double {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: PredictionError.modelLoadFailed)
                    return
                }
                
                do {
                    let price = try self.performPrediction(for: property)
                    continuation.resume(returning: price)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func performPrediction(for property: PropertyInput) throws -> Double {
        if let model = model {
            return try predictWithML(model: model, property: property)
        }
        
        return calculateFallbackPrice(for: property)
    }
    
    private func predictWithML(model: HousePricePredictor, property: PropertyInput) throws -> Double {
        let input = HousePricePredictorInput(
            area: Int64(property.area),
            total_rooms: Int64(property.totalRooms),
            bathrooms: Int64(property.bathrooms),
            garage_spaces: Int64(property.garageSpaces),
            distance_to_center: property.distanceToCenter,
            floor: Int64(property.floor),
            build_year: Int64(property.buildYear)
        )
        
        let prediction = try model.prediction(input: input)
        return prediction.price
    }
    
    private func calculateFallbackPrice(for property: PropertyInput) -> Double {
        let basePricePerSqm = 70_000.0
        let roomBonus = Double(property.totalRooms) * 250_000
        let bathroomBonus = Double(property.bathrooms) * 150_000
        let garageBonus = Double(property.garageSpaces) * 300_000
        let distanceDiscount = property.distanceToCenter * 120_000
        let yearBonus = Double(property.buildYear - 1970) * 15_000
        let floorAdjustment = property.floor <= 2 ? -100_000 : (property.floor > 10 ? 50_000 : 0)
        
        let total = (property.area * basePricePerSqm)
            + roomBonus
            + bathroomBonus
            + garageBonus
            - distanceDiscount
            + yearBonus
            + Double(floorAdjustment)
        
        return max(total, 1_500_000)
    }
}
