//
//  ContentView.swift
//  TrailMarkWatch Watch App
//
//  Created by Robert Vinson on 9/8/26.
//

import SwiftUI
import TrailMarkCore

struct ContentView: View {
    @Environment(HealthKitManager.self) private var healthKit

    var body: some View {
        Group {
            if healthKit.currentAuthStatus == .unavailable {
                ContentUnavailableView(
                    "Health Unavailable",
                    systemImage: "heart.slash"
                )
            } else {
                summaryList
            }
        }
        .task {
            await healthKit.requestAuthorization()
            await healthKit.fetchTodaysSummary()
        }
    }

    private var summaryList: some View {
        List {
            StatRow(label: "Steps",    value: healthKit.todaysSummary.stepsText,        systemImage: "figure.walk")
            StatRow(label: "Distance", value: healthKit.todaysSummary.distanceText,     systemImage: "map")
            StatRow(label: "Energy",   value: healthKit.todaysSummary.activeEnergyText, systemImage: "flame")
        }
        .refreshable {
            await healthKit.fetchTodaysSummary()
        }
        .navigationTitle("Today")
    }
}

private struct StatRow: View {
    let label: String
    let value: String
    let systemImage: String

    var body: some View {
        HStack {
            Image(systemName: systemImage)
                .foregroundStyle(.red)
            VStack(alignment: .leading) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.body)
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(HealthKitManager())
}
