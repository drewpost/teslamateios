import SwiftUI

struct TimelineView: View {
    let carId: Int
    @State private var viewModel = TimelineViewModel()
    @State private var filter: TimelineFilter = .all

    enum TimelineFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case drives = "Drives"
        case charges = "Charges"
        case updates = "Updates"
        var id: String { rawValue }
    }

    var filteredEntries: [TimelineEntry] {
        switch filter {
        case .all: return viewModel.entries
        case .drives: return viewModel.entries.filter { $0.type == "drive" }
        case .charges: return viewModel.entries.filter { $0.type == "charge" }
        case .updates: return viewModel.entries.filter { $0.type == "update" }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Filter pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(TimelineFilter.allCases) { f in
                        Button {
                            filter = f
                        } label: {
                            Text(f.rawValue)
                                .font(.subheadline.weight(filter == f ? .semibold : .regular))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                                .background(filter == f ? Color.accentColor : Color(.systemGray5))
                                .foregroundStyle(filter == f ? .white : .primary)
                                .cornerRadius(16)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }

            if viewModel.isLoading && viewModel.entries.isEmpty {
                Spacer()
                ProgressView()
                Spacer()
            } else if filteredEntries.isEmpty {
                Spacer()
                ContentUnavailableView("No Events", systemImage: "clock.arrow.circlepath", description: Text("Timeline events will appear here."))
                Spacer()
            } else {
                List {
                    ForEach(filteredEntries) { entry in
                        HStack(spacing: 12) {
                            Image(systemName: iconForType(entry.type ?? ""))
                                .foregroundStyle(colorForType(entry.type ?? ""))
                                .frame(width: 28)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.title ?? "")
                                    .font(.subheadline)
                                    .lineLimit(1)
                                HStack(spacing: 4) {
                                    if let subtitle = entry.subtitle {
                                        Text(subtitle)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    if let dateStr = entry.startDate {
                                        Text(formatRelativeDate(dateStr))
                                            .font(.caption)
                                            .foregroundStyle(.tertiary)
                                    }
                                }
                            }
                        }
                    }

                    if viewModel.hasMore {
                        Button("Load Earlier") {
                            Task { await viewModel.loadMore(carId: carId) }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Timeline")
        .task {
            await viewModel.load(carId: carId)
        }
    }

    private func iconForType(_ type: String) -> String {
        switch type {
        case "drive": return "car.fill"
        case "charge": return "bolt.fill"
        case "update": return "arrow.down.app.fill"
        default: return "circle.fill"
        }
    }

    private func colorForType(_ type: String) -> Color {
        switch type {
        case "drive": return .blue
        case "charge": return .green
        case "update": return .orange
        default: return .gray
        }
    }

    private func formatRelativeDate(_ str: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: str) ?? ISO8601DateFormatter().date(from: str) else {
            return str
        }
        let relative = RelativeDateTimeFormatter()
        relative.unitsStyle = .abbreviated
        return relative.localizedString(for: date, relativeTo: Date())
    }
}
