import Foundation

struct StatisticsResponse: Codable {
    let totalDrives: Int?
    let totalCharges: Int?
    let totalDistanceKm: Double?
    let totalEnergyKwh: Double?
    let totalDurationMin: Int?
    let avgDriveDistanceKm: Double?
    let avgDriveEfficiency: Double?
    let avgChargeEnergy: Double?
}
