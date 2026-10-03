import SwiftData
import SwiftUI
import WeatherKit

/// Stored weather for a recording, the fetch's progress, a way to refetch, and
/// the attribution WeatherKit's terms require: Apple's mark plus a link to its
/// legal page, kept as the section footer.
struct WeatherSection: View {
    let recording: Recording
    @Environment(WeatherFetcher.self) private var weatherFetcher
    @State private var showsAllReadings = false

    private var hasCoordinates: Bool {
        recording.latitude != nil && recording.longitude != nil
    }

    private var summary: String? {
        WeatherSummary.line(
            conditions: recording.weatherSummary,
            temperatureC: recording.temperatureC,
            windSpeedKph: recording.windSpeedKph
        )
    }

    var body: some View {
        Section {
            if weatherFetcher.status == .loading {
                LabeledContent("Loading weather…") { ProgressView() }
            }
            if let summary {
                DisclosureGroup(isExpanded: $showsAllReadings) {
                    WeatherRows(recording: recording)
                } label: {
                    Text(summary)
                }
            }
            Button("Update Weather", systemImage: "cloud.sun") {
                weatherFetcher.fill(recording)
            }
            .disabled(weatherFetcher.status == .loading || !hasCoordinates)
            statusNote
        } header: {
            Text("Weather")
        } footer: {
            if let attribution = weatherFetcher.attribution {
                WeatherAttributionFooter(attribution: attribution)
            }
        }
        .task { await weatherFetcher.loadAttributionIfNeeded() }
    }

    @ViewBuilder
    private var statusNote: some View {
        if !hasCoordinates {
            Text("Weather needs a location first.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        } else if weatherFetcher.status == .failed {
            Text("Couldn't get weather. Check the connection and try again.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}

/// One row per stored field that has a value, shown when the section is expanded.
private struct WeatherRows: View {
    let recording: Recording

    var body: some View {
        if let summary = recording.weatherSummary {
            LabeledContent("Conditions", value: summary)
        }
        if let temperature = recording.temperatureC {
            LabeledContent("Temperature") {
                Text(
                    Measurement(value: temperature, unit: UnitTemperature.celsius),
                    format: .measurement(width: .abbreviated, numberFormatStyle: .number.precision(.fractionLength(0)))
                )
            }
        }
        if let speed = recording.windSpeedKph {
            LabeledContent("Wind") {
                Text(
                    Measurement(value: speed, unit: UnitSpeed.kilometersPerHour),
                    format: .measurement(width: .abbreviated, numberFormatStyle: .number.precision(.fractionLength(0)))
                )
            }
        }
        if let direction = recording.windDirectionDeg {
            LabeledContent("Wind direction") {
                Text("\(direction, format: .number.precision(.fractionLength(0)))°")
            }
        }
        if let humidity = recording.humidity {
            LabeledContent("Humidity") {
                Text(humidity, format: .percent.precision(.fractionLength(0)))
            }
        }
        if let pressure = recording.pressureHPa {
            LabeledContent("Pressure") {
                // `.asProvided` keeps hPa; the locale default converts to psi in the US, which no forecast uses.
                Text(
                    Measurement(value: pressure, unit: UnitPressure.hectopascals),
                    format: .measurement(width: .abbreviated, usage: .asProvided, numberFormatStyle: .number.precision(.fractionLength(0)))
                )
            }
        }
        if let cloudCover = recording.cloudCover {
            LabeledContent("Cloud cover") {
                Text(cloudCover, format: .percent.precision(.fractionLength(0)))
            }
        }
        if let rate = recording.precipitationMmPerHour {
            LabeledContent("Precipitation") {
                Text(
                    Measurement(value: rate, unit: UnitSpeed.millimetersPerHour),
                    format: .measurement(width: .abbreviated, usage: .asProvided, numberFormatStyle: .number.precision(.fractionLength(1)))
                )
            }
        }
    }
}

private struct WeatherAttributionFooter: View {
    let attribution: WeatherAttribution
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 8) {
            AsyncImage(url: colorScheme == .dark ? attribution.combinedMarkDarkURL : attribution.combinedMarkLightURL) { image in
                image.resizable().scaledToFit()
            } placeholder: {
                Text(attribution.serviceName)
            }
            .frame(height: 14)
            Link("Weather data sources", destination: attribution.legalPageURL)
        }
    }
}

#Preview {
    NavigationStack {
        Form {
            WeatherSection(recording: PreviewData.recordings[0])
        }
    }
    .modelContainer(PreviewData.container)
    .environment(WeatherFetcher())
}
