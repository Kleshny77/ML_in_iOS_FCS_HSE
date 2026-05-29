import Foundation
import Combine

@MainActor
class DashboardViewModel: ObservableObject {

    @Published var prices: [FCSPriceItem] = []
    @Published var portfolio: VirtualPortfolio = .default
    @Published var agentDecision: AgentDecision?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let exchangeRatesService: ExchangeRatesServiceProtocol
    private let tradingService: VirtualTradingService
    private let agentService: TradingAgentService
    private let favoritePairs = ["EUR/USD", "GBP/USD", "USD/JPY", "XAU/USD"]
    private var timer: Timer?

    init(
        exchangeRatesService: ExchangeRatesServiceProtocol,
        tradingService: VirtualTradingService,
        agentService: TradingAgentService
    ) {
        self.exchangeRatesService = exchangeRatesService
        self.tradingService = tradingService
        self.agentService = agentService
    }

    func startRealtimeUpdates() {
        print("[DashboardViewModel] startRealtimeUpdates")
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 25.0, repeats: true) { [weak self] _ in
            Task {
                await self?.fetchPricesAndUpdatePortfolio()
            }
        }
        Task {
            await fetchPricesAndUpdatePortfolio()
        }
    }

    func stopRealtimeUpdates() {
        timer?.invalidate()
        timer = nil
    }

    func fetchDataAndAnalyze() async {
        await fetchPricesAndUpdatePortfolio()
    }

    func fetchPricesAndUpdatePortfolio() async {
        print("[DashboardViewModel] fetchPricesAndUpdatePortfolio START")
        isLoading = true
        defer { isLoading = false }

        do {
            let prices = try await fetchFavoritePrices()
            print("[DashboardViewModel] fetched \(prices.count) prices")
            self.prices = prices

            let priceMap = Dictionary(uniqueKeysWithValues: prices.compactMap {
                if let price = $0.parsedPrice {
                    return ($0.symbol.replacingOccurrences(of: "/", with: "_"), price)
                }
                return nil
            })
            print("[DashboardViewModel] priceMap: \(priceMap)")
            tradingService.updatePrices(priceMap)
            self.portfolio = tradingService.getPortfolio()
            print("[DashboardViewModel] portfolio updated: balance=\(portfolio.balance) equity=\(portfolio.equity)")

        } catch {
            print("[DashboardViewModel] fetchPricesAndUpdatePortfolio ERROR: \(error)")
            let msg = error.localizedDescription
            if msg.contains("429") || msg.contains("213") {
                errorMessage = "Rate limit API: лимит 3 запроса/мин. Обновление каждые 60 сек."
            } else {
                errorMessage = msg
            }
        }
    }

    func manualBuy() {
        guard let priceItem = prices.first,
              let mid = priceItem.parsedPrice else { return }
        let instrument = priceItem.symbol.replacingOccurrences(of: "/", with: "_")
        _ = tradingService.openPosition(
            instrument: instrument,
            direction: .long,
            units: 1000,
            price: mid
        )
        Task {
            await fetchPricesAndUpdatePortfolio()
        }
    }

    func manualSell() {
        guard let priceItem = prices.first,
              let mid = priceItem.parsedPrice else { return }
        let instrument = priceItem.symbol.replacingOccurrences(of: "/", with: "_")
        _ = tradingService.openPosition(
            instrument: instrument,
            direction: .short,
            units: 1000,
            price: mid
        )
        Task {
            await fetchPricesAndUpdatePortfolio()
        }
    }

    func closeAll() {
        let priceMap = Dictionary(uniqueKeysWithValues: prices.compactMap {
            if let price = $0.parsedPrice {
                return ($0.symbol.replacingOccurrences(of: "/", with: "_"), price)
            }
            return nil
        })
        tradingService.closeAllPositions(priceProvider: { instrument in
            priceMap[instrument] ?? 0.0
        })
        Task {
            await fetchPricesAndUpdatePortfolio()
        }
    }

    func resetPortfolio() {
        tradingService.resetPortfolio(initialBalance: 10000.0)
        Task {
            await fetchPricesAndUpdatePortfolio()
        }
    }

    private func fetchFavoritePrices() async throws -> [FCSPriceItem] {
        print("[DashboardViewModel] fetchFavoritePrices START")
        let bulkSymbol = favoritePairs.joined(separator: ",")
        do {
            let response = try await exchangeRatesService.fetchLatestPrice(symbol: bulkSymbol)
            print("[DashboardViewModel] bulk response code: \(response.code ?? -1)")
            guard let items = response.response, !items.isEmpty else {
                if let code = response.code, code == 213 {
                    throw NetworkError.serverError(statusCode: 429)
                }
                throw NetworkError.noData
            }
            print("[DashboardViewModel] bulk items count: \(items.count)")
            return items
        } catch {
            print("[DashboardViewModel] Failed to fetch bulk prices: \(error)")
            throw error
        }
    }
}
