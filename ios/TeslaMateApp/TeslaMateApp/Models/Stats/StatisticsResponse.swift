import Foundation

struct StatisticsResponse: Codable {
    let buckets: [StatisticsBucket]
}

struct StatisticsBucket: Codable, Identifiable {
    var id: String { period ?? UUID().uuidString }
    let period: String?
    let timeDrivenMin: Int?
    let distanceKm: Double?
    let avgTemp: Double?
    let avgSpeed: Double?
    let efficiencyWhKm: Double?
    let energyKwh: Double?
    let drives: Int?
    let charges: Int?
    let energyAddedKwh: Double?
    let totalCost: Double?
    let costPerKwh: Double?
    let costPer100km: Double?
}
