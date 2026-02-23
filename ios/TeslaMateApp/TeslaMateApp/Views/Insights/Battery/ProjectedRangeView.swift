import SwiftUI
import Charts

struct ProjectedRangeView: View {
    let carId: Int
    @State private var viewModel = ProjectedRangeViewModel()
    @Environment(UnitPreference.self) private var unitPreference

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
                        projectedRangeChart(data.points)
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

    private func projectedRangeChart(_ points: [ProjectedRangePoint]) -> some View {
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

    private func parseDate(_ str: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: str) ?? ISO8601DateFormatter().date(from: str)
    }
}
