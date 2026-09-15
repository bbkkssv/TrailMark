import Foundation
import Observation
import TrailMarkCore

@MainActor
@Observable
final class AppModel {
    let health = HealthKitManager()
    let media = MediaStore()
}
