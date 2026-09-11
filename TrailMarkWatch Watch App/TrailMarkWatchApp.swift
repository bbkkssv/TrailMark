//
//  TrailMarkWatchApp.swift
//  TrailMarkWatch Watch App
//
//  Created by Robert Vinson on 9/8/26.
//

import SwiftUI
import TrailMarkCore

@main
struct TrailMarkWatch_Watch_AppApp: App {
    @State private var healthKit = HealthKitManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(healthKit)
        }
    }
}
