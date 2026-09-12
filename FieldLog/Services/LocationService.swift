import CoreLocation
import Foundation
import MapKit
import Observation

/// One-shot location fix plus reverse geocode for a recording. App-wide, since
/// authorization state is shared; held in the SwiftUI environment.
///
/// Iterating `CLLocationUpdate.liveUpdates()` triggers the permission prompt on
/// first use and reports denial on the update itself, so no `CLLocationManager`
/// is needed. The stream is cancelled as soon as one good fix arrives.
@Observable
final class LocationService {
    enum Status: Equatable {
        case idle, locating, located, denied, failed
    }

    private(set) var status: Status = .idle

    /// Accept the first fix at least this accurate, in metres.
    var desiredAccuracy: CLLocationAccuracy = 100
    /// Give up after this long without a good fix (not counting time spent on the permission prompt).
    var timeout: Duration = .seconds(15)

    private var task: Task<Void, Never>?
    private var isAwaitingAuthorization = false
    private var bestFix: CLLocation?

    private enum Failure: Error {
        case denied, timedOut
    }

    /// Fills `latitude` and `longitude`, then reverse geocodes into `placeName`.
    /// The place name is written only if the user has not typed one, unless
    /// `replacingPlaceName` is set. Cancels any fill still in flight.
    func fill(_ recording: Recording, replacingPlaceName: Bool = false) {
        task?.cancel()
        task = Task {
            await run(recording, replacingPlaceName: replacingPlaceName)
        }
    }

    private func run(_ recording: Recording, replacingPlaceName: Bool) async {
        status = .locating
        do {
            let location = try await firstFix()
            recording.latitude = location.coordinate.latitude
            recording.longitude = location.coordinate.longitude
            if replacingPlaceName || recording.placeName == nil,
               let name = await placeName(for: location) {
                recording.placeName = name
            }
            status = .located
        } catch Failure.denied {
            status = .denied
        } catch is CancellationError {
            // Superseded by a newer fill, which sets its own status.
        } catch {
            status = .failed
        }
    }

    /// Races the update stream against a timeout that restarts while the permission prompt is up.
    private func firstFix() async throws -> CLLocation {
        isAwaitingAuthorization = false
        bestFix = nil
        return try await withThrowingTaskGroup(of: CLLocation.self) { group in
            group.addTask {
                for try await update in CLLocationUpdate.liveUpdates() {
                    if update.authorizationDenied || update.authorizationDeniedGlobally || update.authorizationRestricted {
                        throw Failure.denied
                    }
                    self.isAwaitingAuthorization = update.authorizationRequestInProgress
                    guard let location = update.location, location.horizontalAccuracy >= 0 else { continue }
                    if location.horizontalAccuracy <= self.desiredAccuracy {
                        return location
                    }
                    if self.bestFix.map({ location.horizontalAccuracy < $0.horizontalAccuracy }) ?? true {
                        self.bestFix = location
                    }
                }
                throw Failure.timedOut
            }
            group.addTask {
                repeat {
                    try await Task.sleep(for: self.timeout)
                } while self.isAwaitingAuthorization
                if let fix = self.bestFix { return fix }
                throw Failure.timedOut
            }
            defer { group.cancelAll() }
            guard let first = try await group.next() else { throw Failure.timedOut }
            return first
        }
    }

    private func placeName(for location: CLLocation) async -> String? {
        guard let request = MKReverseGeocodingRequest(location: location),
              let item = try? await request.mapItems.first else {
            return nil
        }
        // `.short` gives "City, ST" and drops the country; `regionName` alone is the country.
        return PlaceNameFormatter.name(
            city: item.addressRepresentations?.cityWithContext(.short),
            pointOfInterest: item.name
        )
    }
}
