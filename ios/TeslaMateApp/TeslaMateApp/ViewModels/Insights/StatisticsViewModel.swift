import Foundation

@MainActor
@Observable
class StatisticsViewModel {
    var driveStats: DriveStatsResponse?
    var chargingStats: ChargingStatsResponse?
    var isLoading = false
    var error: String?

    func load(carId: Int) async {
        isLoading = true
        error = nil
        do {
            async let d = APIClient.shared.getDriveStats(carId: carId)
            async let c = APIClient.shared.getChargingStats(carId: carId)
            driveStats = try await d
            chargingStats = try await c
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}
