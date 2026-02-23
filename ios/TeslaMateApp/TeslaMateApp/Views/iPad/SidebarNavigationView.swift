import SwiftUI

enum SidebarDestination: Hashable {
    case overview
    case drives
    case charges
    case insight(InsightScreen)
    case settings
}

struct SidebarNavigationView: View {
    @Environment(AppState.self) private var appState
    @State private var selection: SidebarDestination? = .overview

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                if appState.cars.count > 1 {
                    Section {
                        Menu {
                            ForEach(appState.cars) { car in
                                Button {
                                    appState.selectedCar = car
                                } label: {
                                    HStack {
                                        Text(car.displayName)
                                        if appState.selectedCar?.id == car.id {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                Image(systemName: "car.2.fill")
                                Text(appState.selectedCar?.displayName ?? "Tesla")
                                    .fontWeight(.semibold)
                                Spacer()
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .tint(.primary)
                    }
                }

                Section {
                    NavigationLink(value: SidebarDestination.overview) {
                        Label("Overview", systemImage: "car.fill")
                    }
                    NavigationLink(value: SidebarDestination.drives) {
                        Label("Drives", systemImage: "road.lanes")
                    }
                    NavigationLink(value: SidebarDestination.charges) {
                        Label("Charges", systemImage: "bolt.fill")
                    }
                }

                ForEach(InsightSection.allCases) { section in
                    Section(section.rawValue) {
                        ForEach(InsightScreen.screens(for: section)) { screen in
                            NavigationLink(value: SidebarDestination.insight(screen)) {
                                Label(screen.title, systemImage: screen.icon)
                            }
                        }
                    }
                }

                Section {
                    NavigationLink(value: SidebarDestination.settings) {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
                }
            }
            .navigationTitle("TeslaMate")
        } detail: {
            if let car = appState.selectedCar {
                switch selection {
                case .overview, .none:
                    OverviewView(carId: car.id)
                        .id(car.id)
                case .drives:
                    DrivesListView(carId: car.id)
                        .id(car.id)
                case .charges:
                    ChargesListView(carId: car.id)
                        .id(car.id)
                case .insight(let screen):
                    insightView(for: screen, carId: car.id)
                        .id(car.id)
                case .settings:
                    SettingsView()
                }
            } else {
                ProgressView("Loading...")
            }
        }
    }

    @ViewBuilder
    private func insightView(for screen: InsightScreen, carId: Int) -> some View {
        switch screen {
        case .batteryHealth: BatteryHealthView(carId: carId)
        case .projectedRange: ProjectedRangeView(carId: carId)
        case .chargeLevel: ChargeLevelView(carId: carId)
        case .vampireDrain: VampireDrainView(carId: carId)
        case .driveStats: DriveStatsView(carId: carId)
        case .efficiency: EfficiencyView(carId: carId)
        case .mileage: MileageView(carId: carId)
        case .visited: VisitedView(carId: carId)
        case .chargingStats: ChargingStatsView(carId: carId)
        case .states: StatesView(carId: carId)
        case .timeline: TimelineView(carId: carId)
        case .updates: UpdatesView(carId: carId)
        case .statistics: StatisticsView(carId: carId)
        }
    }
}
