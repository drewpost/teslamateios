import SwiftUI
import Charts

struct VampireDrainView: View {
    let carId: Int
    @State private var viewModel = VampireDrainViewModel()
    @State private var period: StatsPeriod = .month
    @State private var referenceDate = Date()
    @State private var minIdleHours: Int = 1
    @Environment(UnitPreference.self) private var unitPreference

    private let idleOptions = [1, 4, 8, 24]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                PeriodPicker(selectedPeriod: $period, referenceDate: $referenceDate)
                    .padding(.horizontal)

                // Idle time filter
                VStack(spacing: 4) {
                    Text("Min Idle Time")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Picker("Min Idle", selection: $minIdleHours) {
                        ForEach(idleOptions, id: \.self) { hours in
                            Text("\(hours)h").tag(hours)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.horizontal)

                if viewModel.isLoading && viewModel.data == nil {
                    ProgressView()
                        .padding(.top, 100)
                } else if let data = viewModel.data {
                    if let avg = data.avgLossPerHour {
                        HeroNumberView(
                            value: String(format: "%.2f%%", avg),
                            label: "Avg Loss / Hour"
                        )
                    }

                    if !data.points.isEmpty {
                        // Scatter chart
                        Chart(data.points) { point in
                            if let date = parseDate(point.date),
                               let loss = point.lossPerHour {
                                PointMark(
                                    x: .value("Date", date),
                                    y: .value("Loss/hr", loss)
                                )
                                .foregroundStyle(.orange.opacity(0.7))
                                .symbolSize(30)
                            }
                        }
                        .chartYAxisLabel("% / hr")
                        .frame(height: 250)
                        .padding(.horizontal)

                        // Stats
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            StatCardView(
                                value: "\(data.points.count)",
                                label: "Idle Sessions"
                            )
                            if let avg = data.avgLossPerHour {
                                StatCardView(
                                    value: String(format: "%.1f%%", avg * 24),
                                    label: "Avg Loss / Day"
                                )
                            }
                        }
                        .padding(.horizontal)

                        // Detailed table
                        VStack(spacing: 8) {
                            Text("Idle Sessions")
                                .font(.subheadline.weight(.medium))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)

                            ForEach(data.points) { point in
                                VStack(spacing: 6) {
                                    HStack {
                                        if let startDate = point.startDate {
                                            Text(formatDateTime(startDate))
                                                .font(.caption.weight(.medium))
                                        }
                                        Spacer()
                                        if let hours = point.durationHours {
                                            Text(formatIdleDuration(hours))
                                                .font(.caption.monospacedDigit())
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(durationColor(hours).opacity(0.2))
                                                .cornerRadius(4)
                                        }
                                    }

                                    HStack {
                                        // SoC range
                                        if let start = point.startLevel, let end = point.endLevel {
                                            Text("\(start)% → \(end)%")
                                                .font(.caption.monospacedDigit())
                                                .foregroundStyle(.secondary)
                                        }
                                        // Loss per hour
                                        if let loss = point.lossPerHour {
                                            Text(String(format: "%.2f%%/hr", loss))
                                                .font(.caption.monospacedDigit())
                                                .foregroundStyle(.orange)
                                        }
                                        Spacer()
                                        // Standby %
                                        if let standby = point.standbyPercentage {
                                            Text(String(format: "%.1f%% loss", standby))
                                                .font(.caption2)
                                                .foregroundStyle(standby > 5 ? .red : .secondary)
                                        }
                                        // Cold indicator
                                        if let temp = point.outsideTemp, temp < 0 {
                                            Image(systemName: "snowflake")
                                                .font(.caption2)
                                                .foregroundStyle(.blue)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                                Divider()
                                    .padding(.horizontal)
                            }
                        }
                    }

                    if data.points.isEmpty {
                        ContentUnavailableView(
                            "No Data",
                            systemImage: "moon.zzz",
                            description: Text("Vampire drain data will appear after idle periods > \(minIdleHours) hour(s).")
                        )
                    }
                } else if let error = viewModel.error {
                    ContentUnavailableView("Error", systemImage: "exclamationmark.triangle", description: Text(error))
                }
            }
            .padding()
        }
        .navigationTitle("Vampire Drain")
        .task { Task { await reload() } }
        .onChange(of: period) { Task { await reload() } }
        .onChange(of: referenceDate) { Task { await reload() } }
        .onChange(of: minIdleHours) { Task { await reload() } }
    }

    private func reload() async {
        let picker = PeriodPicker(selectedPeriod: $period, referenceDate: $referenceDate)
        let range = picker.dateRange
        await viewModel.load(carId: carId, from: range.from, to: range.to, minIdleHours: minIdleHours)
    }

    private func parseDate(_ str: String?) -> Date? {
        guard let str else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: str) ?? ISO8601DateFormatter().date(from: str)
    }

    private func formatDateTime(_ str: String) -> String {
        guard let date = parseDate(str) else { return str }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func formatIdleDuration(_ hours: Double) -> String {
        let h = Int(hours)
        let m = Int((hours - Double(h)) * 60)
        if h >= 24 {
            return "\(h / 24)d \(h % 24)h"
        }
        return "\(h)h \(m)m"
    }

    private func durationColor(_ hours: Double) -> Color {
        if hours >= 24 { return .red }
        if hours >= 8 { return .orange }
        return .green
    }
}
