import SwiftUI

struct MainTabView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        TabView {
            Group {
                if let car = appState.selectedCar {
                    OverviewView(carId: car.id)
                        .id(car.id)
                } else {
                    loadingOrErrorView
                }
            }
            .tabItem {
                Label("Overview", systemImage: "car.fill")
            }

            Group {
                if let car = appState.selectedCar {
                    DrivesListView(carId: car.id)
                        .id(car.id)
                } else {
                    loadingOrErrorView
                }
            }
            .tabItem {
                Label("Drives", systemImage: "road.lanes")
            }

            Group {
                if let car = appState.selectedCar {
                    ChargesListView(carId: car.id)
                        .id(car.id)
                } else {
                    loadingOrErrorView
                }
            }
            .tabItem {
                Label("Charges", systemImage: "bolt.fill")
            }

            Group {
                if let car = appState.selectedCar {
                    InsightsHomeView(carId: car.id)
                        .id(car.id)
                } else {
                    loadingOrErrorView
                }
            }
            .tabItem {
                Label("Insights", systemImage: "chart.xyaxis.line")
            }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
    }

    @ViewBuilder
    private var loadingOrErrorView: some View {
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
