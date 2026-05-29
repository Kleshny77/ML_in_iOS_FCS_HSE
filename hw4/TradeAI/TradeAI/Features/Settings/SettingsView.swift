import SwiftUI

struct SettingsView: View {

    @AppStorage("agent_autoTrade") private var autoTradeEnabled: Bool = false
    @AppStorage("agent_confidence") private var confidenceThreshold: Double = 0.70
    @AppStorage("agent_units") private var defaultUnits: Double = 1000
    @AppStorage("agent_stopLoss") private var stopLossPercent: Double = 0.02
    @AppStorage("agent_takeProfit") private var takeProfitPercent: Double = 0.04

    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationStack {
            Form {
                Section("LSTM Агент") {
                    Toggle("Автоторговля", isOn: $autoTradeEnabled)

                    VStack(alignment: .leading) {
                        Text("Порог уверенности: \(Int(confidenceThreshold * 100))%")
                            .font(.caption)
                        Slider(value: $confidenceThreshold, in: 0.5...0.95, step: 0.05)
                    }

                    Stepper(value: $defaultUnits, in: 100...10000, step: 100) {
                        Text("Объём сделки: \(Int(defaultUnits))")
                    }

                    VStack(alignment: .leading) {
                        Text("Стоп-лосс: \(Int(stopLossPercent * 100))%")
                            .font(.caption)
                        Slider(value: $stopLossPercent, in: 0.01...0.10, step: 0.01)
                    }

                    VStack(alignment: .leading) {
                        Text("Тейк-профит: \(Int(takeProfitPercent * 100))%")
                            .font(.caption)
                        Slider(value: $takeProfitPercent, in: 0.02...0.20, step: 0.01)
                    }
                }

                Section("Безопасность") {
                    NavigationLink("Биометрическая аутентификация") {
                        BiometricSettingsView()
                    }
                }

                Section {
                    Button("Выйти") {
                        Task {
                            await DependencyContainer.shared.authManager.logout()
                            await MainActor.run {
                                appState.isAuthenticated = false
                            }
                        }
                    }
                    .foregroundStyle(.red)
                }
            }
            .navigationTitle("Настройки")
            .onChange(of: autoTradeEnabled) { _, _ in syncConfig() }
            .onChange(of: confidenceThreshold) { _, _ in syncConfig() }
            .onChange(of: defaultUnits) { _, _ in syncConfig() }
            .onChange(of: stopLossPercent) { _, _ in syncConfig() }
            .onChange(of: takeProfitPercent) { _, _ in syncConfig() }
            .onAppear {
                syncConfig()
            }
        }
    }

    private func syncConfig() {
        let config = AgentConfig(
            isAutoTradingEnabled: autoTradeEnabled,
            confidenceThreshold: confidenceThreshold,
            defaultUnits: defaultUnits,
            stopLossPercent: stopLossPercent,
            takeProfitPercent: takeProfitPercent
        )
        DependencyContainer.shared.tradingAgentService.updateConfig(config)
    }
}

struct BiometricSettingsView: View {
    var body: some View {
        List {
            Text("Face ID / Touch ID используется для подтверждения торговых операций и просмотра баланса.")
                .foregroundStyle(.secondary)
        }
        .navigationTitle("Биометрия")
    }
}
