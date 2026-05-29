import Foundation

enum PositionDirection: String, Codable, CaseIterable, Sendable {
    case long = "BUY"
    case short = "SELL"
}

struct VirtualPosition: Identifiable, Codable, Sendable {
    let id: UUID
    let instrument: String
    let direction: PositionDirection
    let units: Double
    let entryPrice: Double
    let openTime: Date

    var currentPrice: Double = 0.0

    var unrealizedPL: Double {
        let priceDiff = direction == .long ? (currentPrice - entryPrice) : (entryPrice - currentPrice)
        return priceDiff * units
    }

    var marginUsed: Double {
        (units * entryPrice) * 0.02
    }
}

struct TradeRecord: Identifiable, Codable, Sendable {
    let id: UUID
    let instrument: String
    let direction: PositionDirection
    let units: Double
    let entryPrice: Double
    let exitPrice: Double
    let openTime: Date
    let closeTime: Date
    let realizedPL: Double
}

struct VirtualPortfolio: Codable, Sendable {
    var balance: Double
    var equity: Double
    var marginUsed: Double
    var marginAvailable: Double
    var openPositions: [VirtualPosition]
    var tradeHistory: [TradeRecord]

    static let `default` = VirtualPortfolio(
        balance: 10000.0,
        equity: 10000.0,
        marginUsed: 0.0,
        marginAvailable: 10000.0,
        openPositions: [],
        tradeHistory: []
    )
}

enum AgentAction: String, Codable, Sendable {
    case openBuy = "OPEN_BUY"
    case openSell = "OPEN_SELL"
    case closePosition = "CLOSE"
    case hold = "HOLD"
}

struct AgentDecision: Codable, Sendable {
    let action: AgentAction
    let instrument: String
    let confidence: Double
    let reasoning: String
    let timestamp: Date

    var shouldTrade: Bool {
        action != .hold && confidence > 0.65
    }
}

struct MarketState: Codable, Sendable {
    let instrument: String
    let currentPrice: Double
    let candles: [V2Candle]
    let trend: Double
    let volatility: Double
    let timestamp: Date
}
