import Foundation
import WeatherKit

/// The eight weather fields FieldLog stores, held in WeatherKit's own units
/// until `apply(to:)` converts them to the stored ones. A plain value so the
/// conversion can be unit tested; WeatherKit's types have no public initializers.
struct WeatherSnapshot: Equatable {
    var conditions: String
    var temperature: Measurement<UnitTemperature>
    var windSpeed: Measurement<UnitSpeed>
    var windDirection: Measurement<UnitAngle>
    var humidity: Double                    // 0–1
    var pressure: Measurement<UnitPressure>
    var cloudCover: Double                  // 0–1
    var precipitationIntensity: Measurement<UnitSpeed>

    init(
        conditions: String,
        temperature: Measurement<UnitTemperature>,
        windSpeed: Measurement<UnitSpeed>,
        windDirection: Measurement<UnitAngle>,
        humidity: Double,
        pressure: Measurement<UnitPressure>,
        cloudCover: Double,
        precipitationIntensity: Measurement<UnitSpeed>
    ) {
        self.conditions = conditions
        self.temperature = temperature
        self.windSpeed = windSpeed
        self.windDirection = windDirection
        self.humidity = humidity
        self.pressure = pressure
        self.cloudCover = cloudCover
        self.precipitationIntensity = precipitationIntensity
    }

    init(_ current: CurrentWeather) {
        self.init(
            conditions: current.condition.description,
            temperature: current.temperature,
            windSpeed: current.wind.speed,
            windDirection: current.wind.direction,
            humidity: current.humidity,
            pressure: current.pressure,
            cloudCover: current.cloudCover,
            precipitationIntensity: current.precipitationIntensity
        )
    }

    /// An hour's total precipitation is numerically its rate per hour.
    init(_ hour: HourWeather) {
        self.init(
            conditions: hour.condition.description,
            temperature: hour.temperature,
            windSpeed: hour.wind.speed,
            windDirection: hour.wind.direction,
            humidity: hour.humidity,
            pressure: hour.pressure,
            cloudCover: hour.cloudCover,
            precipitationIntensity: Measurement(
                value: hour.precipitationAmount.converted(to: .millimeters).value,
                unit: .millimetersPerHour
            )
        )
    }

    /// Writes every field, converted to the units the model documents.
    func apply(to recording: Recording) {
        recording.weatherSummary = conditions
        recording.temperatureC = temperature.converted(to: .celsius).value
        recording.windSpeedKph = windSpeed.converted(to: .kilometersPerHour).value
        recording.windDirectionDeg = windDirection.converted(to: .degrees).value
        recording.humidity = humidity
        recording.pressureHPa = pressure.converted(to: .hectopascals).value
        recording.cloudCover = cloudCover
        recording.precipitationMmPerHour = precipitationIntensity.converted(to: .millimetersPerHour).value
    }
}

extension UnitSpeed {
    /// Foundation has no rainfall-rate unit; WeatherKit reports intensity as a speed.
    static let millimetersPerHour = UnitSpeed(
        symbol: "mm/h",
        converter: UnitConverterLinear(coefficient: 0.001 / 3_600)
    )
}
