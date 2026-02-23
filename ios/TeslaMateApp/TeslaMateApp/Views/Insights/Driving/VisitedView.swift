import SwiftUI
import MapKit

struct VisitedView: View {
    let carId: Int
    @State private var viewModel = VisitedViewModel()
    @State private var mode: VisitedViewModel.VisitedMode = .places
    @State private var cameraPosition: MapCameraPosition = .automatic

    var body: some View {
        ZStack(alignment: .bottom) {
            Map(position: $cameraPosition) {
                if mode == .heat {
                    ForEach(viewModel.heatmapPoints) { point in
                        if let lat = point.latitude, let lng = point.longitude, let count = point.count {
                            MapCircle(center: CLLocationCoordinate2D(latitude: lat, longitude: lng),
                                      radius: CLLocationDistance(max(100, count * 50)))
                            .foregroundStyle(.red.opacity(min(0.6, Double(count) * 0.05)))
                        }
                    }
                } else if mode == .places {
                    ForEach(viewModel.places) { place in
                        if let lat = place.latitude, let lng = place.longitude {
                            Annotation(
                                place.geofence?.name ?? place.address?.displayName ?? "",
                                coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng)
                            ) {
                                Image(systemName: "mappin.circle.fill")
                                    .foregroundStyle(.blue)
                                    .font(.title2)
                            }
                        }
                    }
                }
            }

            VStack(spacing: 0) {
                Picker("Mode", selection: $mode) {
                    ForEach(VisitedViewModel.VisitedMode.allCases) { m in
                        Text(m.rawValue).tag(m)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                .background(.ultraThinMaterial)

                if mode == .routes {
                    List(viewModel.routes) { route in
                        HStack {
                            VStack(alignment: .leading) {
                                Text("\(route.startAddress?.displayName ?? "?") → \(route.endAddress?.displayName ?? "?")")
                                    .font(.subheadline)
                                    .lineLimit(1)
                                if let dist = route.totalDistanceKm {
                                    Text(String(format: "%.1f km total", dist))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            Text("\(route.count ?? 0)x")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(height: 300)
                }

                if mode == .places {
                    List(viewModel.places.prefix(20)) { place in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(place.geofence?.name ?? place.address?.displayName ?? "Unknown")
                                    .font(.subheadline)
                                if let city = place.address?.city {
                                    Text(city)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text("\(place.visitCount ?? 0) visits")
                                    .font(.caption)
                                if let charges = place.chargeCount, charges > 0 {
                                    Text("\(charges) charges")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .frame(height: 300)
                }
            }
        }
        .navigationTitle("Visited")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.load(carId: carId)
        }
    }
}
