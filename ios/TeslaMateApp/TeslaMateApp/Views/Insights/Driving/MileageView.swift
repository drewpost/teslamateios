import SwiftUI
import Charts

struct MileageView: View {
    let carId: Int
    @State private var viewModel = MileageViewModel()
    @State private var period: StatsPeriod = .year
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
                    if let odometer = data.currentOdometerKm {
                        HeroNumberView(
                            value: unitPreference.formatDistanceInt(odometer),
                            label: "Current Odometer"
                        )
                    }

                    if !data.buckets.isEmpty {
                        Chart(data.buckets) { bucket in
                            if let period = bucket.period.flatMap({ parseDate($0) }),
                               let cumulative = bucket.cumulativeKm {
                                let value = unitPreference.useMiles ? cumulative * 0.621371 : cumulative
                                AreaMark(
                                    x: .value("Period", period),
                                    y: .value("Cumulative", value)
                                )
                                .foregroundStyle(.blue.opacity(0.2))

                                LineMark(
                                    x: .value("Period", period),
                                    y: .value("Cumulative", value)
                                )
                                .foregroundStyle(.blue)
                            }
                        }
                        .chartYAxisLabel(unitPreference.useMiles ? "mi" : "km")
                        .frame(height: 250)
                        .padding(.horizontal)
                    }
                } else if let error = viewModel.error {
                    ContentUnavailableView("Error", systemImage: "exclamationmark.triangle", description: Text(error))
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Mileage")
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
