import SwiftUI

struct StatCardView: View {
    let value: String
    let label: String
    var icon: String? = nil

    var body: some View {
        VStack(spacing: 4) {
            if let icon {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(value)
                .font(.title3.bold())
                .monospacedDigit()
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}
