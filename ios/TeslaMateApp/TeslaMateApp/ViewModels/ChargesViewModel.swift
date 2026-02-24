import Foundation

@MainActor
@Observable
class ChargesViewModel {
    var charges: [ChargingSession] = []
    var isLoading = false
    var error: String?
    var hasMore = true

    private var currentPage = 1
    private let perPage = 20
    private var loadTask: Task<Void, Never>?

    /// Fire-and-forget load (unstructured task, survives view lifecycle changes)
    func load(carId: Int) {
        loadTask?.cancel()
        loadTask = Task { await loadCharges(carId: carId) }
    }

    /// Fire-and-forget load more
    func loadMoreIfNeeded(carId: Int) {
        guard !isLoading, hasMore else { return }
        Task { await loadMore(carId: carId) }
    }

    func loadCharges(carId: Int) async {
        guard !isLoading else { return }

        isLoading = true
        currentPage = 1
        error = nil

        do {
            let response = try await APIClient.shared.getCharges(carId: carId, page: 1, perPage: perPage)
            if !Task.isCancelled {
                self.charges = response.data
                self.hasMore = response.data.count >= self.perPage
                self.isLoading = false
            }
        } catch is CancellationError {
            // Task was cancelled, don't update state
        } catch {
            self.error = error.localizedDescription
            self.isLoading = false
        }
    }

    func loadMore(carId: Int) async {
        guard !isLoading, hasMore else { return }

        isLoading = true
        currentPage += 1

        do {
            let response = try await APIClient.shared.getCharges(carId: carId, page: currentPage, perPage: perPage)
            if !Task.isCancelled {
                self.charges.append(contentsOf: response.data)
                self.hasMore = response.data.count >= self.perPage
                self.isLoading = false
            }
        } catch is CancellationError {
            self.currentPage -= 1
        } catch {
            self.currentPage -= 1
            self.error = error.localizedDescription
            self.isLoading = false
        }
    }
}
