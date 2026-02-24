import Foundation

@MainActor
@Observable
class ChargeLevelViewModel {
    var data: ChargeLevelResponse?
    var isLoading = false
    var error: String?

    func load(carId: Int, from: String? = nil, to: String? = nil) async {
        isLoading = true
        error = nil
        do {
            data = try await APIClient.shared.getChargeLevel(carId: carId, from: from, to: to)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}
