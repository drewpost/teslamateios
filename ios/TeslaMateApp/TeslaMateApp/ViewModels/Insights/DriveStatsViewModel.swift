import Foundation

@Observable
class DriveStatsViewModel {
    var data: DriveStatsResponse?
    var isLoading = false
    var error: String?

    func load(carId: Int, from: String? = nil, to: String? = nil, bucket: String? = nil) async {
        isLoading = true
        error = nil
        do {
            data = try await APIClient.shared.getDriveStats(carId: carId, from: from, to: to, bucket: bucket)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}
