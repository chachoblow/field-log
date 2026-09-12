import CoreLocation
import Foundation
import Observation
import WeatherKit

/// Fills a recording's weather fields from WeatherKit for its coordinates and
/// start time. App-wide and held in the SwiftUI environment, like
/// `LocationService`, so the form can show progress and retry.
///
/// Called `WeatherFetcher` because WeatherKit already exports a `WeatherService`.
@Observable
final class WeatherFetcher {
    enum Status: Equatable {
        case idle, loading, loaded, failed
    }

    private(set) var status: Status = .idle
    /// Apple's mark and legal link, which WeatherKit's terms require showing
    /// wherever its data appears. Fetched once via `loadAttributionIfNeeded()`.
    private(set) var attribution: WeatherAttribution?

    /// A recording started within this much of now gets current conditions;
    /// anything older gets the forecast hour that contains its start time.
    var currentConditionsWindow: TimeInterval = 3 * 60 * 60

    private var task: Task<Void, Never>?

    private enum Failure: Error {
        case noCoordinates, noHourlyData
    }

    /// Overwrites every weather field on the recording. Cancels any fill still in flight.
    func fill(_ recording: Recording) {
        task?.cancel()
        task = Task {
            await run(recording)
        }
    }

    func loadAttributionIfNeeded() async {
        guard attribution == nil else { return }
        attribution = try? await WeatherService.shared.attribution
    }

    static func usesCurrentConditions(startedAt: Date, now: Date, window: TimeInterval) -> Bool {
        abs(now.timeIntervalSince(startedAt)) <= window
    }

    private func run(_ recording: Recording) async {
        status = .loading
        do {
            guard let latitude = recording.latitude, let longitude = recording.longitude else {
                throw Failure.noCoordinates
            }
            let location = CLLocation(latitude: latitude, longitude: longitude)
            let snapshot = try await snapshot(for: location, at: recording.startedAt)
            try Task.checkCancellation()
            snapshot.apply(to: recording)
            status = .loaded
        } catch {
            // A superseding fill sets its own status; don't overwrite it.
            guard !Task.isCancelled else { return }
            status = .failed
        }
    }

    private func snapshot(for location: CLLocation, at date: Date) async throws -> WeatherSnapshot {
        let service = WeatherService.shared
        if Self.usesCurrentConditions(startedAt: date, now: .now, window: currentConditionsWindow) {
            return WeatherSnapshot(try await service.weather(for: location, including: .current))
        }
        let hourly = try await service.weather(
            for: location,
            including: .hourly(startDate: date.addingTimeInterval(-3_600), endDate: date.addingTimeInterval(3_600))
        )
        guard let hour = hourly.forecast.last(where: { $0.date <= date }) ?? hourly.forecast.first else {
            throw Failure.noHourlyData
        }
        return WeatherSnapshot(hour)
    }
}
