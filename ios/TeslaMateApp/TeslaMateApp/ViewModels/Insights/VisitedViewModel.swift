import Foundation

@MainActor
@Observable
class VisitedViewModel {
    var heatmapPoints: [HeatmapPoint] = []
    var routes: [VisitedRoute] = []
    var places: [VisitedPlace] = []
    var driveStats: DriveStatsResponse?
    var chargingStats: ChargingStatsResponse?
    var isLoading = false
    var error: String?

    enum VisitedMode: String, CaseIterable, Identifiable {
        case heat = "Heat"
        case routes = "Routes"
        case places = "Places"
        var id: String { rawValue }
    }

    func load(carId: Int, from: String? = nil, to: String? = nil) async {
        isLoading = true
        error = nil
        do {
            async let h = APIClient.shared.getVisitedHeatmap(carId: carId, from: from, to: to)
            async let r = APIClient.shared.getVisitedRoutes(carId: carId, from: from, to: to)
            async let p = APIClient.shared.getVisitedPlaces(carId: carId, from: from, to: to)
            async let ds = APIClient.shared.getDriveStats(carId: carId, from: from, to: to)
            async let cs = APIClient.shared.getChargingStats(carId: carId, from: from, to: to)
            heatmapPoints = try await h
            routes = try await r
            places = try await p
            driveStats = try await ds
            chargingStats = try await cs
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}
