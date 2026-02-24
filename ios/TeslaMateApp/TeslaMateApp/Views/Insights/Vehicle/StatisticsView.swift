import SwiftUI

struct StatisticsView: View {
    let carId: Int
    @State private var viewModel = StatisticsViewModel()
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
                        .padding(.top, 100)
                } else if let data = viewModel.data {
                    if data.buckets.isEmpty {
                        ContentUnavailableView("No Data", systemImage: "number", description: Text("Statistics will appear here."))
                    } else {
                        ForEach(data.buckets) { bucket in
                            periodCard(bucket)
                        }
                    }
                } else if let error = viewModel.error {
                    ContentUnavailableView("Error", systemImage: "exclamationmark.triangle", description: Text(error))
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Statistics")
        .task { Task { await reload() } }
        .onChange(of: period) { Task { await reload() } }
        .onChange(of: referenceDate) { Task { await reload() } }
    }

    private func reload() async {
        let picker = PeriodPicker(selectedPeriod: $period, referenceDate: $referenceDate)
        let range = picker.dateRange
        await viewModel.load(carId: carId, from: range.from, to: range.to, bucket: period.bucket)
    }

    private func periodCard(_ bucket: StatisticsBucket) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Period header
            if let periodStr = bucket.period {
                Text(formatPeriodHeader(periodStr))
                    .font(.headline)
            }

            // Driving section
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                statItem(value: "\(bucket.drives ?? 0)", label: "Drives")

                if let dist = bucket.distanceKm {
                    statItem(value: unitPreference.formatDistanceShort(dist), label: "Distance")
                }

                if let dur = bucket.timeDrivenMin {
                    statItem(value: formatDuration(dur), label: "Time Driven")
                }

                if let speed = bucket.avgSpeed {
                    statItem(value: unitPreference.formatSpeed(speed), label: "Avg Speed")
                }

                if let eff = bucket.efficiencyWhKm {
                    statItem(value: String(format: "%.0f %@", unitPreference.useMiles ? eff * 1.60934 : eff, unitPreference.useMiles ? "Wh/mi" : "Wh/km"), label: "Efficiency")
                }

                if let temp = bucket.avgTemp {
                    statItem(value: unitPreference.formatTemperature(temp), label: "Avg Temp")
                }
            }

            Divider()

            // Charging section
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                statItem(value: "\(bucket.charges ?? 0)", label: "Charges")

                if let energy = bucket.energyAddedKwh {
                    statItem(value: String(format: "%.0f kWh", energy), label: "Energy Added")
                }

                if let cost = bucket.totalCost {
                    statItem(value: String(format: "$%.0f", cost), label: "Cost")
                }

                if let cpk = bucket.costPerKwh {
                    statItem(value: String(format: "$%.2f", cpk), label: "$/kWh")
                }

                if let cp100 = bucket.costPer100km {
                    statItem(value: String(format: "$%.1f", unitPreference.useMiles ? cp100 * 1.60934 : cp100), label: unitPreference.useMiles ? "$/100mi" : "$/100km")
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.subheadline.bold())
                .monospacedDigit()
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private func formatDuration(_ minutes: Int) -> String {
        let d = minutes / 1440
        let h = (minutes % 1440) / 60
        if d > 0 { return "\(d)d \(h)h" }
        let m = minutes % 60
        return h > 0 ? "\(h)h \(m)m" : "\(m)m"
    }

    private func formatPeriodHeader(_ str: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: str) ?? ISO8601DateFormatter().date(from: str) else {
            return str
        }
        let df = DateFormatter()
        switch period {
        case .week:
            df.dateFormat = "MMM d, yyyy"
        case .month:
            df.dateFormat = "MMMM yyyy"
        case .year:
            df.dateFormat = "yyyy"
        case .lifetime:
            df.dateFormat = "yyyy"
        }
        return df.string(from: date)
    }
}
