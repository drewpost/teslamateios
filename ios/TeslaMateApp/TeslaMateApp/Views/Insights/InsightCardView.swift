import SwiftUI

struct InsightCardView: View {
    let screen: InsightScreen

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: screen.icon)
                .font(.title2)
                .foregroundStyle(Color.accentColor)
            Text(screen.title)
                .font(.subheadline.weight(.medium))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 90)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
