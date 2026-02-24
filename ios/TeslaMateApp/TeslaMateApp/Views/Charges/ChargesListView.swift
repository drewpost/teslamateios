import SwiftUI

struct ChargesListView: View {
    let carId: Int
    @State private var viewModel = ChargesViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.charges.isEmpty && viewModel.isLoading {
                    ProgressView("Loading charges...")
                } else if viewModel.charges.isEmpty, let error = viewModel.error {
                    ContentUnavailableView {
                        Label("Error Loading Charges", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(error)
                    } actions: {
                        Button("Retry") {
                            viewModel.error = nil
                            viewModel.load(carId: carId)
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
                    List {
                        ForEach(viewModel.charges) { charge in
                            NavigationLink(destination: ChargeDetailView(chargeId: charge.id)) {
                                ChargeRowView(charge: charge)
                            }
                            .onAppear {
                                if charge.id == viewModel.charges.last?.id {
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
            .refreshable {
                await viewModel.loadCharges(carId: carId)
            }
            .navigationTitle("Charges")
            .carSwitcherToolbar()
            .onAppear {
                if viewModel.charges.isEmpty && !viewModel.isLoading {
                    viewModel.load(carId: carId)
                }
            }
        }
    }
}
