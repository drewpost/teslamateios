import SwiftUI
import SwiftData

@main
struct TeslaMateApp: App {
    @State private var appState = AppState()
    @State private var unitPreference = UnitPreference()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .environment(unitPreference)
                .task {
                    await appState.checkAuth()
                }
        }
    }
}
