import Foundation

@MainActor
@Observable
class VampireDrainViewModel {
    var data: VampireDrainResponse?
    var isLoading = false
    var error: String?

    func load(carId: Int, from: String? = nil, to: String? = nil, minIdleHours: Int? = nil) async {
        isLoading = true
        error = nil
        do {
            data = try await APIClient.shared.getVampireDrain(carId: carId, from: from, to: to, minIdleHours: minIdleHours)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}
