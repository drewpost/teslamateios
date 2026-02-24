import SwiftUI

struct UpdatesView: View {
    let carId: Int
    @State private var viewModel = UpdatesViewModel()

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.entries.isEmpty {
                ProgressView()
            } else if viewModel.entries.isEmpty {
                ContentUnavailableView("No Updates", systemImage: "arrow.down.app", description: Text("Software update history will appear here."))
            } else {
                List {
                    Section {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            StatCardView(
                                value: "\(viewModel.entries.count)",
                                label: "Updates"
                            )
                            StatCardView(
                                value: medianDaysBetween,
                                label: "Median Days Between"
                            )
                            StatCardView(
                                value: avgInstallDuration,
                                label: "Avg Install"
                            )
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .padding(.vertical, 4)
                    }

                    Section {
                        ForEach(Array(viewModel.entries.enumerated()), id: \.element.id) { index, entry in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    if let version = entry.version {
                                        Button {
                                            openReleaseNotes(version: version)
                                        } label: {
                                            HStack(spacing: 4) {
                                                Text(version)
                                                    .font(.headline)
                                                Image(systemName: "arrow.up.right.square")
                                                    .font(.caption)
                                            }
                                        }
                                    } else {
                                        Text("Unknown")
                                            .font(.headline)
                                    }
                                    HStack(spacing: 8) {
                                        if let dateStr = entry.startDate {
                                            Text(formatDate(dateStr))
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        if let days = daysSincePrevious(index: index) {
                                            Text("\(days)d since previous")
                                                .font(.caption2)
                                                .foregroundStyle(.tertiary)
                                        }
                                    }
                                    if let duration = installDuration(entry: entry) {
                                        Text("Install: \(duration)")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Updates")
        .task {
            await viewModel.load(carId: carId)
        }
    }

    // MARK: - Computed Stats

    private var medianDaysBetween: String {
        let gaps = dayGaps()
        guard !gaps.isEmpty else { return "--" }
        let sorted = gaps.sorted()
        let median = sorted[sorted.count / 2]
        return "\(median)d"
    }

    private var avgInstallDuration: String {
        let durations = viewModel.entries.compactMap { installMinutes(entry: $0) }
        guard !durations.isEmpty else { return "--" }
        let avg = durations.reduce(0, +) / durations.count
        if avg >= 60 {
            return "\(avg / 60)h \(avg % 60)m"
        }
        return "\(avg)m"
    }

    // MARK: - Helpers

    private func daysSincePrevious(index: Int) -> Int? {
        let entries = viewModel.entries
        guard index + 1 < entries.count,
              let currentDate = parseDate(entries[index].startDate),
              let previousDate = parseDate(entries[index + 1].startDate) else { return nil }
        return Calendar.current.dateComponents([.day], from: previousDate, to: currentDate).day
    }

    private func dayGaps() -> [Int] {
        let entries = viewModel.entries
        guard entries.count > 1 else { return [] }
        var gaps: [Int] = []
        for i in 0..<(entries.count - 1) {
            if let days = daysSincePrevious(index: i) {
                gaps.append(days)
            }
        }
        return gaps
    }

    private func installMinutes(entry: UpdateEntry) -> Int? {
        guard let start = parseDate(entry.startDate),
              let end = parseDate(entry.endDate) else { return nil }
        let interval = end.timeIntervalSince(start)
        return max(0, Int(interval / 60))
    }

    private func installDuration(entry: UpdateEntry) -> String? {
        guard let minutes = installMinutes(entry: entry), minutes > 0 else { return nil }
        if minutes >= 60 {
            return "\(minutes / 60)h \(minutes % 60)m"
        }
        return "\(minutes)m"
    }

    private func openReleaseNotes(version: String) {
        let cleanVersion = version.replacingOccurrences(of: " ", with: "-").lowercased()
        if let url = URL(string: "https://www.notateslaapp.com/software-updates/version/\(cleanVersion)") {
            UIApplication.shared.open(url)
        }
    }

    private func parseDate(_ str: String?) -> Date? {
        guard let str else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: str) ?? ISO8601DateFormatter().date(from: str)
    }

    private func formatDate(_ str: String) -> String {
        guard let date = parseDate(str) else { return str }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
