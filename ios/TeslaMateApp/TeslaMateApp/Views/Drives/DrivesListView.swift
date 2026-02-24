import SwiftUI

struct DrivesListView: View {
    let carId: Int
    @State private var viewModel = DrivesViewModel()
    @State private var hasAppeared = false

    var body: some View {
        NavigationStack {
            content
                .refreshable {
                    await viewModel.loadDrives(carId: carId)
                }
                .navigationTitle("Drives")
                .carSwitcherToolbar()
        }
        .onAppear {
            hasAppeared = true
            if viewModel.drives.isEmpty && !viewModel.isLoading {
                viewModel.load(carId: carId)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
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
        } else if viewModel.drives.isEmpty && hasAppeared {
            ContentUnavailableView(
                "No Drives",
                systemImage: "road.lanes",
                description: Text("Drive data will appear here once available.")
            )
        } else if viewModel.drives.isEmpty {
            ProgressView("Loading drives...")
                .onAppear {
                    viewModel.load(carId: carId)
                }
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
}
