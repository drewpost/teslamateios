import SwiftUI
import Charts

struct ChargeLevelView: View {
    let carId: Int
    @State private var viewModel = ChargeLevelViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
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

                    if !data.points.isEmpty {
                        Chart(data.points) { point in
                            if let date = point.date.flatMap({ parseDate($0) }),
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
                        }
                        .chartYScale(domain: 0...100)
                        .chartYAxisLabel("%")
                        .frame(height: 250)
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
