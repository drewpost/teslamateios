import SwiftUI

struct ChargesListView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = ChargesViewModel()
    @State private var loadedCarId: Int?

    private var carId: Int? { appState.selectedCar?.id }

    var body: some View {
        NavigationStack {
            Group {
                if carId == nil {
                    ProgressView("Loading...")
                } else if viewModel.charges.isEmpty && viewModel.isLoading {
                    ProgressView("Loading charges...")
                } else if viewModel.charges.isEmpty, let error = viewModel.error {
                    ContentUnavailableView {
                        Label("Error Loading Charges", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(error)
                    } actions: {
                        Button("Retry") {
                            viewModel.error = nil
                            if let carId { viewModel.load(carId: carId) }
                        }
                        .buttonStyle(.bordered)
                    }
                } else if viewModel.charges.isEmpty {
                    ContentUnavailableView(
                        "No Charges",
                        systemImage: "bolt.fill",
                        description: Text("Charging data will appear here once available.")
                    )
                } else {
                    chargesList
                }
            }
            .refreshable {
                if let carId {
                    await viewModel.loadCharges(carId: carId)
                }
            }
            .navigationTitle("Charges")
            .carSwitcherToolbar()
            .onChange(of: carId) { _, newCarId in
                if let newCarId, newCarId != loadedCarId {
                    loadedCarId = newCarId
                    viewModel.reset()
                    viewModel.load(carId: newCarId)
                }
            }
            .onAppear {
                if let carId, viewModel.charges.isEmpty && !viewModel.isLoading && loadedCarId != carId {
                    loadedCarId = carId
                    viewModel.load(carId: carId)
                }
            }
        }
    }

    private var chargesList: some View {
        List {
            ForEach(viewModel.charges) { charge in
                NavigationLink(destination: ChargeDetailView(chargeId: charge.id)) {
                    ChargeRowView(charge: charge)
                }
                .onAppear {
                    if let carId, charge.id == viewModel.charges.last?.id {
                        viewModel.loadMoreIfNeeded(carId: carId)
                    }
                }
            }

            if viewModel.isLoading && !viewModel.charges.isEmpty {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            }
        }
    }
}
