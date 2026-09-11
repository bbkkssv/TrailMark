import SwiftUI
import TrailMarkCore

struct TodayDashboardView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        NavigationStack {
            Group {
                switch model.health.currentAuthStatus {
                case .authorized:
                    summary
                case .unavailable:
                    ContentUnavailableView(
                        "Health Data Unavailable",
                        systemImage: "heart.slash",
                        description: Text("This device can't provide health data.")
                    )
                case .requesting:
                    ProgressView("Requesting Health access...")
                case .unknown:
                    ContentUnavailableView {
                        Label("Health Access Needed", systemImage: "heart.text.square")
                    } description: {
                        Text("TrailMark uses Health data to show your activity summary.")
                    } actions: {
                        Button("Enable Health Access") {
                            Task {
                                await model.health.requestAuthorization()
                                await model.health.refreshTodaysSummary()
                            }
                        }
                    }
                case .denied:
                    ContentUnavailableView {
                        Label("Health Access Needed", systemImage: "lock.fill")
                    } description: {
                        Text("Enable TrailMark access in the Health app.")
                    } actions: {
                        Button("Try again") {
                            Task {
                                await model.health.requestAuthorization()
                                await model.health.refreshTodaysSummary()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Today's Data")
            .task { await model.health.refreshTodaysSummary() }
            .refreshable { await model.health.refreshTodaysSummary() }
        }
    }

    private var summary: some View {
        ScrollView {
            VStack(spacing: 16) {
                MetricCard(
                    title: "Steps",
                    value: model.health.todaysSummary.stepsText,
                    symbol: "figure.walk",
                    tint: .blue
                )

                MetricCard(
                    title: "Distance",
                    value: model.health.todaysSummary.distanceText,
                    symbol: "map",
                    tint: .green
                )

                MetricCard(
                    title: "Active Energy",
                    value: model.health.todaysSummary.activeEnergyText,
                    symbol: "flame",
                    tint: .orange
                )

                MetricCard(
                    title: "Flights Climbed",
                    value: model.health.todaysSummary.flightsClimbedText,
                    symbol: "stairs",
                    tint: .purple
                )
            }
            .padding()
        }
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let symbol: String
    let tint: Color

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: symbol)
                .font(.title)
                .foregroundStyle(tint)
                .frame(width: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .contentTransition(.numericText())
            }
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16))
    }
}
