import Foundation

enum ExchangeRatesEndpoint: Endpoint {
    case latest(symbol: String)
    case history(symbol: String, period: String, limit: Int)
    case news(limit: Int)
    case currencies
    case indicators(symbol: String)

    var path: String {
        switch self {
        case .latest:
            return "/api-v3/forex/latest"
        case .history:
            return "/api-v3/forex/history"
        case .news:
            return "/api-v3/forex/news"
        case .currencies:
            return "/api-v3/forex/currency"
        case .indicators:
            return "/api-v3/forex/indicators"
        }
    }

    var queryItems: [URLQueryItem]? {
        var items: [URLQueryItem] = []
        switch self {
        case .latest(let symbol):
            items.append(URLQueryItem(name: "symbol", value: symbol))
        case .history(let symbol, let period, let limit):
            items.append(URLQueryItem(name: "symbol", value: symbol))
            items.append(URLQueryItem(name: "period", value: period))
            items.append(URLQueryItem(name: "limit", value: "\(limit)"))
        case .news(let limit):
            items.append(URLQueryItem(name: "limit", value: "\(limit)"))
        case .currencies:
            break
        case .indicators(let symbol):
            items.append(URLQueryItem(name: "symbol", value: symbol))
        }
        return items.isEmpty ? nil : items
    }
}

protocol ExchangeRatesServiceProtocol: Sendable {
    func fetchLatestPrice(symbol: String) async throws -> FCSPriceResponse
    func fetchHistory(symbol: String, period: String, limit: Int) async throws -> FCSHistoryResponse
    func fetchNews(limit: Int) async throws -> FCSNewsResponse
    func fetchCurrencies() async throws -> FCSCurrenciesResponse
    func fetchIndicators(symbol: String) async throws -> FCSIndicatorsResponse
}

final class ExchangeRatesService: ExchangeRatesServiceProtocol, @unchecked Sendable {

    private let apiClient: any APIClientProtocol

    init(apiClient: any APIClientProtocol) {
        self.apiClient = apiClient
    }

    func fetchLatestPrice(symbol: String) async throws -> FCSPriceResponse {
        print("[ExchangeRatesService] fetchLatestPrice: \(symbol)")
        let response: FCSPriceResponse = try await apiClient.request(ExchangeRatesEndpoint.latest(symbol: symbol))
        print("[ExchangeRatesService] fetchLatestPrice OK: \(symbol), items: \(response.response?.count ?? 0)")
        return response
    }

    func fetchHistory(symbol: String, period: String = "1h", limit: Int = 60) async throws -> FCSHistoryResponse {
        print("[ExchangeRatesService] fetchHistory: \(symbol) period=\(period) limit=\(limit)")
        let response: FCSHistoryResponse = try await apiClient.request(ExchangeRatesEndpoint.history(symbol: symbol, period: period, limit: limit))
        print("[ExchangeRatesService] fetchHistory OK: \(symbol), candles: \(response.candles.count)")
        return response
    }

    func fetchNews(limit: Int = 10) async throws -> FCSNewsResponse {
        try await apiClient.request(ExchangeRatesEndpoint.news(limit: limit))
    }

    func fetchCurrencies() async throws -> FCSCurrenciesResponse {
        try await apiClient.request(ExchangeRatesEndpoint.currencies)
    }

    func fetchIndicators(symbol: String) async throws -> FCSIndicatorsResponse {
        print("[ExchangeRatesService] fetchIndicators: \(symbol)")
        let response: FCSIndicatorsResponse = try await apiClient.request(ExchangeRatesEndpoint.indicators(symbol: symbol))
        print("[ExchangeRatesService] fetchIndicators OK: \(symbol), items: \(response.response?.count ?? 0)")
        return response
    }
}
