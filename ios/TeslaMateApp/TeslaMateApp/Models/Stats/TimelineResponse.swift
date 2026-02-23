import Foundation

struct TimelineResponse: Codable {
    let entries: [TimelineEntry]
    let page: Int
    let perPage: Int
    let total: Int
}

struct TimelineEntry: Codable, Identifiable {
    var id: String { "\(type ?? "")_\(entryId ?? 0)" }
    let type: String?
    let entryId: Int?
    let startDate: String?
    let endDate: String?
    let title: String?
    let subtitle: String?

    enum CodingKeys: String, CodingKey {
        case type
        case entryId = "id"
        case startDate
        case endDate
        case title
        case subtitle
    }
}
