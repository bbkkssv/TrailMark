import SwiftUI
import TrailMarkCore

struct ContentView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        TabView {
            TodayDashboardView()
                .tabItem { Label("Today", systemImage: "sun.max.fill") }
        }
        .task {
            await model.health.requestAuthorization()
            await model.health.refreshTodaysSummary()
        }
    }
}

#Preview {
    ContentView()
        .environment(AppModel())
}
