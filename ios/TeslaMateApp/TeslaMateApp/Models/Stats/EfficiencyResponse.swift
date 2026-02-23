import Foundation

struct EfficiencyResponse: Codable {
    let avgEfficiency: Double?
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
