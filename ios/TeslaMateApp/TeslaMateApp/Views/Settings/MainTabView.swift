import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            OverviewView()
                .tabItem {
                    Label("Overview", systemImage: "car.fill")
                }

            DrivesListView()
                .tabItem {
                    Label("Drives", systemImage: "road.lanes")
                }

            ChargesListView()
                .tabItem {
                    Label("Charges", systemImage: "bolt.fill")
                }

            InsightsHomeView()
                .tabItem {
                    Label("Insights", systemImage: "chart.xyaxis.line")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
    }
}
