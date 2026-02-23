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

                    if !data.points.isEmpty {
                        Chart(data.points) { point in
                            if let date = point.date.flatMap({ parseDate($0) }),
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

    private func parseDate(_ str: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: str) ?? ISO8601DateFormatter().date(from: str)
    }
}
