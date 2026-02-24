import Foundation

struct TimelineResponse: Codable {
    let entries: [TimelineEntry]
    let page: Int
    let perPage: Int
    let total: Int
}

struct TimelineEntry: Codable, Identifiable {
    var id: String { "\(type ?? "")_\(entryId ?? 0)_\(startDate ?? "")" }
    let type: String?
    let entryId: Int?
    let startDate: String?
    let endDate: String?
    let title: String?
    let subtitle: String?
    let distanceKm: Double?
    let energyKwh: Double?
    let energyAddedKwh: Double?
    let cost: Double?
    let address: String?
    let startSoc: Int?
    let endSoc: Int?
    let outsideTemp: Double?

    enum CodingKeys: String, CodingKey {
        case type
        case entryId = "id"
        case startDate
        case endDate
        case title
        case subtitle
        case distanceKm
        case energyKwh
        case energyAddedKwh
        case cost
        case address
        case startSoc
        case endSoc
        case outsideTemp
    }
}
