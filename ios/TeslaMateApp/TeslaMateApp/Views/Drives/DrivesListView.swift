import SwiftUI

struct DrivesListView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = DrivesViewModel()
    @State private var loadedCarId: Int?

    private var carId: Int? { appState.selectedCar?.id }

    var body: some View {
        NavigationStack {
            Group {
                if carId == nil {
                    ProgressView("Loading...")
                } else if viewModel.drives.isEmpty && viewModel.isLoading {
                    ProgressView("Loading drives...")
                } else if viewModel.drives.isEmpty, let error = viewModel.error {
                    ContentUnavailableView {
                        Label("Error Loading Drives", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(error)
                    } actions: {
                        Button("Retry") {
                            viewModel.error = nil
                            if let carId { viewModel.load(carId: carId) }
                        }
                        .buttonStyle(.bordered)
                    }
                } else if viewModel.drives.isEmpty {
                    ContentUnavailableView(
                        "No Drives",
                        systemImage: "road.lanes",
                        description: Text("Drive data will appear here once available.")
                    )
                } else {
                    drivesList
                }
            }
            .refreshable {
                if let carId {
                    await viewModel.loadDrives(carId: carId)
                }
            }
            .navigationTitle("Drives")
            .carSwitcherToolbar()
            .onChange(of: carId) { _, newCarId in
                if let newCarId, newCarId != loadedCarId {
                    loadedCarId = newCarId
                    viewModel.reset()
                    viewModel.load(carId: newCarId)
                }
            }
            .onAppear {
                if let carId, viewModel.drives.isEmpty && !viewModel.isLoading && loadedCarId != carId {
                    loadedCarId = carId
                    viewModel.load(carId: carId)
                }
            }
        }
    }

    private var drivesList: some View {
        List {
            ForEach(viewModel.drives) { drive in
                NavigationLink(destination: DriveDetailView(driveId: drive.id)) {
                    DriveRowView(drive: drive)
                }
                .onAppear {
                    if let carId, drive.id == viewModel.drives.last?.id {
                        viewModel.loadMoreIfNeeded(carId: carId)
                    }
                }
            }

            if viewModel.isLoading && !viewModel.drives.isEmpty {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            }
        }
    }
}
