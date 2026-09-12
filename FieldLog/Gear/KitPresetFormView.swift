import SwiftData
import SwiftUI

/// Edits one kit preset: a name and the gear it fills into a recording.
struct KitPresetFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var preset: KitPreset

    var body: some View {
        Form {
            Section {
                TextField("Name", text: $preset.name)
            }
            GearChecklistSections(selection: $preset.gear.orEmptyArray())
        }
        .navigationTitle(preset.name.isEmpty ? "New Preset" : preset.name)
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { try? modelContext.save() }
    }
}

#Preview {
    NavigationStack {
        KitPresetFormView(preset: KitPreset(name: "Field kit"))
    }
    .modelContainer(PreviewData.container)
}
