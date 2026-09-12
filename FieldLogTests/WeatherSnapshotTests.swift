import Foundation
import Testing
@testable import FieldLog

@MainActor
struct WeatherSnapshotTests {
    @Test func convertsToStoredUnits() {
        let snapshot = WeatherSnapshot(
            conditions: "Foggy",
            temperature: Measurement(value: 50, unit: .fahrenheit),
            windSpeed: Measurement(value: 10, unit: .milesPerHour),
            windDirection: Measurement(value: .pi / 2, unit: .radians),
            humidity: 0.93,
            pressure: Measurement(value: 30, unit: .inchesOfMercury),
            cloudCover: 0.8,
            precipitationIntensity: Measurement(value: 0.001 / 3_600, unit: .metersPerSecond)
        )
        let recording = Recording()

        snapshot.apply(to: recording)

        #expect(recording.weatherSummary == "Foggy")
        #expect(recording.temperatureC.map { abs($0 - 10) < 0.001 } == true)
        #expect(recording.windSpeedKph.map { abs($0 - 16.093) < 0.01 } == true)
        #expect(recording.windDirectionDeg.map { abs($0 - 90) < 0.001 } == true)
        #expect(recording.humidity == 0.93)
        #expect(recording.pressureHPa.map { abs($0 - 1015.9) < 0.1 } == true)
        #expect(recording.cloudCover == 0.8)
        #expect(recording.precipitationMmPerHour.map { abs($0 - 1) < 0.0001 } == true)
    }

    @Test func millimetersPerHourRoundTripsThroughMetersPerSecond() {
        let rate = Measurement(value: 7.2, unit: UnitSpeed.millimetersPerHour)
        let metersPerSecond = rate.converted(to: .metersPerSecond)
        #expect(abs(metersPerSecond.value - 0.000002) < 1e-12)
        #expect(abs(metersPerSecond.converted(to: .millimetersPerHour).value - 7.2) < 1e-9)
    }
}

struct WeatherFetcherTests {
    private let window: TimeInterval = 3 * 60 * 60

    @Test func recentStartUsesCurrentConditions() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        #expect(WeatherFetcher.usesCurrentConditions(startedAt: now.addingTimeInterval(-60), now: now, window: window))
        #expect(WeatherFetcher.usesCurrentConditions(startedAt: now.addingTimeInterval(-window), now: now, window: window))
    }

    @Test func olderStartUsesTheHour() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        #expect(!WeatherFetcher.usesCurrentConditions(startedAt: now.addingTimeInterval(-window - 1), now: now, window: window))
        #expect(!WeatherFetcher.usesCurrentConditions(startedAt: now.addingTimeInterval(-86_400), now: now, window: window))
    }

    @Test func futureStartBeyondTheWindowUsesTheHour() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        #expect(!WeatherFetcher.usesCurrentConditions(startedAt: now.addingTimeInterval(window + 1), now: now, window: window))
    }
}
