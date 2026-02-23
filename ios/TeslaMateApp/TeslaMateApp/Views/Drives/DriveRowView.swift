import SwiftUI

struct DriveRowView: View {
    let drive: Drive
    @Environment(UnitPreference.self) private var unitPreference

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Route
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(drive.startDisplayName)
                        .font(.subheadline.weight(.medium))
                        .lineLimit(1)
                    Image(systemName: "arrow.down")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(drive.endDisplayName)
                        .font(.subheadline.weight(.medium))
                        .lineLimit(1)
                }
                Spacer()
            }

            // Stats
            HStack(spacing: 16) {
                if let distance = drive.distance {
                    Label(unitPreference.formatDistance(distance), systemImage: "road.lanes")
                }
                Label(drive.formattedDuration, systemImage: "clock")
                if let speedMax = drive.speedMax {
                    Label(unitPreference.formatSpeed(speedMax), systemImage: "gauge.with.dots.needle.67percent")
                }
            }
            .font(.caption)
            .foregroundColor(.secondary)

            // Date
            if let dateStr = drive.startDate {
                Text(formatDate(dateStr))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func formatDate(_ iso: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: iso) {
            let display = DateFormatter()
            display.dateStyle = .medium
            display.timeStyle = .short
            return display.string(from: date)
        }
        // Try without fractional seconds
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: iso) {
            let display = DateFormatter()
            display.dateStyle = .medium
            display.timeStyle = .short
            return display.string(from: date)
        }
        return iso
    }
}
