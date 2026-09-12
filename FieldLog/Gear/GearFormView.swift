import SwiftData
import SwiftUI

/// Edits one piece of gear. Recorders also carry the format they default into a recording.
struct GearFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var gear: Gear

    var body: some View {
        Form {
            Section {
                TextField("Name", text: $gear.name)
                Picker("Type", selection: $gear.type) {
                    ForEach(GearType.allCases) { type in
                        Text(type.label).tag(type.rawValue)
                    }
                }
            }
            if gear.type == GearType.recorder.rawValue {
                Section("Recording defaults") {
                    SampleRatePicker(selection: $gear.defaultSampleRateHz)
                    BitDepthPicker(selection: $gear.defaultBitDepth)
                }
            }
        }
        .navigationTitle(gear.name.isEmpty ? "New Gear" : gear.name)
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { try? modelContext.save() }
    }
}

#Preview {
    NavigationStack {
        GearFormView(gear: Gear(name: "Zoom F3", type: "recorder", defaultSampleRateHz: 48_000, defaultBitDepth: "32-bit float"))
    }
    .modelContainer(PreviewData.container)
}
