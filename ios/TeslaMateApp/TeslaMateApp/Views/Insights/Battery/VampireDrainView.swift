import SwiftUI
import Charts

struct VampireDrainView: View {
    let carId: Int
    @State private var viewModel = VampireDrainViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
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
                        Chart(data.points) { point in
                            if let date = point.date.flatMap({ parseDate($0) }),
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

                        // Supporting stats
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
                    }

                    if data.points.isEmpty {
                        ContentUnavailableView(
                            "No Data",
                            systemImage: "moon.zzz",
                            description: Text("Vampire drain data will appear after idle periods > 1 hour.")
                        )
                    }
                } else if let error = viewModel.error {
                    ContentUnavailableView("Error", systemImage: "exclamationmark.triangle", description: Text(error))
                }
            }
            .padding()
        }
        .navigationTitle("Vampire Drain")
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
