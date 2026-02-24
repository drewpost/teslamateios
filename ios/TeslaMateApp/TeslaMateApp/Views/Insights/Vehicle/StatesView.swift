import SwiftUI
import Charts

struct StatesView: View {
    let carId: Int
    @State private var viewModel = StatesViewModel()
    @State private var period: StatsPeriod = .week
    @State private var referenceDate = Date()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                PeriodPicker(selectedPeriod: $period, referenceDate: $referenceDate)
                    .padding(.horizontal)

                if viewModel.isLoading && viewModel.entries.isEmpty {
                    ProgressView()
                        .padding(.top, 100)
                } else if !viewModel.entries.isEmpty {
                    // Stat cards
                    let distribution = viewModel.stateDistribution
                    let totalMin = distribution.reduce(0) { $0 + $1.minutes }
                    let parkedMin = distribution.first(where: { $0.state == "asleep" || $0.state == "offline" })?.minutes ?? 0

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        if let last = viewModel.entries.last {
                            StatCardView(
                                value: (last.state ?? "unknown").capitalized,
                                label: "Current State"
                            )
                        }
                        if totalMin > 0 {
                            StatCardView(
                                value: "\(parkedMin * 100 / totalMin)%",
                                label: "Parked"
                            )
                        }
                    }
                    .padding(.horizontal)

                    // Donut chart of state distribution
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
                            "offline": Color.gray,
                            "driving": Color.blue,
                            "charging": Color.yellow,
                            "updating": Color.orange,
                            "suspended": Color.purple
                        ])
                        .frame(height: 250)
                        .padding(.horizontal)
                    }

                    // State timeline chart
                    if viewModel.entries.count > 1 {
                        Text("Timeline")
                            .font(.subheadline.weight(.medium))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)

                        Chart(viewModel.entries) { entry in
                            if let startDate = parseDate(entry.startDate),
                               let endDate = parseDate(entry.endDate) {
                                RectangleMark(
                                    xStart: .value("Start", startDate),
                                    xEnd: .value("End", endDate),
                                    y: .value("State", "")
                                )
                                .foregroundStyle(colorForState(entry.state ?? "unknown"))
                            }
                        }
                        .chartYAxis(.hidden)
                        .frame(height: 40)
                        .padding(.horizontal)

                        // Legend
                        let states = Array(Set(viewModel.entries.compactMap(\.state))).sorted()
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 4) {
                            ForEach(states, id: \.self) { state in
                                Label(state.capitalized, systemImage: "circle.fill")
                                    .font(.caption2)
                                    .foregroundStyle(colorForState(state))
                            }
                        }
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
        .task { Task { await reload() } }
        .onChange(of: period) { Task { await reload() } }
        .onChange(of: referenceDate) { Task { await reload() } }
    }

    private func reload() async {
        let picker = PeriodPicker(selectedPeriod: $period, referenceDate: $referenceDate)
        let range = picker.dateRange
        await viewModel.load(carId: carId, from: range.from, to: range.to)
    }

    private func colorForState(_ state: String) -> Color {
        switch state {
        case "asleep": return .indigo
        case "online": return .green
        case "offline": return .gray
        case "driving": return .blue
        case "charging": return .yellow
        case "updating": return .orange
        case "suspended": return .purple
        default: return .secondary
        }
    }

    private func formatDuration(_ minutes: Int) -> String {
        let d = minutes / 1440
        let h = (minutes % 1440) / 60
        if d > 0 { return "\(d)d \(h)h" }
        let m = minutes % 60
        return h > 0 ? "\(h)h \(m)m" : "\(m)m"
    }

    private func parseDate(_ str: String?) -> Date? {
        guard let str else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: str) ?? ISO8601DateFormatter().date(from: str)
    }
}
