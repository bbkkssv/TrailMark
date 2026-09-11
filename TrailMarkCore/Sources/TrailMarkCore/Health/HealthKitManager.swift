
import Foundation
import HealthKit
import Observation

@MainActor
@Observable
public final class HealthKitManager {

    public enum AuthorizationState: Equatable {
        case unknown
        case unavailable
        case requesting
        case authorized
        case denied
    }

    public private(set) var currentAuthStatus: AuthorizationState = .unknown

    public private(set) var todaysSummary: ActivitySummary = .empty
    
    private let store = HKHealthStore()

    public init() {
        if !HKHealthStore.isHealthDataAvailable() {
            currentAuthStatus = .unavailable
        }
    }

    private var stepsType: HKQuantityType { HKQuantityType(.stepCount) }
    private var distanceType: HKQuantityType { HKQuantityType(.distanceWalkingRunning) }
    private var energyType: HKQuantityType { HKQuantityType(.activeEnergyBurned) }
    private var flightsClimbedType: HKQuantityType { HKQuantityType(.flightsClimbed) }
    private var sleepType: HKCategoryType { HKCategoryType(.sleepAnalysis) } // Awake, REM, Core, Deep

    // MARK: - Authorization Framework

    private var readTypes: Set<HKObjectType> {
        [stepsType, distanceType, energyType, flightsClimbedType, sleepType]
    }

    private var shareTypes: Set<HKSampleType> {
        [energyType, distanceType, HKObjectType.workoutType()]
    }
    
    public func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            currentAuthStatus = .unavailable
            return
        }

        currentAuthStatus = .requesting
        do {
            try await store.requestAuthorization(toShare: shareTypes, read: readTypes)
            currentAuthStatus = .authorized
        } catch {
            currentAuthStatus = .denied
        }
    }
    
    public func fetchTodaysSummary() async {
        await refreshTodaysSummary()
    }

    public func refreshTodaysSummary() async {
        guard currentAuthStatus == .authorized else { return }

        let startOfDay = Calendar.current.startOfDay(for: Date())
        async let steps = sumQuantity(stepsType, unit: .count(), since: startOfDay)
        async let distance = sumQuantity(distanceType, unit: .meter(), since: startOfDay)
        async let energy = sumQuantity(energyType, unit: .kilocalorie(), since: startOfDay)
        async let flightsClimbed = sumQuantity(flightsClimbedType, unit: .count(), since: startOfDay)

        todaysSummary = ActivitySummary(
            steps: await steps,
            distanceMeters: await distance,
            activeEnergyKcal: await energy,
            flightsClimbed: await flightsClimbed,
            date: startOfDay
        )
    }

    /// This func returns the cumulative sum of a quantity type from a given start date to now
    private func sumQuantity(
        _ type: HKQuantityType,
        unit: HKUnit,
        since start: Date
    ) async -> Double {
        return await withCheckedContinuation { continuation in
            let timePredicate = HKQuery.predicateForSamples(withStart: start, end: Date())

            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: timePredicate,
                options: .cumulativeSum,
            ) { _, stats, _ in
                let value = stats?.sumQuantity()?.doubleValue(for: unit) ?? 0
                continuation.resume(returning: value)
            }

            store.execute(query)
        }
    }
}
