import SwiftUI
import MapKit

struct OverviewView: View {
    let carId: Int
    @Environment(AppState.self) private var appState
    @Environment(UnitPreference.self) private var unitPreference
    @State private var viewModel = OverviewViewModel()
    @State private var cameraPosition: MapCameraPosition = .automatic

    var body: some View {
        NavigationStack {
            ScrollView {
                if let summary = viewModel.summary {
                    VStack(spacing: 16) {
                        // Vehicle Header
                        VStack(spacing: 4) {
                            Text(summary.displayName ?? appState.selectedCar?.displayName ?? "Tesla")
                                .font(.title2.bold())
                            if let model = summary.model {
                                Text("Model \(model)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }

                        // State Badge
                        StateBadgeView(state: summary.formattedState)

                        // Speed Display (when driving)
                        if summary.isDriving, let speed = summary.speed {
                            VStack(spacing: 4) {
                                Text(unitPreference.formatSpeed(speed))
                                    .font(.system(size: 48, weight: .bold, design: .rounded))
                                    .monospacedDigit()
                                if let power = summary.power {
                                    Text("\(power) kW")
                                        .font(.title3)
                                        .foregroundColor(power < 0 ? .green : .orange)
                                }
                            }
                            .padding(.vertical, 8)
                        }

                        // Battery Gauge
                        BatteryGaugeView(
                            level: summary.batteryLevel ?? 0,
                            isCharging: summary.isCharging,
                            formattedRange: summary.rangeKm.map { unitPreference.formatRange($0) }
                        )
                        .frame(height: 180)

                        // Info Grid
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            if let temp = summary.outsideTemp {
                                InfoCard(title: "Outside", value: unitPreference.formatTemperature(temp), icon: "thermometer")
                            }
                            if let temp = summary.insideTemp {
                                InfoCard(title: "Inside", value: unitPreference.formatTemperature(temp), icon: "thermometer.sun")
                            }
                            if let odometer = summary.odometer {
                                InfoCard(title: "Odometer", value: unitPreference.formatDistanceInt(odometer), icon: "gauge.with.dots.needle.bottom.50percent")
                            }
                            if let version = summary.version {
                                InfoCard(title: "Software", value: version, icon: "arrow.down.app")
                            }
                            if let geofence = summary.geofence {
                                InfoCard(title: "Location", value: geofence, icon: "location.fill")
                            }
                            if let elevation = summary.elevation {
                                InfoCard(title: "Elevation", value: unitPreference.formatElevation(elevation), icon: "mountain.2")
                            }
                        }
                        .padding(.horizontal)

                        // Status indicators
                        HStack(spacing: 16) {
                            StatusIcon(icon: "lock.fill", active: summary.locked == true, label: "Locked")
                            StatusIcon(icon: "shield.fill", active: summary.sentryMode == true, label: "Sentry")
                            StatusIcon(icon: "powerplug.fill", active: summary.pluggedIn == true, label: "Plugged In")
                            StatusIcon(icon: "fan.fill", active: summary.isClimateOn == true, label: "Climate")
                        }
                        .padding()

                        // Location Map
                        if let lat = summary.latitude, let lng = summary.longitude {
                            Map(position: $cameraPosition) {
                                Annotation("", coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng)) {
                                    Image(systemName: "car.fill")
                                        .font(.title2)
                                        .foregroundColor(.accentColor)
                                        .rotationEffect(.degrees(Double(summary.heading ?? 0)))
                                }
                            }
                            .frame(height: 250)
                            .cornerRadius(12)
                            .padding(.horizontal)
                            .allowsHitTesting(false)
                            .onChange(of: summary.latitude) {
                                updateCamera(lat: lat, lng: lng)
                            }
                            .onChange(of: summary.longitude) {
                                updateCamera(lat: lat, lng: lng)
                            }
                            .onAppear {
                                updateCamera(lat: lat, lng: lng)
                            }
                        }
                    }
                    .padding()
                } else if viewModel.isLoading {
                    ProgressView("Loading vehicle data...")
                        .padding(.top, 100)
                } else if let error = viewModel.error {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text(error)
                            .multilineTextAlignment(.center)
                        Button("Retry") {
                            Task { await viewModel.refresh(carId: carId) }
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.top, 100)
                }
            }
            .refreshable {
                await viewModel.refresh(carId: carId)
            }
            .navigationTitle("Overview")
            .task {
                await viewModel.startListening(carId: carId)
            }
            .onDisappear {
                Task { await viewModel.stopListening() }
            }
        }
    }

    private func updateCamera(lat: Double, lng: Double) {
        withAnimation {
            cameraPosition = .region(MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: lat, longitude: lng),
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            ))
        }
    }
}

struct InfoCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.accentColor)
            Text(value)
                .font(.headline)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct StatusIcon: View {
    let icon: String
    let active: Bool
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(active ? .green : .gray)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}
