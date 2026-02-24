import SwiftUI
import Charts

struct ProjectedRangeView: View {
    let carId: Int
    @State private var viewModel = ProjectedRangeViewModel()
    @State private var chartMode: ChartMode = .overTime
    @Environment(UnitPreference.self) private var unitPreference

    enum ChartMode: String, CaseIterable, Identifiable {
        case overTime = "Over Time"
        case vsMileage = "vs Mileage"
        case vsTemperature = "vs Temperature"
        var id: String { rawValue }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if viewModel.isLoading && viewModel.data == nil {
                    ProgressView()
                        .padding(.top, 100)
                } else if let data = viewModel.data {
                    if let latest = data.points.last, let range = latest.ratedRangeKm {
                        HeroNumberView(
                            value: unitPreference.formatRange(range),
                            label: "Latest Rated Range at 100%"
                        )
                    }

                    if !data.points.isEmpty {
                        Picker("Chart Mode", selection: $chartMode) {
                            ForEach(ChartMode.allCases) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)

                        switch chartMode {
                        case .overTime:
                            overTimeChart(data.points)
                        case .vsMileage:
                            vsMileageChart(data.points)
                        case .vsTemperature:
                            vsTemperatureChart(data.points)
                        }
                    }

                    if data.points.isEmpty {
                        ContentUnavailableView(
                            "No Data",
                            systemImage: "arrow.left.and.right",
                            description: Text("Charge to 100% to see projected range over time.")
                        )
                    }
                } else if let error = viewModel.error {
                    ContentUnavailableView("Error", systemImage: "exclamationmark.triangle", description: Text(error))
                }
            }
            .padding()
        }
        .navigationTitle("Projected Range")
        .task {
            await viewModel.load(carId: carId)
        }
    }

    // MARK: - Over Time Chart

    private func overTimeChart(_ points: [ProjectedRangePoint]) -> some View {
        let chartData: [(date: Date, value: Double, series: String)] = points.flatMap { point -> [(Date, Double, String)] in
            guard let dateStr = point.date, let date = parseDate(dateStr) else { return [] }
            var result: [(Date, Double, String)] = []
            if let rated = point.ratedRangeKm {
                let v = unitPreference.useMiles ? rated * 0.621371 : rated
                result.append((date, v, "Rated"))
            }
            if let ideal = point.idealRangeKm {
                let v = unitPreference.useMiles ? ideal * 0.621371 : ideal
                result.append((date, v, "Ideal"))
            }
            return result
        }

        return Chart(chartData, id: \.date) { item in
            LineMark(
                x: .value("Date", item.date),
                y: .value("Range", item.value)
            )
            .foregroundStyle(by: .value("Series", item.series))
            .interpolationMethod(.stepCenter)
        }
        .chartYAxisLabel(unitPreference.useMiles ? "Miles" : "km")
        .chartForegroundStyleScale([
            "Rated": Color.blue,
            "Ideal": Color.green
        ])
        .frame(height: 250)
        .padding(.horizontal)
    }

    // MARK: - vs Mileage Chart

    private func vsMileageChart(_ points: [ProjectedRangePoint]) -> some View {
        let filtered = points.filter { $0.odometerKm != nil && $0.ratedRangeKm != nil }

        return Group {
            if filtered.isEmpty {
                ContentUnavailableView("No Odometer Data", systemImage: "speedometer", description: Text("Odometer data not available for these charges."))
            } else {
                Chart(filtered) { point in
                    if let odo = point.odometerKm, let range = point.ratedRangeKm {
                        let x = unitPreference.useMiles ? odo * 0.621371 : odo
                        let y = unitPreference.useMiles ? range * 0.621371 : range
                        PointMark(
                            x: .value("Odometer", x),
                            y: .value("Range", y)
                        )
                        .foregroundStyle(.blue.opacity(0.6))
                        .symbolSize(20)
                    }
                }
                .chartXAxisLabel(unitPreference.useMiles ? "Miles" : "km")
                .chartYAxisLabel(unitPreference.useMiles ? "Miles" : "km")
                .frame(height: 250)
                .padding(.horizontal)
            }
        }
    }

    // MARK: - vs Temperature Chart

    private func vsTemperatureChart(_ points: [ProjectedRangePoint]) -> some View {
        let filtered = points.filter { $0.outsideTemp != nil && $0.ratedRangeKm != nil }

        return Group {
            if filtered.isEmpty {
                ContentUnavailableView("No Temperature Data", systemImage: "thermometer", description: Text("Temperature data not available for these charges."))
            } else {
                Chart(filtered) { point in
                    if let temp = point.outsideTemp, let range = point.ratedRangeKm {
                        let x = unitPreference.useFahrenheit ? temp * 9.0 / 5.0 + 32.0 : temp
                        let y = unitPreference.useMiles ? range * 0.621371 : range
                        PointMark(
                            x: .value("Temperature", x),
                            y: .value("Range", y)
                        )
                        .foregroundStyle(.orange.opacity(0.6))
                        .symbolSize(20)
                    }
                }
                .chartXAxisLabel(unitPreference.temperatureUnit)
                .chartYAxisLabel(unitPreference.useMiles ? "Miles" : "km")
                .frame(height: 250)
                .padding(.horizontal)
            }
        }
    }

    private func parseDate(_ str: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: str) ?? ISO8601DateFormatter().date(from: str)
    }
}
