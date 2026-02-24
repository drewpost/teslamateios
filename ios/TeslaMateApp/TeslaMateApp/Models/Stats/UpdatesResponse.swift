import Foundation

struct UpdateEntry: Codable, Identifiable {
    var id: String { "\(version ?? "")_\(startDate ?? "")" }
    let version: String?
    let startDate: String?
    let endDate: String?
}
