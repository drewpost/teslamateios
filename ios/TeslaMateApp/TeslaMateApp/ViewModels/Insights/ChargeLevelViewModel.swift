import Foundation

@MainActor
@Observable
class ChargeLevelViewModel {
    var data: ChargeLevelResponse?
    var isLoading = false
    var error: String?

    func load(carId: Int) async {
        isLoading = true
        error = nil
        do {
            data = try await APIClient.shared.getChargeLevel(carId: carId)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}
