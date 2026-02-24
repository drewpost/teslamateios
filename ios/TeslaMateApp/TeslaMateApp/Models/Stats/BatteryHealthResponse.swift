import Foundation

struct BatteryHealthResponse: Codable {
    let currentSoh: Double?
    let totalCharges: Int?
    let totalEnergyAdded: Double?
    let acEnergyKwh: Double?
    let dcEnergyKwh: Double?
    let usableCapacityKm: Double?
    let points: [BatteryHealthPoint]
}

struct BatteryHealthPoint: Codable, Identifiable {
    var id: String { date ?? UUID().uuidString }
    let date: String?
    let ratedRangeKm: Double?
    let batteryLevel: Int?
    let sohEstimate: Double?
}
