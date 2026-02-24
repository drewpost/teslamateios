import SwiftUI

struct ChargesListView: View {
    let carId: Int
    @State private var viewModel = ChargesViewModel()
    @State private var hasAppeared = false

    var body: some View {
        NavigationStack {
            content
                .refreshable {
                    await viewModel.loadCharges(carId: carId)
                }
                .navigationTitle("Charges")
                .carSwitcherToolbar()
        }
        .onAppear {
            hasAppeared = true
            if viewModel.charges.isEmpty && !viewModel.isLoading {
                viewModel.load(carId: carId)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
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
        } else if viewModel.charges.isEmpty && hasAppeared {
            ContentUnavailableView(
                "No Charges",
                systemImage: "bolt.fill",
                description: Text("Charging data will appear here once available.")
            )
        } else if viewModel.charges.isEmpty {
            ProgressView("Loading charges...")
                .onAppear {
                    viewModel.load(carId: carId)
                }
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
}
