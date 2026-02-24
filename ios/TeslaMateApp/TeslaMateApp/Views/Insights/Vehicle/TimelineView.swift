import SwiftUI

struct TimelineView: View {
    let carId: Int
    @State private var viewModel = TimelineViewModel()
    @State private var filter: TimelineFilter = .all
    @State private var searchText = ""
    @Environment(UnitPreference.self) private var unitPreference

    enum TimelineFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case drives = "Drives"
        case charges = "Charges"
        case parking = "Parking"
        case updates = "Updates"
        var id: String { rawValue }
    }

    var filteredEntries: [TimelineEntry] {
        switch filter {
        case .all: return viewModel.entries
        case .drives: return viewModel.entries.filter { $0.type == "drive" }
        case .charges: return viewModel.entries.filter { $0.type == "charge" }
        case .parking: return viewModel.entries.filter { $0.type == "parking" }
        case .updates: return viewModel.entries.filter { $0.type == "update" }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search addresses...", text: $searchText)
                    .textFieldStyle(.plain)
                    .onSubmit {
                        Task { await reload() }
                    }
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        Task { await reload() }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(10)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
            .padding(.top, 8)

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
                        VStack(alignment: .leading, spacing: 4) {
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

                            // Detail metrics row
                            detailRow(entry)
                        }
                    }

                    if viewModel.hasMore {
                        Button("Load Earlier") {
                            Task { await viewModel.loadMore(carId: carId, search: searchText.isEmpty ? nil : searchText) }
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
            await reload()
        }
    }

    private func reload() async {
        await viewModel.load(carId: carId, search: searchText.isEmpty ? nil : searchText)
    }

    @ViewBuilder
    private func detailRow(_ entry: TimelineEntry) -> some View {
        let type = entry.type ?? ""
        if type == "drive" {
            HStack(spacing: 12) {
                if let dist = entry.distanceKm {
                    Label(unitPreference.formatDistanceShort(dist), systemImage: "road.lanes")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                if let startSoc = entry.startSoc, let endSoc = entry.endSoc {
                    Text("\(startSoc)% → \(endSoc)%")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                if let temp = entry.outsideTemp {
                    Label(unitPreference.formatTemperature(temp), systemImage: "thermometer")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.leading, 40)
        } else if type == "charge" {
            HStack(spacing: 12) {
                if let energy = entry.energyAddedKwh {
                    Label(String(format: "%.1f kWh", energy), systemImage: "bolt.fill")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                if let startSoc = entry.startSoc, let endSoc = entry.endSoc {
                    Text("\(startSoc)% → \(endSoc)%")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                if let cost = entry.cost, cost > 0 {
                    Label(String(format: "$%.2f", cost), systemImage: "dollarsign.circle")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.leading, 40)
        }
    }

    private func iconForType(_ type: String) -> String {
        switch type {
        case "drive": return "car.fill"
        case "charge": return "bolt.fill"
        case "update": return "arrow.down.app.fill"
        case "parking": return "parkingsign.circle.fill"
        default: return "circle.fill"
        }
    }

    private func colorForType(_ type: String) -> Color {
        switch type {
        case "drive": return .blue
        case "charge": return .green
        case "update": return .orange
        case "parking": return .gray
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
