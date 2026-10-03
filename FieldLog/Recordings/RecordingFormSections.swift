import SwiftData
import SwiftUI

struct WhenSection: View {
    @Bindable var recording: Recording

    var body: some View {
        Section("When") {
            DatePicker("Started", selection: $recording.startedAt)
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
            TextField("Description", text: $recording.captureDescription, axis: .vertical)
                .lineLimit(3...)
            TextField("Mic technique", text: $recording.micTechnique.orEmpty)
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
