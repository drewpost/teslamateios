import SwiftUI

struct DrivesListView: View {
    let carId: Int
    @State private var viewModel = DrivesViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.drives.isEmpty && viewModel.isLoading {
                    ProgressView("Loading drives...")
                } else if viewModel.drives.isEmpty, let error = viewModel.error {
                    ContentUnavailableView {
                        Label("Error Loading Drives", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(error)
                    } actions: {
                        Button("Retry") {
                            viewModel.error = nil
                            viewModel.load(carId: carId)
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
                    List {
                        ForEach(viewModel.drives) { drive in
                            NavigationLink(destination: DriveDetailView(driveId: drive.id)) {
                                DriveRowView(drive: drive)
                            }
                            .onAppear {
                                if drive.id == viewModel.drives.last?.id {
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
            .refreshable {
                await viewModel.loadDrives(carId: carId)
            }
            .navigationTitle("Drives")
            .carSwitcherToolbar()
            .onAppear {
                if viewModel.drives.isEmpty && !viewModel.isLoading {
                    viewModel.load(carId: carId)
                }
            }
        }
    }
}
