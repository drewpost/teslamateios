import Foundation

struct ProjectedRangeResponse: Codable {
    let points: [ProjectedRangePoint]
}

struct ProjectedRangePoint: Codable, Identifiable {
    var id: String { date ?? UUID().uuidString }
    let date: String?
    let ratedRangeKm: Double?
    let idealRangeKm: Double?
    let batteryLevel: Int?
}
