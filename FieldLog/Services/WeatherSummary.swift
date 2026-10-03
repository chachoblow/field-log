import Foundation

/// The one-line glance the Weather section shows before it is expanded, built
/// from whichever stored fields have values.
enum WeatherSummary {
    /// Conditions, temperature, and wind joined with middle dots, or nil when
    /// nothing has been fetched. Wind carries its own word because a bare
    /// number next to a temperature reads as a second temperature. Units follow
    /// the locale, matching the detail rows.
    static func line(conditions: String?, temperatureC: Double?, windSpeedKph: Double?) -> String? {
        var parts: [String] = []
        if let conditions = nonBlank(conditions) {
            parts.append(conditions)
        }
        if let temperatureC {
            parts.append(whole(Measurement(value: temperatureC, unit: UnitTemperature.celsius)))
        }
        if let windSpeedKph {
            parts.append("wind " + whole(Measurement(value: windSpeedKph, unit: UnitSpeed.kilometersPerHour)))
        }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    private static func whole<U: Dimension>(_ measurement: Measurement<U>) -> String {
        measurement.formatted(
            .measurement(width: .abbreviated, numberFormatStyle: .number.precision(.fractionLength(0)))
        )
    }

    private static func nonBlank(_ text: String?) -> String? {
        guard let trimmed = text?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else {
            return nil
        }
        return trimmed
    }
}
