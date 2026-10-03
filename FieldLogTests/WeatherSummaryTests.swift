import Foundation
import Testing

@testable import FieldLog

/// Unit strings follow the test runner's locale, so these assert the shape of
/// the line rather than exact numbers.
struct WeatherSummaryTests {
    @Test func nothingFetchedHasNoLine() {
        #expect(WeatherSummary.line(conditions: nil, temperatureC: nil, windSpeedKph: nil) == nil)
    }

    @Test func blankConditionsCountAsMissing() {
        #expect(WeatherSummary.line(conditions: "   ", temperatureC: nil, windSpeedKph: nil) == nil)
    }

    @Test func conditionsAloneAreTheWholeLine() {
        #expect(WeatherSummary.line(conditions: "Fog", temperatureC: nil, windSpeedKph: nil) == "Fog")
    }

    @Test func allThreeJoinWithMiddleDots() {
        let line = try! #require(WeatherSummary.line(conditions: "Fog", temperatureC: 12.5, windSpeedKph: 18))
        let parts = line.components(separatedBy: " · ")
        #expect(parts.count == 3)
        #expect(parts[0] == "Fog")
        #expect(parts[2].hasPrefix("wind "))
    }

    @Test func missingMiddleFieldDoesNotLeaveAnEmptyPart() {
        let line = try! #require(WeatherSummary.line(conditions: "Fog", temperatureC: nil, windSpeedKph: 18))
        #expect(line.components(separatedBy: " · ").count == 2)
        #expect(!line.contains("·  ·"))
    }

    @Test func temperatureAloneStillReads() {
        let line = try! #require(WeatherSummary.line(conditions: nil, temperatureC: 12.5, windSpeedKph: nil))
        #expect(!line.contains("·"))
        #expect(!line.isEmpty)
    }
}
