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

    func load(carId: Int, from: String? = nil, to: String? = nil, search: String? = nil) async {
        isLoading = true
        error = nil
        page = 1
        do {
            let response = try await APIClient.shared.getTimeline(carId: carId, from: from, to: to, page: 1, perPage: 50, search: search)
            entries = response.entries
            total = response.total
            page = 1
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func loadMore(carId: Int, from: String? = nil, to: String? = nil, search: String? = nil) async {
        guard hasMore && !isLoading else { return }
        isLoading = true
        let nextPage = page + 1
        do {
            let response = try await APIClient.shared.getTimeline(carId: carId, from: from, to: to, page: nextPage, perPage: 50, search: search)
            entries.append(contentsOf: response.entries)
            total = response.total
            page = nextPage
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}
