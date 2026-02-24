import Foundation

@MainActor
@Observable
class BatteryHealthViewModel {
    var data: BatteryHealthResponse?
    var isLoading = false
    var error: String?

    func load(carId: Int) async {
        isLoading = true
        error = nil
        do {
            data = try await APIClient.shared.getBatteryHealth(carId: carId)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}
