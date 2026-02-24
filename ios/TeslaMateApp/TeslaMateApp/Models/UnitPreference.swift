import Foundation

@Observable
class UnitPreference {
    var useMiles: Bool {
        didSet { UserDefaults.standard.set(useMiles, forKey: "useMiles") }
    }

    var useFahrenheit: Bool {
        didSet { UserDefaults.standard.set(useFahrenheit, forKey: "useFahrenheit") }
    }

    init() {
        self.useMiles = UserDefaults.standard.bool(forKey: "useMiles")
        self.useFahrenheit = UserDefaults.standard.bool(forKey: "useFahrenheit")
    }

    // MARK: - Formatting Helpers

    func formatDistance(_ km: Double) -> String {
        if useMiles {
            return String(format: "%.1f mi", km * 0.621371)
        }
        return String(format: "%.1f km", km)
    }

    func formatDistanceInt(_ km: Double) -> String {
        if useMiles {
            return String(format: "%.0f mi", km * 0.621371)
        }
        return String(format: "%.0f km", km)
    }

    func formatSpeed(_ kph: Int) -> String {
        if useMiles {
            return "\(Int(Double(kph) * 0.621371)) mph"
        }
        return "\(kph) km/h"
    }

    func formatRange(_ km: Double) -> String {
        if useMiles {
            return String(format: "%.0f mi", km * 0.621371)
        }
        return String(format: "%.0f km", km)
    }

    func formatTemperature(_ celsius: Double) -> String {
        if useFahrenheit {
            return String(format: "%.1f\u{00B0}F", celsius * 9.0 / 5.0 + 32.0)
        }
        return String(format: "%.1f\u{00B0}C", celsius)
    }

    func formatElevation(_ meters: Int) -> String {
        if useMiles {
            return "\(Int(Double(meters) * 3.28084)) ft"
        }
        return "\(meters)m"
    }

    func formatDistanceShort(_ km: Double) -> String {
        if useMiles {
            let mi = km * 0.621371
            return mi >= 1000 ? String(format: "%.0f mi", mi) : String(format: "%.1f mi", mi)
        }
        return km >= 1000 ? String(format: "%.0f km", km) : String(format: "%.1f km", km)
    }

    func formatSpeed(_ kph: Double) -> String {
        if useMiles {
            return String(format: "%.0f mph", kph * 0.621371)
        }
        return String(format: "%.0f km/h", kph)
    }

    var distanceUnit: String { useMiles ? "mi" : "km" }
    var speedUnit: String { useMiles ? "mph" : "km/h" }
    var temperatureUnit: String { useFahrenheit ? "°F" : "°C" }
}
