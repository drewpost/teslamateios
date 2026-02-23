import Foundation

@MainActor
@Observable
class ChargingStatsViewModel {
    var data: ChargingStatsResponse?
    var isLoading = false
    var error: String?

    func load(carId: Int, from: String? = nil, to: String? = nil, bucket: String? = nil) async {
        isLoading = true
        error = nil
        do {
            data = try await APIClient.shared.getChargingStats(carId: carId, from: from, to: to, bucket: bucket)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}
