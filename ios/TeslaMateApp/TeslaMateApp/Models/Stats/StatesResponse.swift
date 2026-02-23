import Foundation

struct StateEntry: Codable, Identifiable {
    var id: String { "\(state ?? "")_\(startDate ?? "")" }
    let state: String?
    let startDate: String?
    let endDate: String?
    let durationMin: Int?
}
