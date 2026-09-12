import SwiftData
import SwiftUI

struct WhenSection: View {
    @Bindable var recording: Recording

    private var hasEnded: Binding<Bool> {
        Binding(
            get: { recording.endedAt != nil },
            set: { recording.endedAt = $0 ? max(.now, recording.startedAt) : nil }
        )
    }

    var body: some View {
        Section("When") {
            DatePicker("Started", selection: $recording.startedAt)
            Toggle("Ended", isOn: hasEnded)
            if recording.endedAt != nil {
                DatePicker(
                    "Ended",
                    selection: Binding(
                        get: { recording.endedAt ?? recording.startedAt },
                        set: { recording.endedAt = $0 }
                    ),
                    in: recording.startedAt...
                )
            }
        }
    }
}

struct WeatherSection: View {
    let recording: Recording

    private var hasWeather: Bool {
        recording.weatherSummary != nil
            || recording.temperatureC != nil
            || recording.windSpeedKph != nil
            || recording.windDirectionDeg != nil
    }

    var body: some View {
        if hasWeather {
            Section("Weather") {
                if let summary = recording.weatherSummary {
                    LabeledContent("Conditions", value: summary)
                }
                if let temperature = recording.temperatureC {
                    LabeledContent("Temperature") {
                        Text(Measurement(value: temperature, unit: UnitTemperature.celsius), format: .measurement(width: .abbreviated))
                    }
                }
                if let speed = recording.windSpeedKph {
                    LabeledContent("Wind") {
                        Text(Measurement(value: speed, unit: UnitSpeed.kilometersPerHour), format: .measurement(width: .abbreviated))
                    }
                }
                if let direction = recording.windDirectionDeg {
                    LabeledContent("Wind direction") {
                        Text("\(direction, format: .number.precision(.fractionLength(0)))°")
                    }
                }
            }
        }
    }
}

struct FileSection: View {
    @Bindable var recording: Recording

    var body: some View {
        Section("File") {
            TextField("Filename", text: $recording.filename.orEmpty)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            SampleRatePicker(selection: $recording.sampleRateHz)
            BitDepthPicker(selection: $recording.bitDepth)
        }
    }
}

struct CaptureSection: View {
    @Bindable var recording: Recording

    var body: some View {
        Section("Capture") {
            TextField("Mic technique", text: $recording.micTechnique.orEmpty)
            TextField("Description", text: $recording.captureDescription, axis: .vertical)
                .lineLimit(3...)
            Toggle("Compromised", isOn: $recording.isCompromised)
        }
    }
}

struct ReviewSection: View {
    @Bindable var recording: Recording

    var body: some View {
        Section("Review") {
            TextField("Notes", text: $recording.notes, axis: .vertical)
                .lineLimit(3...)
            Picker("Rating", selection: $recording.rating) {
                Text("None").tag(Int?.none)
                ForEach(1...5, id: \.self) { stars in
                    Text(String(repeating: "★", count: stars)).tag(Int?.some(stars))
                }
            }
        }
    }
}
