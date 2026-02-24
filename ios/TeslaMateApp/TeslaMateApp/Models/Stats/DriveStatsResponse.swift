import Foundation

struct DriveStatsResponse: Codable {
    let totals: DriveTotals
    let buckets: [DriveBucket]
}

struct DriveTotals: Codable {
    let totalDrives: Int?
    let totalDistanceKm: Double?
    let totalDurationMin: Int?
    let totalEnergyKwh: Double?
    let avgSpeed: Double?
}

struct DriveBucket: Codable, Identifiable {
    var id: String { period ?? UUID().uuidString }
    let period: String?
    let count: Int?
    let distanceKm: Double?
    let durationMin: Int?
    let energyKwh: Double?
}
