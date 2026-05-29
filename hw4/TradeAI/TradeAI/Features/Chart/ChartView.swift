import SwiftUI

struct ChartView: View {
    let instrument: String
    @StateObject private var viewModel: ChartViewModel
    @State private var selectedTimeframe: Timeframe = .h1

    enum Timeframe: String, CaseIterable {
        case m1 = "M1"
        case m5 = "M5"
        case h1 = "H1"
        case d1 = "D1"
    }

    init(instrument: String) {
        self.instrument = instrument
        _viewModel = StateObject(wrappedValue: DependencyContainer.shared.chartViewModel(instrument: instrument))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    timeframePicker

                    if viewModel.isLoading && viewModel.candles.isEmpty {
                        ProgressView()
                            .frame(height: 300)
                    } else if viewModel.candles.isEmpty {
                        Text("Нет данных для отображения")
                            .foregroundStyle(.secondary)
                            .frame(height: 300)
                    } else {
                        CandlestickChartView(candles: viewModel.candles)
                            .frame(height: 300)
                            .background(Color(.systemBackground))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.3)))
                    }

                    if let decision = viewModel.agentDecision {
                        AgentDecisionCard(decision: decision)
                    }

                    if !viewModel.candles.isEmpty {
                        CandleSummarySection(candles: viewModel.candles)
                    }
                }
                .padding()
            }
            .navigationTitle(instrument.replacingOccurrences(of: "_", with: "/"))
            .task(id: selectedTimeframe) {
                await viewModel.loadCandles(timeframe: selectedTimeframe)
            }
            .alert("Ошибка", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    private var timeframePicker: some View {
        Picker("Таймфрейм", selection: $selectedTimeframe) {
            ForEach(Timeframe.allCases, id: \.self) { tf in
                Text(tf.rawValue).tag(tf)
            }
        }
        .pickerStyle(.segmented)
    }
}

struct AgentDecisionCard: View {
    let decision: AgentDecision

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("LSTM Агент")
                .font(.headline)
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
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct CandleSummarySection: View {
    let candles: [FCSHistoryCandle]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Данные свечей")
                .font(.headline)

            let opens = candles.compactMap { $0.parsedOpen }
            let highs = candles.compactMap { $0.parsedHigh }
            let lows = candles.compactMap { $0.parsedLow }
            let closes = candles.compactMap { $0.parsedClose }

            if let firstOpen = opens.first, let lastClose = closes.last {
                HStack {
                    Text("Изменение:")
                    Spacer()
                    let change = lastClose - firstOpen
                    let changePercent = (change / firstOpen) * 100
                    Text("\(String(format: "%.4f", change)) (\(String(format: "%.2f", changePercent))%)")
                        .foregroundStyle(change >= 0 ? .green : .red)
                }
                .font(.caption)
            }

            if let maxHigh = highs.max(), let minLow = lows.min() {
                HStack {
                    Text("Диапазон:")
                    Spacer()
                    Text("\(String(format: "%.5f", minLow)) - \(String(format: "%.5f", maxHigh))")
                        .font(.caption)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct AIPredictionBadge: View {
    let direction: OrderDirection
    let confidence: Double

    var body: some View {
        HStack {
            Image(systemName: direction == .buy ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
            Text("AI: \(direction.rawValue) \(Int(confidence * 100))%")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(direction == .buy ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
        .foregroundStyle(direction == .buy ? .green : .red)
        .clipShape(Capsule())
    }
}
