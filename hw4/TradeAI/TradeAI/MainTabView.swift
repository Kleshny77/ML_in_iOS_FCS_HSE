import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            DashboardView(viewModel: DependencyContainer.shared.dashboardViewModel())
                .tabItem {
                    Label("Дашборд", systemImage: "chart.line.uptrend.xyaxis")
                }

            ChartView(instrument: "EUR_USD")
                .tabItem {
                    Label("График", systemImage: "chart.bar")
                }

            SettingsView()
                .tabItem {
                    Label("Настройки", systemImage: "gearshape")
                }
        }
    }
}

struct LoginView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 80))
                .foregroundStyle(.blue)

            Text("TradeAI")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("FCS API Powered Virtual Trading")
                .foregroundStyle(.secondary)

            Button("Войти") {
                appState.isAuthenticated = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }
}
