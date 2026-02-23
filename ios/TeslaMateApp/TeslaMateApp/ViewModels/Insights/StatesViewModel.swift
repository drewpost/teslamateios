import Foundation

@MainActor
@Observable
class StatesViewModel {
    var entries: [StateEntry] = []
    var isLoading = false
    var error: String?

    func load(carId: Int, from: String? = nil, to: String? = nil) async {
        isLoading = true
        error = nil
        do {
            entries = try await APIClient.shared.getStates(carId: carId, from: from, to: to)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    var stateDistribution: [(state: String, minutes: Int)] {
        var grouped: [String: Int] = [:]
        for entry in entries {
            let state = entry.state ?? "unknown"
            grouped[state, default: 0] += entry.durationMin ?? 0
        }
        return grouped.map { (state: $0.key, minutes: $0.value) }
            .sorted { $0.minutes > $1.minutes }
    }
}
