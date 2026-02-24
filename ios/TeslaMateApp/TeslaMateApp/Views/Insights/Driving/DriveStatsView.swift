import SwiftUI
import Charts

struct DriveStatsView: View {
    let carId: Int
    @State private var viewModel = DriveStatsViewModel()
    @State private var period: StatsPeriod = .month
    @State private var referenceDate = Date()
    @Environment(UnitPreference.self) private var unitPreference

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                PeriodPicker(selectedPeriod: $period, referenceDate: $referenceDate)
                    .padding(.horizontal)

                if viewModel.isLoading && viewModel.data == nil {
                    ProgressView()
                        .padding(.top, 60)
                } else if let data = viewModel.data {
                    // Totals
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        StatCardView(
                            value: "\(data.totals.totalDrives ?? 0)",
                            label: "Drives"
                        )
                        if let dist = data.totals.totalDistanceKm {
                            StatCardView(
                                value: unitPreference.formatDistanceShort(dist),
                                label: "Distance"
                            )
                        }
                        if let dur = data.totals.totalDurationMin {
                            StatCardView(
                                value: formatDuration(dur),
                                label: "Duration"
                            )
                        }
                        if let speed = data.totals.avgSpeed {
                            StatCardView(
                                value: unitPreference.formatSpeed(speed),
                                label: "Avg Speed"
                            )
                        }
                        if let dur = data.totals.totalDurationMin, let drives = data.totals.totalDrives, drives > 0 {
                            StatCardView(
                                value: formatDuration(dur / drives),
                                label: "Avg Duration"
                            )
                        }
                        if let energy = data.totals.totalEnergyKwh {
                            StatCardView(
                                value: String(format: "%.1f kWh", energy),
                                label: "Total Energy"
                            )
                        }
                    }
                    .padding(.horizontal)

                    if !data.buckets.isEmpty {
                        Chart(data.buckets) { bucket in
                            if let period = bucket.period.flatMap({ parseDate($0) }),
                               let dist = bucket.distanceKm {
                                BarMark(
                                    x: .value("Period", period, unit: .month),
                                    y: .value("Distance", unitPreference.useMiles ? dist * 0.621371 : dist)
                                )
                                .foregroundStyle(.blue.gradient)
                            }
                        }
                        .chartYAxisLabel(unitPreference.useMiles ? "mi" : "km")
                        .frame(height: 220)
                        .padding(.horizontal)
                    }
                } else if let error = viewModel.error {
                    ContentUnavailableView("Error", systemImage: "exclamationmark.triangle", description: Text(error))
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Drive Stats")
        .task { Task { await reload() } }
        .onChange(of: period) { Task { await reload() } }
        .onChange(of: referenceDate) { Task { await reload() } }
    }

    private func reload() async {
        let picker = PeriodPicker(selectedPeriod: $period, referenceDate: $referenceDate)
        let range = picker.dateRange
        await viewModel.load(carId: carId, from: range.from, to: range.to, bucket: period.bucket)
    }

    private func formatDuration(_ minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        return h > 0 ? "\(h)h \(m)m" : "\(m)m"
    }

    private func parseDate(_ str: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: str) ?? ISO8601DateFormatter().date(from: str)
    }
}
