import Foundation

@MainActor
@Observable
class VampireDrainViewModel {
    var data: VampireDrainResponse?
    var isLoading = false
    var error: String?

    func load(carId: Int) async {
        isLoading = true
        error = nil
        do {
            data = try await APIClient.shared.getVampireDrain(carId: carId)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}
