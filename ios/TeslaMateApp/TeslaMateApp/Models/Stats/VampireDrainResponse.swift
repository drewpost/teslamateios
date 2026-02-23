import Foundation

struct VampireDrainResponse: Codable {
    let avgLossPerHour: Double?
    let points: [VampireDrainPoint]
}

struct VampireDrainPoint: Codable, Identifiable {
    var id: String { date ?? UUID().uuidString }
    let date: String?
    let startLevel: Int?
    let endLevel: Int?
    let durationHours: Double?
    let lossPerHour: Double?
}
