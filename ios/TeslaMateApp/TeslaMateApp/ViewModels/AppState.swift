import Foundation
import SwiftUI

@Observable
class AppState {
    var isAuthenticated = false
    var selectedCar: Car? {
        didSet {
            if let id = selectedCar?.id {
                UserDefaults.standard.set(id, forKey: "selectedCarId")
            } else {
                UserDefaults.standard.removeObject(forKey: "selectedCarId")
            }
        }
    }
    var cars: [Car] = []
    var connectionStatus: ConnectionStatus = .disconnected

    enum ConnectionStatus {
        case connected
        case connecting
        case disconnected
        case error(String)

        var displayText: String {
            switch self {
            case .connected: return "Connected"
            case .connecting: return "Connecting..."
            case .disconnected: return "Disconnected"
            case .error(let msg): return "Error: \(msg)"
            }
        }

        var isConnected: Bool {
            if case .connected = self { return true }
            return false
        }
    }

    func checkAuth() async {
        let auth = AuthService.shared
        isAuthenticated = await auth.isAuthenticated

        if isAuthenticated {
            await loadCars()
        }
    }

    func loadCars() async {
        do {
            cars = try await APIClient.shared.getCars()
            if selectedCar == nil {
                let savedId = UserDefaults.standard.object(forKey: "selectedCarId") as? Int
                if let savedId, let saved = cars.first(where: { $0.id == savedId }) {
                    selectedCar = saved
                } else if let first = cars.first {
                    selectedCar = first
                }
            }
        } catch {
            connectionStatus = .error(error.localizedDescription)
        }
    }

    func logout() async {
        await AuthService.shared.logout()
        isAuthenticated = false
        selectedCar = nil
        cars = []
        connectionStatus = .disconnected
    }
}
