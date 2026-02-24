import SwiftUI
import Charts
import MapKit

struct ChargingStatsView: View {
    let carId: Int
    @State private var viewModel = ChargingStatsViewModel()
    @State private var period: StatsPeriod = .year
    @State private var referenceDate = Date()
    @State private var cameraPosition: MapCameraPosition = .automatic

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                PeriodPicker(selectedPeriod: $period, referenceDate: $referenceDate)
                    .padding(.horizontal)

                if viewModel.isLoading && viewModel.data == nil {
                    ProgressView()
                        .padding(.top, 60)
                } else if let data = viewModel.data {
                    // Stat cards
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        StatCardView(
                            value: "\(data.totals.totalSessions ?? 0)",
                            label: "Sessions"
                        )
                        if let energy = data.totals.totalEnergyKwh {
                            StatCardView(
                                value: String(format: "%.0f kWh", energy),
                                label: "Total Energy"
                            )
                        }
                        if let cost = data.totals.totalCost {
                            StatCardView(
                                value: String(format: "$%.0f", cost),
                                label: "Total Cost"
                            )
                        }
                        StatCardView(
                            value: "\(data.totals.acSessions ?? 0) / \(data.totals.dcSessions ?? 0)",
                            label: "AC / DC"
                        )
                    }
                    .padding(.horizontal)

                    // AC/DC Energy pie chart
                    if let ac = data.totals.acEnergyKwh, let dc = data.totals.dcEnergyKwh, (ac + dc) > 0 {
                        VStack(spacing: 8) {
                            Text("AC / DC Energy")
                                .font(.subheadline.weight(.medium))

                            Chart {
                                SectorMark(
                                    angle: .value("AC", ac),
                                    innerRadius: .ratio(0.5),
                                    angularInset: 1.5
                                )
                                .foregroundStyle(.green)
                                .annotation(position: .overlay) {
                                    VStack(spacing: 0) {
                                        Text("AC")
                                            .font(.caption2.bold())
                                        Text(String(format: "%.0f kWh", ac))
                                            .font(.caption2)
                                    }
                                    .foregroundStyle(.white)
                                }

                                SectorMark(
                                    angle: .value("DC", dc),
                                    innerRadius: .ratio(0.5),
                                    angularInset: 1.5
                                )
                                .foregroundStyle(.orange)
                                .annotation(position: .overlay) {
                                    VStack(spacing: 0) {
                                        Text("DC")
                                            .font(.caption2.bold())
                                        Text(String(format: "%.0f kWh", dc))
                                            .font(.caption2)
                                    }
                                    .foregroundStyle(.white)
                                }
                            }
                            .frame(height: 180)

                            HStack(spacing: 16) {
                                Label("AC", systemImage: "circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                                Label("DC", systemImage: "circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Energy bar chart
                    if !data.buckets.isEmpty {
                        Chart(data.buckets) { bucket in
                            if let period = bucket.period.flatMap({ parseDate($0) }),
                               let energy = bucket.energyKwh {
                                BarMark(
                                    x: .value("Period", period, unit: .month),
                                    y: .value("kWh", energy)
                                )
                                .foregroundStyle(.green.gradient)
                            }
                        }
                        .chartYAxisLabel("kWh")
                        .frame(height: 220)
                        .padding(.horizontal)
                    }

                    // DC Charging Curve scatter
                    if !viewModel.dcCurve.isEmpty {
                        VStack(spacing: 8) {
                            Text("DC Charging Curve")
                                .font(.subheadline.weight(.medium))
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Chart(viewModel.dcCurve) { point in
                                if let level = point.batteryLevel, let power = point.chargerPower {
                                    PointMark(
                                        x: .value("SoC", level),
                                        y: .value("Power", power)
                                    )
                                    .foregroundStyle(.orange.opacity(0.5))
                                    .symbolSize(15)
                                }
                            }
                            .chartXAxisLabel("Battery %")
                            .chartYAxisLabel("kW")
                            .chartXScale(domain: 0...100)
                            .frame(height: 200)
                        }
                        .padding(.horizontal)
                    }

                    // Top Charging Stations
                    if !viewModel.topStations.isEmpty {
                        VStack(spacing: 8) {
                            Text("Top Charging Stations")
                                .font(.subheadline.weight(.medium))
                                .frame(maxWidth: .infinity, alignment: .leading)

                            ForEach(viewModel.topStations.prefix(10)) { station in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(station.displayName ?? "Unknown")
                                            .font(.subheadline)
                                            .lineLimit(1)
                                        if let city = station.city {
                                            Text(city)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text("\(station.sessions ?? 0)x")
                                            .font(.subheadline.monospacedDigit())
                                        if let energy = station.totalEnergyKwh {
                                            Text(String(format: "%.0f kWh", energy))
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                                Divider()
                            }
                        }
                        .padding(.horizontal)

                        // Charging map
                        let stationsWithCoords = viewModel.topStations.filter { $0.latitude != nil && $0.longitude != nil }
                        if !stationsWithCoords.isEmpty {
                            VStack(spacing: 8) {
                                Text("Charging Locations")
                                    .font(.subheadline.weight(.medium))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal)

                                Map(position: $cameraPosition) {
                                    ForEach(stationsWithCoords) { station in
                                        if let lat = station.latitude, let lng = station.longitude {
                                            Annotation(
                                                station.displayName ?? "",
                                                coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng)
                                            ) {
                                                Image(systemName: "bolt.circle.fill")
                                                    .foregroundStyle(.green)
                                                    .font(.title2)
                                            }
                                        }
                                    }
                                }
                                .frame(height: 250)
                                .cornerRadius(12)
                                .padding(.horizontal)
                            }
                        }
                    }
                } else if let error = viewModel.error {
                    ContentUnavailableView("Error", systemImage: "exclamationmark.triangle", description: Text(error))
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Charging Stats")
        .task { Task { await reload() } }
        .onChange(of: period) { Task { await reload() } }
        .onChange(of: referenceDate) { Task { await reload() } }
    }

    private func reload() async {
        let picker = PeriodPicker(selectedPeriod: $period, referenceDate: $referenceDate)
        let range = picker.dateRange
        await viewModel.load(carId: carId, from: range.from, to: range.to, bucket: period.bucket)
    }

    private func parseDate(_ str: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: str) ?? ISO8601DateFormatter().date(from: str)
    }
}
