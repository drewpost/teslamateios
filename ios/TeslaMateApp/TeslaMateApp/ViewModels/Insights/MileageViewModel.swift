import Foundation

@MainActor
@Observable
class MileageViewModel {
    var data: MileageResponse?
    var isLoading = false
    var error: String?

    func load(carId: Int, from: String? = nil, to: String? = nil, bucket: String? = nil) async {
        isLoading = true
        error = nil
        do {
            data = try await APIClient.shared.getMileage(carId: carId, from: from, to: to, bucket: bucket)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}
