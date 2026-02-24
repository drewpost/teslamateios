import Foundation

struct VampireDrainResponse: Codable {
    let avgLossPerHour: Double?
    let points: [VampireDrainPoint]
}

struct VampireDrainPoint: Codable, Identifiable {
    var id: String { date ?? UUID().uuidString }
    let date: String?
    let startDate: String?
    let endDate: String?
    let startLevel: Int?
    let endLevel: Int?
    let durationHours: Double?
    let lossPerHour: Double?
    let startRangeKm: Double?
    let endRangeKm: Double?
    let rangeDiffKm: Double?
    let avgPowerWatts: Double?
    let standbyPercentage: Double?
    let outsideTemp: Double?
}
