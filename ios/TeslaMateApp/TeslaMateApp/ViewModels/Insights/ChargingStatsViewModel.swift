import Foundation

@MainActor
@Observable
class ChargingStatsViewModel {
    var data: ChargingStatsResponse?
    var dcCurve: [DCCurvePoint] = []
    var topStations: [TopChargingStation] = []
    var isLoading = false
    var error: String?

    func load(carId: Int, from: String? = nil, to: String? = nil, bucket: String? = nil) async {
        isLoading = true
        error = nil
        do {
            async let stats = APIClient.shared.getChargingStats(carId: carId, from: from, to: to, bucket: bucket)
            async let curve = APIClient.shared.getDcCurve(carId: carId, from: from, to: to)
            async let stations = APIClient.shared.getTopChargingStations(carId: carId, from: from, to: to)
            data = try await stats
            dcCurve = try await curve
            topStations = try await stations
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}
