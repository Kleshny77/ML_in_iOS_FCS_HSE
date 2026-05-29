import Foundation

struct PropertyInput {
    var area: Double
    var totalRooms: Int
    var bathrooms: Int
    var garageSpaces: Int
    var distanceToCenter: Double
    var floor: Int
    var buildYear: Int
    
    static let `default` = PropertyInput(
        area: 75,
        totalRooms: 3,
        bathrooms: 2,
        garageSpaces: 1,
        distanceToCenter: 2.5,
        floor: 5,
        buildYear: 2010
    )
    
    struct ValidationResult {
        let isValid: Bool
        let errorMessage: String?
    }
    
    func validate() -> ValidationResult {
        guard area >= 10 && area <= 1000 else {
            return ValidationResult(
                isValid: false,
                errorMessage: "Площадь должна быть от 10 до 1000 м²"
            )
        }
        
        guard totalRooms >= 1 && totalRooms <= 20 else {
            return ValidationResult(
                isValid: false,
                errorMessage: "Количество комнат должно быть от 1 до 20"
            )
        }
        
        guard bathrooms >= 1 && bathrooms <= 10 else {
            return ValidationResult(
                isValid: false,
                errorMessage: "Количество санузлов должно быть от 1 до 10"
            )
        }
        
        guard garageSpaces >= 0 && garageSpaces <= 10 else {
            return ValidationResult(
                isValid: false,
                errorMessage: "Парковочных мест должно быть от 0 до 10"
            )
        }
        
        guard distanceToCenter >= 0 && distanceToCenter <= 100 else {
            return ValidationResult(
                isValid: false,
                errorMessage: "Расстояние до центра должно быть от 0 до 100 км"
            )
        }
        
        guard floor >= 1 && floor <= 100 else {
            return ValidationResult(
                isValid: false,
                errorMessage: "Этаж должен быть от 1 до 100"
            )
        }
        
        let currentYear = Calendar.current.component(.year, from: Date())
        guard buildYear >= 1900 && buildYear <= currentYear + 5 else {
            return ValidationResult(
                isValid: false,
                errorMessage: "Год постройки должен быть от 1900 до \(currentYear + 5)"
            )
        }
        
        return ValidationResult(isValid: true, errorMessage: nil)
    }
}
