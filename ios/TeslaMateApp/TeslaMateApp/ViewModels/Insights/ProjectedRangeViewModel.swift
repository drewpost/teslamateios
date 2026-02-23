import Foundation

@MainActor
@Observable
class ProjectedRangeViewModel {
    var data: ProjectedRangeResponse?
    var isLoading = false
    var error: String?

    func load(carId: Int) async {
        isLoading = true
        error = nil
        do {
            data = try await APIClient.shared.getProjectedRange(carId: carId)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}
