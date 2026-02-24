import Foundation

@MainActor
@Observable
class UpdatesViewModel {
    var entries: [UpdateEntry] = []
    var isLoading = false
    var error: String?

    func load(carId: Int) async {
        isLoading = true
        error = nil
        do {
            entries = try await APIClient.shared.getUpdates(carId: carId)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}
