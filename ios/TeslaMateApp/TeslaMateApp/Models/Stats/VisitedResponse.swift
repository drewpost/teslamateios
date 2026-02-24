import Foundation

struct HeatmapPoint: Codable, Identifiable {
    var id: String { "\(latitude ?? 0)_\(longitude ?? 0)" }
    let latitude: Double?
    let longitude: Double?
    let count: Int?
}

struct VisitedRoute: Codable, Identifiable {
    var id: Int { driveId ?? 0 }
    let driveId: Int?
    let startAddress: AddressSummary?
    let endAddress: AddressSummary?
    let count: Int?
    let totalDistanceKm: Double?
}

struct VisitedPlace: Codable, Identifiable {
    var id: String { "\(latitude ?? 0)_\(longitude ?? 0)" }
    let address: AddressSummary?
    let geofence: GeofenceSummary?
    let visitCount: Int?
    let chargeCount: Int?
    let latitude: Double?
    let longitude: Double?
}

struct AddressSummary: Codable {
    let id: Int?
    let displayName: String?
    let city: String?
    let country: String?
}

struct GeofenceSummary: Codable {
    let id: Int?
    let name: String?
}
