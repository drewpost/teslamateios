import SwiftUI

struct CarSwitcherToolbar: ViewModifier {
    @Environment(AppState.self) private var appState

    func body(content: Content) -> some View {
        content.toolbar {
            ToolbarItem(placement: .principal) {
                if appState.cars.count > 1 {
                    Menu {
                        ForEach(appState.cars) { car in
                            Button {
                                appState.selectedCar = car
                            } label: {
                                HStack {
                                    Text(car.displayName)
                                    if appState.selectedCar?.id == car.id {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(appState.selectedCar?.displayName ?? "Tesla")
                                .fontWeight(.semibold)
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    Text(appState.selectedCar?.displayName ?? "Tesla")
                        .fontWeight(.semibold)
                }
            }
        }
    }
}

extension View {
    func carSwitcherToolbar() -> some View {
        modifier(CarSwitcherToolbar())
    }
}
