import SwiftUI
import Charts

struct ChargingStatsView: View {
    let carId: Int
    @State private var viewModel = ChargingStatsViewModel()
    @State private var period: StatsPeriod = .year
    @State private var referenceDate = Date()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                PeriodPicker(selectedPeriod: $period, referenceDate: $referenceDate)
                    .padding(.horizontal)

                if viewModel.isLoading && viewModel.data == nil {
                    ProgressView()
                        .padding(.top, 60)
                } else if let data = viewModel.data {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        StatCardView(
                            value: "\(data.totals.totalSessions ?? 0)",
                            label: "Sessions"
                        )
                        if let energy = data.totals.totalEnergyKwh {
                            StatCardView(
                                value: String(format: "%.0f kWh", energy),
                                label: "Total Energy"
                            )
                        }
                        if let cost = data.totals.totalCost {
                            StatCardView(
                                value: String(format: "$%.0f", cost),
                                label: "Total Cost"
                            )
                        }
                        StatCardView(
                            value: "\(data.totals.acSessions ?? 0) / \(data.totals.dcSessions ?? 0)",
                            label: "AC / DC"
                        )
                    }
                    .padding(.horizontal)

                    if !data.buckets.isEmpty {
                        Chart(data.buckets) { bucket in
                            if let period = bucket.period.flatMap({ parseDate($0) }),
                               let energy = bucket.energyKwh {
                                BarMark(
                                    x: .value("Period", period, unit: .month),
                                    y: .value("kWh", energy)
                                )
                                .foregroundStyle(.green.gradient)
                            }
                        }
                        .chartYAxisLabel("kWh")
                        .frame(height: 220)
                        .padding(.horizontal)
                    }
                } else if let error = viewModel.error {
                    ContentUnavailableView("Error", systemImage: "exclamationmark.triangle", description: Text(error))
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Charging Stats")
        .task { Task { await reload() } }
        .onChange(of: period) { Task { await reload() } }
        .onChange(of: referenceDate) { Task { await reload() } }
    }

    private func reload() async {
        let picker = PeriodPicker(selectedPeriod: $period, referenceDate: $referenceDate)
        let range = picker.dateRange
        await viewModel.load(carId: carId, from: range.from, to: range.to, bucket: period.bucket)
    }

    private func parseDate(_ str: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: str) ?? ISO8601DateFormatter().date(from: str)
    }
}
