import SwiftUI
import Charts

struct EfficiencyView: View {
    let carId: Int
    @State private var viewModel = EfficiencyViewModel()
    @State private var period: StatsPeriod = .lifetime
    @State private var referenceDate = Date()
    @Environment(UnitPreference.self) private var unitPreference

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                PeriodPicker(selectedPeriod: $period, referenceDate: $referenceDate)
                    .padding(.horizontal)

                if viewModel.isLoading && viewModel.data == nil {
                    ProgressView()
                        .padding(.top, 100)
                } else if let data = viewModel.data {
                    if let avg = data.avgEfficiency {
                        HeroNumberView(
                            value: String(format: "%.0f", unitPreference.useMiles ? avg * 1.60934 : avg),
                            label: unitPreference.useMiles ? "Avg Wh/mi" : "Avg Wh/km"
                        )
                    }

                    // Stat cards
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        if let net = data.netConsumptionWhKm {
                            StatCardView(
                                value: String(format: "%.0f", unitPreference.useMiles ? net * 1.60934 : net),
                                label: unitPreference.useMiles ? "Net Wh/mi" : "Net Wh/km"
                            )
                        }
                        if let rated = data.ratedEfficiency {
                            StatCardView(
                                value: String(format: "%.0f", unitPreference.useMiles ? rated * 1.60934 : rated),
                                label: unitPreference.useMiles ? "Rated Wh/mi" : "Rated Wh/km"
                            )
                        }
                    }
                    .padding(.horizontal)

                    if !data.points.isEmpty {
                        // Efficiency vs Temperature scatter
                        Chart(data.points) { point in
                            if let temp = point.outsideTempAvg,
                               let eff = point.efficiencyWhKm {
                                let effVal = unitPreference.useMiles ? eff * 1.60934 : eff
                                PointMark(
                                    x: .value("Temp", unitPreference.useFahrenheit ? temp * 9/5 + 32 : temp),
                                    y: .value("Efficiency", effVal)
                                )
                                .foregroundStyle(.green.opacity(0.5))
                                .symbolSize(20)
                            }
                        }
                        .chartXAxisLabel(unitPreference.temperatureUnit)
                        .chartYAxisLabel(unitPreference.useMiles ? "Wh/mi" : "Wh/km")
                        .frame(height: 250)
                        .padding(.horizontal)

                        Text("Efficiency vs. Temperature")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    // Temperature buckets table
                    if let buckets = data.temperatureBuckets, !buckets.isEmpty {
                        VStack(spacing: 8) {
                            Text("Efficiency by Temperature")
                                .font(.subheadline.weight(.medium))
                                .frame(maxWidth: .infinity, alignment: .leading)

                            ForEach(buckets) { bucket in
                                if let temp = bucket.tempBucket {
                                    HStack {
                                        Text(formatTempRange(temp))
                                            .font(.caption.monospacedDigit())
                                            .frame(width: 80, alignment: .leading)
                                        if let eff = bucket.avgEfficiency {
                                            Text(String(format: "%.0f %@", unitPreference.useMiles ? eff * 1.60934 : eff, unitPreference.useMiles ? "Wh/mi" : "Wh/km"))
                                                .font(.caption.monospacedDigit())
                                        }
                                        Spacer()
                                        if let dist = bucket.totalDistanceKm {
                                            Text(unitPreference.formatDistanceShort(dist))
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }
                                        Text("\(bucket.count ?? 0) drives")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    Divider()
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    if data.points.isEmpty {
                        ContentUnavailableView(
                            "No Data",
                            systemImage: "leaf",
                            description: Text("Drive data will appear here.")
                        )
                    }
                } else if let error = viewModel.error {
                    ContentUnavailableView("Error", systemImage: "exclamationmark.triangle", description: Text(error))
                }
            }
            .padding()
        }
        .navigationTitle("Efficiency")
        .task { Task { await reload() } }
        .onChange(of: period) { Task { await reload() } }
        .onChange(of: referenceDate) { Task { await reload() } }
    }

    private func reload() async {
        let picker = PeriodPicker(selectedPeriod: $period, referenceDate: $referenceDate)
        let range = picker.dateRange
        await viewModel.load(carId: carId, from: range.from, to: range.to)
    }

    private func formatTempRange(_ temp: Double) -> String {
        let low = unitPreference.useFahrenheit ? temp * 9/5 + 32 : temp
        let high = unitPreference.useFahrenheit ? (temp + 5) * 9/5 + 32 : temp + 5
        return String(format: "%.0f–%.0f%@", low, high, unitPreference.temperatureUnit)
    }
}
