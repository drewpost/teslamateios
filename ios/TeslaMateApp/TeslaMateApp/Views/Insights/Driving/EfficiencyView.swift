import SwiftUI
import Charts

struct EfficiencyView: View {
    let carId: Int
    @State private var viewModel = EfficiencyViewModel()
    @Environment(UnitPreference.self) private var unitPreference

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
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

                    if !data.points.isEmpty {
                        // Efficiency vs Temperature
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
                        .chartXAxisLabel(unitPreference.useFahrenheit ? "°F" : "°C")
                        .chartYAxisLabel(unitPreference.useMiles ? "Wh/mi" : "Wh/km")
                        .frame(height: 250)
                        .padding(.horizontal)

                        Text("Efficiency vs. Temperature")
                            .font(.caption)
                            .foregroundStyle(.secondary)
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
        .task {
            await viewModel.load(carId: carId)
        }
    }
}
