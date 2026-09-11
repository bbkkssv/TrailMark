
import Foundation

public struct ActivitySummary: Sendable, Equatable, Codable {
    public var steps: Double
    public var distanceMeters: Double
    public var activeEnergyKcal: Double
    public var flightsClimbed: Double
    public var date: Date

    public init(
        steps: Double = 0,
        distanceMeters: Double = 0,
        activeEnergyKcal: Double = 0,
        flightsClimbed: Double = 0,
        date: Date = Date()
    ) {
        self.steps = steps
        self.distanceMeters = distanceMeters
        self.activeEnergyKcal = activeEnergyKcal
        self.flightsClimbed = flightsClimbed
        self.date = date
    }

    public static let empty = ActivitySummary()

    // MARK: - UI Helpers To Display Data

    public var stepsText: String {
        Self.wholeNumber.string(from: NSNumber(value: steps)) ?? "0"
    }

    public var activeEnergyText: String {
        let value = Self.wholeNumber.string(from: NSNumber(value: activeEnergyKcal)) ?? "0"
        return "\(value) kcal"
    }

    public var distanceText: String {
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .naturalScale
        formatter.numberFormatter.maximumFractionDigits = 2
        let measurement = Measurement(value: distanceMeters, unit: UnitLength.meters)
        return formatter.string(from: measurement)
    }

    public var flightsClimbedText: String {
        Self.wholeNumber.string(from: NSNumber(value: flightsClimbed)) ?? "0"
    }

    private static let wholeNumber: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        return f
    }()
}
