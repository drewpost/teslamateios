import Foundation

struct MileageResponse: Codable {
    let currentOdometerKm: Double?
    let buckets: [MileageBucket]
}

struct MileageBucket: Codable, Identifiable {
    var id: String { period ?? UUID().uuidString }
    let period: String?
    let distanceKm: Double?
    let cumulativeKm: Double?
}
