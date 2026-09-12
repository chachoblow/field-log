import SwiftData
import SwiftUI

/// Manages the gear reference table and kit presets. Presented as a sheet
/// from the recording list, so it owns its own navigation stack.
struct GearListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: [SortDescriptor(\Gear.name, comparator: .localizedStandard)]) private var gear: [Gear]
    @Query(sort: \KitPreset.name) private var presets: [KitPreset]
    @State private var path = NavigationPath()

    private var gearByType: [String: [Gear]] {
        Dictionary(grouping: gear, by: \.type)
    }

    var body: some View {
        NavigationStack(path: $path) {
            List {
                ForEach(GearType.allCases) { type in
                    if let items = gearByType[type.rawValue] {
                        Section(type.pluralLabel) {
                            ForEach(items) { item in
                                NavigationLink(value: item) {
                                    Text(item.name.isEmpty ? "Untitled" : item.name)
                                }
                            }
                            .onDelete { offsets in delete(items, at: offsets) }
                        }
                    }
                }
                Section("Presets") {
                    ForEach(presets) { preset in
                        NavigationLink(value: preset) {
                            LabeledContent(preset.name.isEmpty ? "Untitled" : preset.name) {
                                Text("^[\(preset.gear?.count ?? 0) item](inflect: true)")
                            }
                        }
                    }
                    .onDelete { offsets in delete(presets, at: offsets) }
                }
            }
            .navigationTitle("Gear")
            .navigationDestination(for: Gear.self) { GearFormView(gear: $0) }
            .navigationDestination(for: KitPreset.self) { KitPresetFormView(preset: $0) }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Menu("Add", systemImage: "plus") {
                        Button("New Gear", systemImage: "mic", action: addGear)
                        Button("New Preset", systemImage: "backpack", action: addPreset)
                    }
                }
            }
        }
    }

    private func addGear() {
        let item = Gear(type: GearType.mic.rawValue)
        modelContext.insert(item)
        try? modelContext.save()
        path.append(item)
    }

    private func addPreset() {
        let preset = KitPreset()
        modelContext.insert(preset)
        try? modelContext.save()
        path.append(preset)
    }

    private func delete<Model: PersistentModel>(_ items: [Model], at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(items[index])
        }
        try? modelContext.save()
    }
}

#Preview {
    GearListView()
        .modelContainer(PreviewData.container)
}
