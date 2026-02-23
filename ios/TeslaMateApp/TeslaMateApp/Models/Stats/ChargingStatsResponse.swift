import Foundation

struct ChargingStatsResponse: Codable {
    let totals: ChargingTotals
    let buckets: [ChargingBucket]
}

struct ChargingTotals: Codable {
    let totalEnergyKwh: Double?
    let totalCost: Double?
    let totalSessions: Int?
    let avgEnergyKwh: Double?
    let acSessions: Int?
    let dcSessions: Int?
}

struct ChargingBucket: Codable, Identifiable {
    var id: String { period ?? UUID().uuidString }
    let period: String?
    let energyKwh: Double?
    let cost: Double?
    let sessions: Int?
    let acEnergyKwh: Double?
    let dcEnergyKwh: Double?
}

struct DCCurvePoint: Codable, Identifiable {
    var id: String { "\(batteryLevel ?? 0)_\(chargerPower ?? 0)" }
    let batteryLevel: Int?
    let chargerPower: Int?
    let chargeEnergyAdded: Double?
    let chargerVoltage: Int?
    let outsideTemp: Double?
}
