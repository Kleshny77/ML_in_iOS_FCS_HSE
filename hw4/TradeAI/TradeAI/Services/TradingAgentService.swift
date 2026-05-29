import Foundation
import Combine

struct AgentConfig: Codable, Sendable {
    var isAutoTradingEnabled: Bool
    var confidenceThreshold: Double
    var defaultUnits: Double
    var stopLossPercent: Double
    var takeProfitPercent: Double

    static let `default` = AgentConfig(
        isAutoTradingEnabled: false,
        confidenceThreshold: 0.70,
        defaultUnits: 1000,
        stopLossPercent: 0.02,
        takeProfitPercent: 0.04
    )
}

final class TradingAgentService: @unchecked Sendable {

    private(set) var lastDecision: AgentDecision?
    private(set) var isAnalyzing: Bool = false

    private let forecastService: ForecastServiceProtocol
    private let tradingService: VirtualTradingService
    private var config: AgentConfig

    init(
        forecastService: ForecastServiceProtocol,
        tradingService: VirtualTradingService,
        config: AgentConfig = .default
    ) {
        self.forecastService = forecastService
        self.tradingService = tradingService
        self.config = config
    }

    func updateConfig(_ newConfig: AgentConfig) {
        self.config = newConfig
    }

    func analyze(instrument: String, candles: [V2Candle], currentPrice: Double) async {
        guard candles.count >= 10 else { return }

        isAnalyzing = true
        defer { isAnalyzing = false }

        do {
            let forecast = try await forecastService.predict(for: instrument, candles: candles)
            let portfolio = await tradingService.getPortfolio()

            let decision = makeDecision(
                instrument: instrument,
                currentPrice: currentPrice,
                forecast: forecast,
                positions: portfolio.openPositions,
                balance: portfolio.balance
            )

            lastDecision = decision

            if config.isAutoTradingEnabled && decision.shouldTrade {
                await executeDecision(decision, currentPrice: currentPrice)
            }

        } catch {
            #if DEBUG
            print("Agent analysis failed: \(error)")
            #endif
        }
    }

    private func makeDecision(
        instrument: String,
        currentPrice: Double,
        forecast: ForecastResult,
        positions: [VirtualPosition],
        balance: Double
    ) -> AgentDecision {
        let relevantPositions = positions.filter { $0.instrument == instrument }
        let longPosition = relevantPositions.first { $0.direction == .long }
        let shortPosition = relevantPositions.first { $0.direction == .short }

        if let pos = longPosition {
            let plPercent = pos.unrealizedPL / balance
            if plPercent <= -config.stopLossPercent {
                return AgentDecision(
                    action: .closePosition,
                    instrument: instrument,
                    confidence: 1.0,
                    reasoning: "Стоп-лосс LONG: убыток \(String(format: "%.2f", plPercent * 100))%",
                    timestamp: Date()
                )
            }
            if plPercent >= config.takeProfitPercent {
                return AgentDecision(
                    action: .closePosition,
                    instrument: instrument,
                    confidence: 1.0,
                    reasoning: "Тейк-профит LONG: прибыль \(String(format: "%.2f", plPercent * 100))%",
                    timestamp: Date()
                )
            }
        }

        if let pos = shortPosition {
            let plPercent = pos.unrealizedPL / balance
            if plPercent <= -config.stopLossPercent {
                return AgentDecision(
                    action: .closePosition,
                    instrument: instrument,
                    confidence: 1.0,
                    reasoning: "Стоп-лосс SHORT: убыток \(String(format: "%.2f", plPercent * 100))%",
                    timestamp: Date()
                )
            }
            if plPercent >= config.takeProfitPercent {
                return AgentDecision(
                    action: .closePosition,
                    instrument: instrument,
                    confidence: 1.0,
                    reasoning: "Тейк-профит SHORT: прибыль \(String(format: "%.2f", plPercent * 100))%",
                    timestamp: Date()
                )
            }
        }

        if forecast.confidence >= config.confidenceThreshold {
            switch forecast.direction {
            case .up:
                if longPosition == nil {
                    return AgentDecision(
                        action: .openBuy,
                        instrument: instrument,
                        confidence: forecast.confidence,
                        reasoning: "LSTM прогнозирует рост с уверенностью \(Int(forecast.confidence * 100))%",
                        timestamp: Date()
                    )
                } else if shortPosition != nil {
                    return AgentDecision(
                        action: .closePosition,
                        instrument: instrument,
                        confidence: forecast.confidence,
                        reasoning: "Закрыть SHORT перед ожидаемым ростом",
                        timestamp: Date()
                    )
                }
            case .down:
                if shortPosition == nil {
                    return AgentDecision(
                        action: .openSell,
                        instrument: instrument,
                        confidence: forecast.confidence,
                        reasoning: "LSTM прогнозирует падение с уверенностью \(Int(forecast.confidence * 100))%",
                        timestamp: Date()
                    )
                } else if longPosition != nil {
                    return AgentDecision(
                        action: .closePosition,
                        instrument: instrument,
                        confidence: forecast.confidence,
                        reasoning: "Закрыть LONG перед ожидаемым падением",
                        timestamp: Date()
                    )
                }
            case .neutral:
                break
            }
        }

        return AgentDecision(
            action: .hold,
            instrument: instrument,
            confidence: forecast.confidence,
            reasoning: "Нет чёткого сигнала (уверенность \(Int(forecast.confidence * 100))%)",
            timestamp: Date()
        )
    }

    private func executeDecision(_ decision: AgentDecision, currentPrice: Double) async {
        let portfolio = await tradingService.getPortfolio()
        let positions = portfolio.openPositions.filter { $0.instrument == decision.instrument }

        switch decision.action {
        case .openBuy:
            _ = await tradingService.openPosition(
                instrument: decision.instrument,
                direction: .long,
                units: config.defaultUnits,
                price: currentPrice
            )
        case .openSell:
            _ = await tradingService.openPosition(
                instrument: decision.instrument,
                direction: .short,
                units: config.defaultUnits,
                price: currentPrice
            )
        case .closePosition:
            for position in positions {
                _ = await tradingService.closePosition(id: position.id, price: currentPrice)
            }
        case .hold:
            break
        }
    }
}
