import Foundation

final class DependencyContainer {
    static let shared = DependencyContainer()

    private init() {}

    lazy var authManager: AuthManager = {
        let apiKey = "ключ"
        return AuthManager(keychain: KeychainService(), apiKey: apiKey)
    }()

    lazy var apiClient: APIClient = {

        let baseURL = URL(string: "https://fcsapi.com")!
        return APIClient(baseURL: baseURL, authManager: authManager)
    }()

    lazy var exchangeRatesService: ExchangeRatesService = {
        ExchangeRatesService(apiClient: apiClient)
    }()

    lazy var virtualTradingService: VirtualTradingService = {
        VirtualTradingService()
    }()

    lazy var forecastService: ForecastService = {
        ForecastService()
    }()

    lazy var tradingAgentService: TradingAgentService = {
        TradingAgentService(
            forecastService: forecastService,
            tradingService: virtualTradingService
        )
    }()

    func dashboardViewModel() -> DashboardViewModel {
        DashboardViewModel(
            exchangeRatesService: exchangeRatesService,
            tradingService: virtualTradingService,
            agentService: tradingAgentService
        )
    }

    func chartViewModel(instrument: String) -> ChartViewModel {
        ChartViewModel(
            instrument: instrument,
            exchangeRatesService: exchangeRatesService,
            agentService: tradingAgentService
        )
    }
}
