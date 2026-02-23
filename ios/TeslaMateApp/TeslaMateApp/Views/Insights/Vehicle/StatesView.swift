import SwiftUI
import Charts

struct StatesView: View {
    let carId: Int
    @State private var viewModel = StatesViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if viewModel.isLoading && viewModel.entries.isEmpty {
                    ProgressView()
                        .padding(.top, 100)
                } else if !viewModel.entries.isEmpty {
                    // Donut chart of state distribution
                    let distribution = viewModel.stateDistribution
                    if !distribution.isEmpty {
                        Chart(distribution, id: \.state) { item in
                            SectorMark(
                                angle: .value("Minutes", item.minutes),
                                innerRadius: .ratio(0.5),
                                angularInset: 1.5
                            )
                            .foregroundStyle(by: .value("State", item.state))
                        }
                        .chartForegroundStyleScale([
                            "asleep": Color.indigo,
                            "online": Color.green,
                            "offline": Color.gray
                        ])
                        .frame(height: 250)
                        .padding(.horizontal)
                    }

                    // State breakdown
                    ForEach(distribution, id: \.state) { item in
                        HStack {
                            Circle()
                                .fill(colorForState(item.state))
                                .frame(width: 12, height: 12)
                            Text(item.state.capitalized)
                                .font(.subheadline)
                            Spacer()
                            Text(formatDuration(item.minutes))
                                .font(.subheadline.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal)
                    }
                } else if let error = viewModel.error {
                    ContentUnavailableView("Error", systemImage: "exclamationmark.triangle", description: Text(error))
                } else {
                    ContentUnavailableView("No Data", systemImage: "circle.grid.3x3", description: Text("State data will appear here."))
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("States")
        .task {
            await viewModel.load(carId: carId)
        }
    }

    private func colorForState(_ state: String) -> Color {
        switch state {
        case "asleep": return .indigo
        case "online": return .green
        case "offline": return .gray
        default: return .blue
        }
    }

    private func formatDuration(_ minutes: Int) -> String {
        let d = minutes / 1440
        let h = (minutes % 1440) / 60
        if d > 0 { return "\(d)d \(h)h" }
        let m = minutes % 60
        return h > 0 ? "\(h)h \(m)m" : "\(m)m"
    }
}
