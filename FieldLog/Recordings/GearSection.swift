import SwiftData
import SwiftUI

/// Recording form section: apply a preset in one tap or pick gear by hand.
/// Any change re-runs `RecorderDefaults` so a recorder fills in the format.
struct GearSection: View {
    @Bindable var recording: Recording
    @Query(sort: \KitPreset.name) private var presets: [KitPreset]

    private var selection: Binding<[Gear]> {
        Binding(
            get: { recording.gear ?? [] },
            set: {
                recording.gear = $0
                RecorderDefaults.apply(to: recording)
            }
        )
    }

    private var summary: String {
        let names = (recording.gear ?? []).map(\.name).sorted()
        return names.isEmpty ? "None" : names.joined(separator: ", ")
    }

    var body: some View {
        Section("Gear") {
            if !presets.isEmpty {
                Menu {
                    ForEach(presets) { preset in
                        Button(preset.name) { selection.wrappedValue = preset.gear ?? [] }
                    }
                } label: {
                    // Fill the row so a tap anywhere on it opens the menu, not just on the text.
                    Text("Apply Preset")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                }
            }
            NavigationLink {
                GearPickerView(selection: selection)
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Selected")
                    Text(summary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
