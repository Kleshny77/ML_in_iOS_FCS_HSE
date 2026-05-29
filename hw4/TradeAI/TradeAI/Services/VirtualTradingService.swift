import Foundation
import Combine

final class VirtualTradingService: @unchecked Sendable {

    private(set) var portfolio: VirtualPortfolio = .default
    private(set) var lastError: String?

    private let storageKey = "virtual_portfolio"
    private let lock = NSLock()

    init() {
        loadPortfolio()
    }

    func resetPortfolio(initialBalance: Double = 10000.0) {
        let fresh = VirtualPortfolio(
            balance: initialBalance,
            equity: initialBalance,
            marginUsed: 0.0,
            marginAvailable: initialBalance,
            openPositions: [],
            tradeHistory: []
        )
        updatePortfolio(fresh)
    }

    func openPosition(
        instrument: String,
        direction: PositionDirection,
        units: Double,
        price: Double
    ) -> VirtualPosition? {
        let marginRequired = (units * price) * 0.02

        lock.lock()
        defer { lock.unlock() }

        guard portfolio.marginAvailable >= marginRequired else {
            lastError = "Недостаточно маржины для открытия позиции"
            return nil
        }

        let position = VirtualPosition(
            id: UUID(),
            instrument: instrument,
            direction: direction,
            units: units,
            entryPrice: price,
            openTime: Date(),
            currentPrice: price
        )

        var updated = portfolio
        updated.openPositions.append(position)
        updated.marginUsed += marginRequired
        updated.marginAvailable = updated.balance - updated.marginUsed
        updatePortfolio(updated)

        return position
    }

    func closePosition(id: UUID, price: Double) -> TradeRecord? {
        lock.lock()
        defer { lock.unlock() }

        var updated = portfolio
        guard let index = updated.openPositions.firstIndex(where: { $0.id == id }) else {
            return nil
        }

        var position = updated.openPositions.remove(at: index)
        position.currentPrice = price

        let pl = position.unrealizedPL
        let trade = TradeRecord(
            id: UUID(),
            instrument: position.instrument,
            direction: position.direction,
            units: position.units,
            entryPrice: position.entryPrice,
            exitPrice: price,
            openTime: position.openTime,
            closeTime: Date(),
            realizedPL: pl
        )

        updated.balance += pl
        updated.marginUsed -= position.marginUsed
        updated.marginAvailable = updated.balance - updated.marginUsed
        updated.tradeHistory.append(trade)

        updatePortfolio(updated)
        return trade
    }

    func closeAllPositions(priceProvider: (String) -> Double) {
        lock.lock()
        defer { lock.unlock() }

        var updated = portfolio
        let positionsToClose = updated.openPositions

        for position in positionsToClose {
            let currentPrice = priceProvider(position.instrument)
            let pl = (position.direction == .long ? (currentPrice - position.entryPrice) : (position.entryPrice - currentPrice)) * position.units

            let trade = TradeRecord(
                id: UUID(),
                instrument: position.instrument,
                direction: position.direction,
                units: position.units,
                entryPrice: position.entryPrice,
                exitPrice: currentPrice,
                openTime: position.openTime,
                closeTime: Date(),
                realizedPL: pl
            )

            updated.balance += pl
            updated.tradeHistory.append(trade)
        }

        updated.openPositions.removeAll()
        updated.marginUsed = 0.0
        updated.marginAvailable = updated.balance
        updatePortfolio(updated)
    }

    func updatePrices(_ prices: [String: Double]) {
        lock.lock()
        defer { lock.unlock() }

        var updated = portfolio
        var totalUnrealizedPL: Double = 0.0

        for i in updated.openPositions.indices {
            if let price = prices[updated.openPositions[i].instrument] {
                updated.openPositions[i].currentPrice = price
                totalUnrealizedPL += updated.openPositions[i].unrealizedPL
            }
        }

        updated.equity = updated.balance + totalUnrealizedPL

        if updated.marginUsed > 0 && updated.equity < updated.marginUsed * 0.5 {
            lastError = "Margin Call! Позиции закрыты автоматически."
            let currentPrices = prices
            for i in updated.openPositions.indices.reversed() {
                let pos = updated.openPositions[i]
                let price = currentPrices[pos.instrument] ?? pos.currentPrice
                let pl = pos.unrealizedPL
                updated.balance += pl
                updated.tradeHistory.append(TradeRecord(
                    id: UUID(),
                    instrument: pos.instrument,
                    direction: pos.direction,
                    units: pos.units,
                    entryPrice: pos.entryPrice,
                    exitPrice: price,
                    openTime: pos.openTime,
                    closeTime: Date(),
                    realizedPL: pl
                ))
            }
            updated.openPositions.removeAll()
            updated.marginUsed = 0.0
            updated.marginAvailable = updated.balance
            updated.equity = updated.balance
        }

        updatePortfolio(updated)
    }

    func getPortfolio() -> VirtualPortfolio {
        lock.lock()
        defer { lock.unlock() }
        return portfolio
    }

    private func loadPortfolio() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let saved = try? JSONDecoder().decode(VirtualPortfolio.self, from: data) else {
            return
        }
        portfolio = saved
    }

    private func updatePortfolio(_ newPortfolio: VirtualPortfolio) {
        portfolio = newPortfolio
        if let data = try? JSONEncoder().encode(newPortfolio) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}
