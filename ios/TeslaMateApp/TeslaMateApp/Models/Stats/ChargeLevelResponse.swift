import Foundation

struct ChargeLevelResponse: Codable {
    let currentLevel: Int?
    let points: [ChargeLevelPoint]
}

struct ChargeLevelPoint: Codable, Identifiable {
    var id: String { date ?? UUID().uuidString }
    let date: String?
    let batteryLevel: Int?
    let usableBatteryLevel: Int?
}
