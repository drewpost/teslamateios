import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @Environment(UnitPreference.self) private var unitPreference
    @State private var viewModel = SettingsViewModel()

    var body: some View {
        NavigationStack {
            Form {
                Section("Server Connection") {
                    TextField("Server URL", text: $viewModel.serverURL)
                        .keyboardType(.URL)
                        .textContentType(.URL)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)

                    SecureField("API Token", text: $viewModel.apiToken)
                        .textContentType(.password)
                }

                Section {
                    Button {
                        Task { await viewModel.testConnection() }
                    } label: {
                        HStack {
                            Text("Test Connection")
                            if viewModel.isTestingConnection {
                                Spacer()
                                ProgressView()
                            }
                        }
                    }
                    .disabled(viewModel.serverURL.isEmpty || viewModel.isTestingConnection)

                    if let result = viewModel.connectionTestResult {
                        Label(result, systemImage: viewModel.connectionTestSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(viewModel.connectionTestSuccess ? .green : .red)
                            .font(.caption)
                    }
                }

                Section {
                    Button {
                        Task { await viewModel.login(appState: appState) }
                    } label: {
                        HStack {
                            Text(appState.isAuthenticated ? "Reconnect" : "Connect & Login")
                            if viewModel.isLoggingIn {
                                Spacer()
                                ProgressView()
                            }
                        }
                    }
                    .disabled(viewModel.serverURL.isEmpty || viewModel.apiToken.isEmpty || viewModel.isLoggingIn)

                    if let error = viewModel.loginError {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }

                Section("Units") {
                    @Bindable var units = unitPreference
                    Toggle("Use Miles", isOn: $units.useMiles)
                    Toggle("Use Fahrenheit", isOn: $units.useFahrenheit)
                }

                if appState.isAuthenticated {
                    Section("Account") {
                        Button("Logout", role: .destructive) {
                            Task { await appState.logout() }
                        }
                    }

                    if !appState.cars.isEmpty {
                        Section("Default Vehicle") {
                            ForEach(appState.cars) { car in
                                Button {
                                    appState.defaultCarId = car.id
                                    appState.selectedCar = car
                                } label: {
                                    HStack {
                                        Text(car.displayName)
                                        Spacer()
                                        if appState.selectedCar?.id == car.id {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(.accentColor)
                                        }
                                    }
                                }
                                .foregroundColor(.primary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .task {
                await viewModel.loadSavedSettings()
            }
        }
    }
}
