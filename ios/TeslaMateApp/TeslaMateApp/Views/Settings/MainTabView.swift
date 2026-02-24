import SwiftUI

struct MainTabView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        TabView {
            OverviewTab()
                .tabItem {
                    Label("Overview", systemImage: "car.fill")
                }

            DrivesTab()
                .tabItem {
                    Label("Drives", systemImage: "road.lanes")
                }

            ChargesTab()
                .tabItem {
                    Label("Charges", systemImage: "bolt.fill")
                }

            InsightsTab()
                .tabItem {
                    Label("Insights", systemImage: "chart.xyaxis.line")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
    }
}

// Thin wrappers that read selectedCar from the environment.
// These always exist in the TabView (stable identity), so .onAppear fires reliably.

private struct OverviewTab: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        if let car = appState.selectedCar {
            OverviewView(carId: car.id)
                .id(car.id)
        } else {
            LoadingOrErrorView()
        }
    }
}

private struct DrivesTab: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        if let car = appState.selectedCar {
            DrivesListView(carId: car.id)
                .id(car.id)
        } else {
            LoadingOrErrorView()
        }
    }
}

private struct ChargesTab: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        if let car = appState.selectedCar {
            ChargesListView(carId: car.id)
                .id(car.id)
        } else {
            LoadingOrErrorView()
        }
    }
}

private struct InsightsTab: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        if let car = appState.selectedCar {
            InsightsHomeView(carId: car.id)
                .id(car.id)
        } else {
            LoadingOrErrorView()
        }
    }
}

private struct LoadingOrErrorView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        if case .error(let message) = appState.connectionStatus {
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.largeTitle)
                    .foregroundColor(.orange)
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                Button("Retry") {
                    Task { await appState.loadCars() }
                }
                .buttonStyle(.bordered)
            }
        } else {
            ProgressView("Loading...")
        }
    }
}
