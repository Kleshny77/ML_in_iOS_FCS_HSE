import Foundation
import Combine

enum LoadingState: Equatable {
    case idle
    case loading
    case loaded
    case error(String)
}

@MainActor
final class MortgageViewModel: ObservableObject {
    
    @Published var areaText: String = "75"
    @Published var roomsText: String = "3"
    @Published var bathroomsText: String = "2"
    @Published var garageText: String = "1"
    @Published var distanceText: String = "2.5"
    @Published var floorText: String = "5"
    @Published var buildYearText: String = "2010"
    
    @Published var mortgageSettings = MortgageSettings.default
    
    @Published var result: MortgageResult?
    @Published var loadingState: LoadingState = .idle
    
    private let predictionService: PricePredictionServiceProtocol
    private let mortgageCalculator: MortgageCalculatorProtocol
    
    private var cancellables = Set<AnyCancellable>()
    private var debounceTask: Task<Void, Never>?
    
    var propertyInput: PropertyInput? {
        guard let area = Double(areaText),
              let rooms = Int(roomsText),
              let bathrooms = Int(bathroomsText),
              let garage = Int(garageText),
              let distance = Double(distanceText),
              let floor = Int(floorText),
              let buildYear = Int(buildYearText) else {
            return nil
        }
        
        return PropertyInput(
            area: area,
            totalRooms: rooms,
            bathrooms: bathrooms,
            garageSpaces: garage,
            distanceToCenter: distance,
            floor: floor,
            buildYear: buildYear
        )
    }
    
    var errorMessage: String? {
        if case .error(let message) = loadingState {
            return message
        }
        return nil
    }
    
    var isCalculating: Bool {
        loadingState == .loading
    }
    
    init(
        predictionService: PricePredictionServiceProtocol = PricePredictionService.shared,
        mortgageCalculator: MortgageCalculatorProtocol = MortgageCalculator.shared
    ) {
        self.predictionService = predictionService
        self.mortgageCalculator = mortgageCalculator
        
        setupBindings()
    }
    
    private func setupBindings() {
        Publishers.MergeMany(
            $areaText.map { _ in () },
            $roomsText.map { _ in () },
            $bathroomsText.map { _ in () },
            $garageText.map { _ in () },
            $distanceText.map { _ in () },
            $floorText.map { _ in () },
            $buildYearText.map { _ in () }
        )
        .dropFirst(7)
        .sink { [weak self] _ in
            self?.debouncedCalculate()
        }
        .store(in: &cancellables)
        
        $mortgageSettings
            .dropFirst()
            .sink { [weak self] _ in
                self?.recalculateMortgageOnly()
            }
            .store(in: &cancellables)
    }
    
    func onAppear() {
        calculateFull()
    }
    
    func calculateFull() {
        debounceTask?.cancel()
        
        debounceTask = Task {
            await performFullCalculation()
        }
    }
    
    private func debouncedCalculate() {
        debounceTask?.cancel()
        
        debounceTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            
            guard !Task.isCancelled else { return }
            
            await performFullCalculation()
        }
    }
    
    private func performFullCalculation() async {
        guard let property = propertyInput else {
            loadingState = .error("Введите корректные числовые значения")
            result = nil
            return
        }
        
        let validation = property.validate()
        guard validation.isValid else {
            loadingState = .error(validation.errorMessage ?? "Ошибка валидации")
            result = nil
            return
        }
        
        loadingState = .loading
        
        do {
            let price = try await predictionService.predictPrice(for: property)
            
            let mortgageResult = mortgageCalculator.calculateResult(
                price: price,
                settings: mortgageSettings
            )
            
            result = mortgageResult
            loadingState = .loaded
            
        } catch {
            loadingState = .error(error.localizedDescription)
            result = nil
        }
    }
    
    private func recalculateMortgageOnly() {
        guard let currentResult = result else {
            debouncedCalculate()
            return
        }
        
        result = mortgageCalculator.calculateResult(
            price: currentResult.predictedPrice,
            settings: mortgageSettings
        )
    }
}
