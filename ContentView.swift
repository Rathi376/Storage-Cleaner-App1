import SwiftUI

/// Main tab navigation: Home, Clean, Settings.
struct MainTabView: View {
    @Environment(DashboardViewModel.self) private var dashboardVM

    var body: some View {
        TabView {
            NavigationStack {
                DashboardView()
            }
            .tabItem {
                Label("Home", systemImage: "internaldrive.fill")
            }

            NavigationStack {
                CleanTabView()
            }
            .tabItem {
                Label("Clean", systemImage: "sparkles")
            }

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
        }
        .tint(CSTheme.accentBlue)
    }
}

/// Fallback wrapper for ContentView
struct ContentView: View {
    var body: some View {
        MainTabView()
    }
}
