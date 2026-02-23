import Foundation

@MainActor
@Observable
class TimelineViewModel {
    var entries: [TimelineEntry] = []
    var isLoading = false
    var error: String?
    var page = 1
    var total = 0
    var hasMore: Bool { entries.count < total }

    func load(carId: Int) async {
        isLoading = true
        error = nil
        page = 1
        do {
            let response = try await APIClient.shared.getTimeline(carId: carId, page: 1, perPage: 50)
            entries = response.entries
            total = response.total
            page = 1
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func loadMore(carId: Int) async {
        guard hasMore && !isLoading else { return }
        isLoading = true
        let nextPage = page + 1
        do {
            let response = try await APIClient.shared.getTimeline(carId: carId, page: nextPage, perPage: 50)
            entries.append(contentsOf: response.entries)
            total = response.total
            page = nextPage
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}
