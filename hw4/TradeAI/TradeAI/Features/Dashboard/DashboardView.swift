import SwiftUI

struct DashboardView: View {

    @StateObject private var viewModel: DashboardViewModel

    init(viewModel: DashboardViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            List {
                portfolioSection
                agentSection
                positionsSection
                quotesSection
                actionsSection
            }
            .listStyle(.insetGrouped)
            .onAppear {
                viewModel.startRealtimeUpdates()
            }
            .onDisappear {
                viewModel.stopRealtimeUpdates()
            }
            .refreshable {
                await viewModel.fetchDataAndAnalyze()
            }
            .alert("Ошибка", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    private var portfolioSection: some View {
        Section("Портфель") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    MetricView(title: "Баланс", value: viewModel.portfolio.balance)
                    Spacer()
                    MetricView(title: "Эквити", value: viewModel.portfolio.equity)
                }
                HStack {
                    MetricView(title: "Margin", value: viewModel.portfolio.marginUsed)
                    Spacer()
                    MetricView(title: "Свободно", value: viewModel.portfolio.marginAvailable)
                }

                let totalPL = viewModel.portfolio.equity - viewModel.portfolio.balance
                HStack {
                    Text("Unrealized P&L:")
                        .font(.caption)
                    Spacer()
                    Text(String(format: "%.2f", totalPL))
                        .font(.caption.bold())
                        .foregroundStyle(totalPL >= 0 ? .green : .red)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var agentSection: some View {
        Section("LSTM Агент") {
            if let decision = viewModel.agentDecision {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        SignalBadge(action: decision.action)
                        Spacer()
                        Text("\(Int(decision.confidence * 100))%")
                            .font(.caption.bold())
                            .foregroundStyle(.blue)
                    }
                    Text(decision.reasoning)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("Откройте График для анализа LSTM")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var positionsSection: some View {
        Section("Открытые позиции") {
            if viewModel.portfolio.openPositions.isEmpty {
                Text("Нет открытых позиций")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.portfolio.openPositions) { position in
                    PositionCard(position: position)
                }
            }
        }
    }

    private var quotesSection: some View {
        Section("Котировки") {
            if viewModel.prices.isEmpty {
                if let error = viewModel.errorMessage {
                    Text("Ошибка загрузки: \(error)")
                        .font(.caption)
                        .foregroundStyle(.red)
                } else {
                    Text("Загрузка котировок...")
                        .foregroundStyle(.secondary)
                }
            } else {
                ForEach(viewModel.prices) { rate in
                    HStack {
                        Text(rate.symbol)
                            .font(.headline)
                        Spacer()
                        if let mid = rate.parsedPrice {
                            Text(String(format: "%.5f", mid))
                                .font(.system(.body, design: .monospaced))
                        } else {
                            Text("—")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    private var actionsSection: some View {
        Section("Ручная торговля") {
            HStack(spacing: 12) {
                Button("BUY") {
                    viewModel.manualBuy()
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)

                Button("SELL") {
                    viewModel.manualSell()
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)

                Button("Close All") {
                    viewModel.closeAll()
                }
                .buttonStyle(.bordered)

                Spacer()
            }

            Button("Сбросить портфель") {
                viewModel.resetPortfolio()
            }
            .foregroundStyle(.orange)
        }
    }
}

struct MetricView: View {
    let title: String
    let value: Double

    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(String(format: "%.2f", value))
                .font(.headline)
        }
    }
}

struct SignalBadge: View {
    let action: AgentAction

    var body: some View {
        Text(action.rawValue)
            .font(.caption.bold())
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(colorForAction)
            .foregroundStyle(.white)
            .clipShape(Capsule())
    }

    private var colorForAction: Color {
        switch action {
        case .openBuy: return .green
        case .openSell: return .red
        case .closePosition: return .orange
        case .hold: return .gray
        }
    }
}

struct PositionCard: View {
    let position: VirtualPosition

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(position.instrument) \(position.direction.rawValue)")
                    .font(.subheadline.bold())
                Text("\(String(format: "%.0f", position.units)) units @ \(String(format: "%.5f", position.entryPrice))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.2f", position.unrealizedPL))
                    .font(.subheadline.bold())
                    .foregroundStyle(position.unrealizedPL >= 0 ? .green : .red)
                Text("Current: \(String(format: "%.5f", position.currentPrice))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}
