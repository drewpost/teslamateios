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
                List(viewModel.entries) { entry in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(entry.version ?? "Unknown")
                                .font(.headline)
                            if let dateStr = entry.startDate {
                                Text(formatDate(dateStr))
                                    .font(.caption)
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
        .navigationTitle("Updates")
        .task {
            await viewModel.load(carId: carId)
        }
    }

    private func formatDate(_ str: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = isoFormatter.date(from: str) ?? ISO8601DateFormatter().date(from: str) else {
            return str
        }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
