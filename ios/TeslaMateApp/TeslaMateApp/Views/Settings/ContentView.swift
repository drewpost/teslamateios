import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        Group {
            if appState.isAuthenticated {
                if horizontalSizeClass == .regular {
                    SidebarNavigationView()
                } else {
                    MainTabView()
                }
            } else {
                SettingsView()
            }
        }
    }
}
