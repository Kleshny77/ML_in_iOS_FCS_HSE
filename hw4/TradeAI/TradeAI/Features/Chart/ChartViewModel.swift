import Foundation
import Combine

@MainActor
class ChartViewModel: ObservableObject {

    @Published var candles: [FCSHistoryCandle] = []
    @Published var agentDecision: AgentDecision?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let exchangeRatesService: ExchangeRatesServiceProtocol
    private let agentService: TradingAgentService
    private let instrument: String

    init(
        instrument: String,
        exchangeRatesService: ExchangeRatesServiceProtocol,
        agentService: TradingAgentService
    ) {
        self.instrument = instrument
        self.exchangeRatesService = exchangeRatesService
        self.agentService = agentService
    }

    func loadCandles(timeframe: ChartView.Timeframe) async {
        print("[ChartViewModel] loadCandles START for \(instrument) timeframe=\(timeframe.rawValue)")
        isLoading = true
        defer { isLoading = false }

        let symbol = instrument.replacingOccurrences(of: "_", with: "/")

        let period: String
        let limit: Int
        switch timeframe {
        case .m1:
            period = "1m"
            limit = 60
        case .m5:
            period = "5m"
            limit = 72
        case .h1:
            period = "1h"
            limit = 48
        case .d1:
            period = "1d"
            limit = 90
        }

        do {
            let candlesResponse = try await exchangeRatesService.fetchHistory(
                symbol: symbol,
                period: period,
                limit: limit
            )
            self.candles = candlesResponse.candles
            print("[ChartViewModel] Loaded \(self.candles.count) candles for \(symbol)")

            if let lastCandle = candles.last,
               let currentPrice = lastCandle.parsedClose,
               candles.count >= 10 {
                let v2Candles = candles.map { fcsCandle -> V2Candle in
                    V2Candle(
                        base_currency: String(instrument.prefix(3)),
                        quote_currency: String(instrument.suffix(3)),
                        start_time: fcsCandle.t,
                        open_time: nil,
                        close_time: nil,
                        open_bid: fcsCandle.o,
                        open_ask: nil,
                        open_midpoint: fcsCandle.o,
                        close_bid: fcsCandle.c,
                        close_ask: nil,
                        close_midpoint: fcsCandle.c,
                        high_bid: fcsCandle.h,
                        high_ask: nil,
                        high_midpoint: fcsCandle.h,
                        low_bid: fcsCandle.l,
                        low_ask: nil,
                        low_midpoint: fcsCandle.l,
                        average_bid: nil,
                        average_ask: nil,
                        average_midpoint: nil
                    )
                }
                await agentService.analyze(
                    instrument: instrument,
                    candles: v2Candles,
                    currentPrice: currentPrice
                )
                self.agentDecision = agentService.lastDecision
                print("[ChartViewModel] Agent decision: \(agentService.lastDecision?.action.rawValue ?? "nil")")
            }

        } catch {
            print("[ChartViewModel] Failed to load candles: \(error)")
            errorMessage = error.localizedDescription
            self.candles = []
        }

        print("[ChartViewModel] loadCandles END")
    }
}
