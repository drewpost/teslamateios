import Foundation

struct EfficiencyResponse: Codable {
    let avgEfficiency: Double?
    let ratedEfficiency: Double?
    let netConsumptionWhKm: Double?
    let temperatureBuckets: [TemperatureBucket]?
    let points: [EfficiencyPoint]
}

struct EfficiencyPoint: Codable, Identifiable {
    var id: String { date ?? UUID().uuidString }
    let date: String?
    let distanceKm: Double?
    let energyKwh: Double?
    let efficiencyWhKm: Double?
    let outsideTempAvg: Double?
    let speedAvg: Double?
}

struct TemperatureBucket: Codable, Identifiable {
    var id: Double { tempBucket ?? 0 }
    let tempBucket: Double?
    let count: Int?
    let avgEfficiency: Double?
    let avgSpeed: Double?
    let totalDistanceKm: Double?
}
