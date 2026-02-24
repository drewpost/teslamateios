import SwiftUI

struct InsightsHomeView: View {
    @Environment(AppState.self) private var appState

    private var carId: Int? { appState.selectedCar?.id }

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            Group {
                if let carId {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            ForEach(InsightSection.allCases) { section in
                                VStack(alignment: .leading, spacing: 12) {
                                    Label(section.rawValue, systemImage: section.icon)
                                        .font(.title3.bold())
                                        .padding(.horizontal)

                                    LazyVGrid(columns: columns, spacing: 12) {
                                        ForEach(InsightScreen.screens(for: section)) { screen in
                                            NavigationLink {
                                                insightDestination(for: screen, carId: carId)
                                            } label: {
                                                InsightCardView(screen: screen)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                        .padding(.vertical)
                    }
                } else {
                    ProgressView("Loading...")
                }
            }
            .navigationTitle("Insights")
            .carSwitcherToolbar()
        }
    }

    @ViewBuilder
    private func insightDestination(for screen: InsightScreen, carId: Int) -> some View {
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
