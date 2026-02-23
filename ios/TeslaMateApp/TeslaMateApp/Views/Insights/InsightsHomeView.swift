import SwiftUI

struct InsightsHomeView: View {
    let carId: Int

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
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
                                        insightDestination(for: screen)
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
            .navigationTitle("Insights")
            .carSwitcherToolbar()
        }
    }

    @ViewBuilder
    private func insightDestination(for screen: InsightScreen) -> some View {
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
