import SwiftUI
import Charts

struct ChargeLevelView: View {
    let carId: Int
    @State private var viewModel = ChargeLevelViewModel()
    @State private var period: StatsPeriod = .month
    @State private var referenceDate = Date()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                PeriodPicker(selectedPeriod: $period, referenceDate: $referenceDate)
                    .padding(.horizontal)

                if viewModel.isLoading && viewModel.data == nil {
                    ProgressView()
                        .padding(.top, 100)
                } else if let data = viewModel.data {
                    if let level = data.currentLevel {
                        HeroNumberView(
                            value: "\(level)%",
                            label: "Current Level"
                        )
                    }

                    // Stats bar
                    if !data.points.isEmpty {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            StatCardView(
                                value: "\(avgSoC(data.points))%",
                                label: "Avg SoC"
                            )
                            StatCardView(
                                value: "\(timeAbovePercent(data.points, threshold: 90))%",
                                label: "Time >90%"
                            )
                            StatCardView(
                                value: "\(timeBelowPercent(data.points, threshold: 20))%",
                                label: "Time <20%"
                            )
                        }
                        .padding(.horizontal)
                    }

                    if !data.points.isEmpty {
                        Chart {
                            // Low threshold
                            RuleMark(y: .value("Low", 20))
                                .foregroundStyle(.red)
                                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
                                .annotation(position: .trailing, alignment: .leading) {
                                    Text("20%")
                                        .font(.caption2)
                                        .foregroundStyle(.red)
                                }

                            // High threshold
                            RuleMark(y: .value("High", 80))
                                .foregroundStyle(.yellow)
                                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
                                .annotation(position: .trailing, alignment: .leading) {
                                    Text("80%")
                                        .font(.caption2)
                                        .foregroundStyle(.yellow)
                                }

                            ForEach(data.points) { point in
                                if let date = parseDate(point.date),
                                   let level = point.batteryLevel {
                                    AreaMark(
                                        x: .value("Date", date),
                                        y: .value("Level", level)
                                    )
                                    .foregroundStyle(.green.opacity(0.3))

                                    LineMark(
                                        x: .value("Date", date),
                                        y: .value("Level", level)
                                    )
                                    .foregroundStyle(.green)
                                }

                                if let date = parseDate(point.date),
                                   let usable = point.usableBatteryLevel {
                                    LineMark(
                                        x: .value("Date", date),
                                        y: .value("Usable", usable)
                                    )
                                    .foregroundStyle(.orange)
                                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 2]))
                                }
                            }
                        }
                        .chartYScale(domain: 0...100)
                        .chartYAxisLabel("%")
                        .frame(height: 250)
                        .padding(.horizontal)

                        // Legend
                        HStack(spacing: 16) {
                            Label("Battery", systemImage: "circle.fill")
                                .font(.caption)
                                .foregroundStyle(.green)
                            Label("Usable", systemImage: "circle.fill")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                        .padding(.horizontal)
                    }

                    if data.points.isEmpty {
                        ContentUnavailableView(
                            "No Data",
                            systemImage: "battery.50percent",
                            description: Text("Battery level history will appear here.")
                        )
                    }
                } else if let error = viewModel.error {
                    ContentUnavailableView("Error", systemImage: "exclamationmark.triangle", description: Text(error))
                }
            }
            .padding()
        }
        .navigationTitle("Charge Level")
        .task { Task { await reload() } }
        .onChange(of: period) { Task { await reload() } }
        .onChange(of: referenceDate) { Task { await reload() } }
    }

    private func reload() async {
        let picker = PeriodPicker(selectedPeriod: $period, referenceDate: $referenceDate)
        let range = picker.dateRange
        await viewModel.load(carId: carId, from: range.from, to: range.to)
    }

    // MARK: - Stats Computations

    private func avgSoC(_ points: [ChargeLevelPoint]) -> Int {
        let levels = points.compactMap(\.batteryLevel)
        guard !levels.isEmpty else { return 0 }
        return levels.reduce(0, +) / levels.count
    }

    private func timeAbovePercent(_ points: [ChargeLevelPoint], threshold: Int) -> Int {
        let levels = points.compactMap(\.batteryLevel)
        guard !levels.isEmpty else { return 0 }
        let above = levels.filter { $0 > threshold }.count
        return Int(Double(above) / Double(levels.count) * 100)
    }

    private func timeBelowPercent(_ points: [ChargeLevelPoint], threshold: Int) -> Int {
        let levels = points.compactMap(\.batteryLevel)
        guard !levels.isEmpty else { return 0 }
        let below = levels.filter { $0 < threshold }.count
        return Int(Double(below) / Double(levels.count) * 100)
    }

    private func parseDate(_ str: String?) -> Date? {
        guard let str else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: str) ?? ISO8601DateFormatter().date(from: str)
    }
}
