
import SwiftUI

@main
struct AttentionTrainerApp: App {
    @StateObject private var userStats = UserStats()

    var body: some Scene {
        WindowGroup {
            MainMenuView()
                .environmentObject(userStats)
        }
    }
}
