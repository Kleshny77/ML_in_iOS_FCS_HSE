import SwiftUI
import Combine

@main
struct TradeAIApp: App {

    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
    }
}

class AppState: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var selectedAccountID: String?

    @MainActor
    func checkAuthStatus() async {
        let authManager = DependencyContainer.shared.authManager
        let authenticated = await authManager.isAuthenticated()
        print("[AppState] Auth check: \(authenticated)")
        self.isAuthenticated = authenticated
    }
}

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Group {
            if appState.isAuthenticated {
                MainTabView()
            } else {
                LoginView()
            }
        }
        .task {
            await appState.checkAuthStatus()
        }
    }
}
