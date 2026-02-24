import SwiftUI
import Charts

struct BatteryHealthView: View {
    let carId: Int
    @State private var viewModel = BatteryHealthViewModel()
    @Environment(UnitPreference.self) private var unitPreference

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if viewModel.isLoading && viewModel.data == nil {
                    ProgressView()
                        .padding(.top, 100)
                } else if let data = viewModel.data {
                    if let soh = data.currentSoh {
                        HeroNumberView(
                            value: String(format: "%.1f%%", soh),
                            label: "Estimated Health"
                        )
                    }

                    // Stats grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        StatCardView(
                            value: "\(data.totalCharges ?? 0)",
                            label: "Total Charges"
                        )
                        if let energy = data.totalEnergyAdded {
                            StatCardView(
                                value: String(format: "%.0f kWh", energy),
                                label: "Energy Added"
                            )
                        }
                        if let capacity = data.usableCapacityKm {
                            StatCardView(
                                value: unitPreference.formatRange(capacity),
                                label: "Usable Range"
                            )
                        }
                    }
                    .padding(.horizontal)

                    // AC/DC energy split pie chart
                    if let ac = data.acEnergyKwh, let dc = data.dcEnergyKwh, (ac + dc) > 0 {
                        VStack(spacing: 8) {
                            Text("AC / DC Energy Split")
                                .font(.subheadline.weight(.medium))

                            Chart {
                                SectorMark(
                                    angle: .value("AC", ac),
                                    innerRadius: .ratio(0.5),
                                    angularInset: 1.5
                                )
                                .foregroundStyle(.green)
                                .annotation(position: .overlay) {
                                    Text(String(format: "%.0f kWh", ac))
                                        .font(.caption2.bold())
                                        .foregroundStyle(.white)
                                }

                                SectorMark(
                                    angle: .value("DC", dc),
                                    innerRadius: .ratio(0.5),
                                    angularInset: 1.5
                                )
                                .foregroundStyle(.orange)
                                .annotation(position: .overlay) {
                                    Text(String(format: "%.0f kWh", dc))
                                        .font(.caption2.bold())
                                        .foregroundStyle(.white)
                                }
                            }
                            .frame(height: 180)
                            .padding(.horizontal)

                            HStack(spacing: 16) {
                                Label("AC", systemImage: "circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                                Label("DC", systemImage: "circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                            }
                        }
                    }

                    // Range over time chart
                    if !data.points.isEmpty {
                        Chart(data.points) { point in
                            if let date = parseDate(point.date),
                               let range = point.ratedRangeKm {
                                PointMark(
                                    x: .value("Date", date),
                                    y: .value("Range", unitPreference.useMiles ? range * 0.621371 : range)
                                )
                                .foregroundStyle(.blue.opacity(0.6))
                                .symbolSize(20)
                            }
                        }
                        .chartYAxisLabel(unitPreference.useMiles ? "Miles" : "km")
                        .frame(height: 250)
                        .padding(.horizontal)
                    }

                    if data.points.isEmpty {
                        ContentUnavailableView(
                            "No Data",
                            systemImage: "heart.text.square",
                            description: Text("Charge to 100% to generate battery health data.")
                        )
                    }
                } else if let error = viewModel.error {
                    ContentUnavailableView(
                        "Error",
                        systemImage: "exclamationmark.triangle",
                        description: Text(error)
                    )
                }
            }
            .padding()
        }
        .navigationTitle("Battery Health")
        .task {
            await viewModel.load(carId: carId)
        }
    }

    private func parseDate(_ str: String?) -> Date? {
        guard let str else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: str) ?? ISO8601DateFormatter().date(from: str)
    }
}
