import SwiftUI

struct StatisticsView: View {
    let carId: Int
    @State private var viewModel = StatisticsViewModel()
    @Environment(UnitPreference.self) private var unitPreference

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if viewModel.isLoading {
                    ProgressView()
                        .padding(.top, 100)
                } else if viewModel.driveStats != nil || viewModel.chargingStats != nil {
                    // Drive stats section
                    if let drive = viewModel.driveStats?.totals {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Driving", systemImage: "car.fill")
                                .font(.title3.bold())

                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                StatCardView(
                                    value: "\(drive.totalDrives ?? 0)",
                                    label: "Total Drives"
                                )
                                if let dist = drive.totalDistanceKm {
                                    StatCardView(
                                        value: unitPreference.formatDistanceShort(dist),
                                        label: "Total Distance"
                                    )
                                }
                                if let dur = drive.totalDurationMin {
                                    StatCardView(
                                        value: formatDuration(dur),
                                        label: "Total Time"
                                    )
                                }
                                if let speed = drive.avgSpeed {
                                    StatCardView(
                                        value: unitPreference.formatSpeed(speed),
                                        label: "Avg Speed"
                                    )
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Charging stats section
                    if let charge = viewModel.chargingStats?.totals {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Charging", systemImage: "bolt.fill")
                                .font(.title3.bold())

                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                StatCardView(
                                    value: "\(charge.totalSessions ?? 0)",
                                    label: "Sessions"
                                )
                                if let energy = charge.totalEnergyKwh {
                                    StatCardView(
                                        value: String(format: "%.0f kWh", energy),
                                        label: "Total Energy"
                                    )
                                }
                                if let cost = charge.totalCost {
                                    StatCardView(
                                        value: String(format: "$%.2f", cost),
                                        label: "Total Cost"
                                    )
                                }
                                if let avg = charge.avgEnergyKwh {
                                    StatCardView(
                                        value: String(format: "%.1f kWh", avg),
                                        label: "Avg / Session"
                                    )
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                } else if let error = viewModel.error {
                    ContentUnavailableView("Error", systemImage: "exclamationmark.triangle", description: Text(error))
                } else {
                    ContentUnavailableView("No Data", systemImage: "number", description: Text("Statistics will appear here."))
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Statistics")
        .task {
            await viewModel.load(carId: carId)
        }
    }

    private func formatDuration(_ minutes: Int) -> String {
        let d = minutes / 1440
        let h = (minutes % 1440) / 60
        if d > 0 { return "\(d)d \(h)h" }
        let m = minutes % 60
        return h > 0 ? "\(h)h \(m)m" : "\(m)m"
    }
}
