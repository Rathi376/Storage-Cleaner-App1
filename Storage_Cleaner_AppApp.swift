import SwiftUI

@main
struct CleanSpaceApp: App {
    @State private var dashboardVM = DashboardViewModel()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(dashboardVM)
                .preferredColorScheme(.dark)
        }
    }
}
