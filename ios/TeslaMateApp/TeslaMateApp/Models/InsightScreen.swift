import Foundation

enum InsightSection: String, CaseIterable, Identifiable {
    case battery = "Battery"
    case driving = "Driving"
    case charging = "Charging"
    case vehicle = "Vehicle"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .battery: return "battery.75percent"
        case .driving: return "car.fill"
        case .charging: return "bolt.fill"
        case .vehicle: return "gauge.with.dots.needle.bottom.50percent"
        }
    }
}

enum InsightScreen: String, CaseIterable, Identifiable {
    case batteryHealth
    case projectedRange
    case chargeLevel
    case vampireDrain
    case driveStats
    case efficiency
    case mileage
    case visited
    case chargingStats
    case states
    case timeline
    case updates
    case statistics

    var id: String { rawValue }

    var title: String {
        switch self {
        case .batteryHealth: return "Battery Health"
        case .projectedRange: return "Projected Range"
        case .chargeLevel: return "Charge Level"
        case .vampireDrain: return "Vampire Drain"
        case .driveStats: return "Drive Stats"
        case .efficiency: return "Efficiency"
        case .mileage: return "Mileage"
        case .visited: return "Visited"
        case .chargingStats: return "Charging Stats"
        case .states: return "States"
        case .timeline: return "Timeline"
        case .updates: return "Updates"
        case .statistics: return "Statistics"
        }
    }

    var icon: String {
        switch self {
        case .batteryHealth: return "heart.text.square"
        case .projectedRange: return "arrow.left.and.right"
        case .chargeLevel: return "battery.50percent"
        case .vampireDrain: return "moon.zzz"
        case .driveStats: return "chart.bar"
        case .efficiency: return "leaf"
        case .mileage: return "road.lanes"
        case .visited: return "map"
        case .chargingStats: return "bolt.batteryblock"
        case .states: return "circle.grid.3x3"
        case .timeline: return "clock.arrow.circlepath"
        case .updates: return "arrow.down.app"
        case .statistics: return "number"
        }
    }

    var section: InsightSection {
        switch self {
        case .batteryHealth, .projectedRange, .chargeLevel, .vampireDrain:
            return .battery
        case .driveStats, .efficiency, .mileage, .visited:
            return .driving
        case .chargingStats:
            return .charging
        case .states, .timeline, .updates, .statistics:
            return .vehicle
        }
    }

    static func screens(for section: InsightSection) -> [InsightScreen] {
        allCases.filter { $0.section == section }
    }
}
