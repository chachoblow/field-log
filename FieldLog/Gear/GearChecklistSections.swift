import SwiftData
import SwiftUI

/// One section per gear type; tapping a row toggles its membership in `selection`.
/// Drop it inside any `List` or `Form`.
struct GearChecklistSections: View {
    @Query(sort: [SortDescriptor(\Gear.name, comparator: .localizedStandard)]) private var allGear: [Gear]
    @Binding var selection: [Gear]

    var body: some View {
        ForEach(GearType.allCases) { type in
            let items = allGear.filter { $0.type == type.rawValue }
            if !items.isEmpty {
                Section(type.pluralLabel) {
                    ForEach(items) { item in
                        Button {
                            toggle(item)
                        } label: {
                            HStack {
                                Text(item.name.isEmpty ? "Untitled" : item.name)
                                Spacer()
                                if selection.contains(item) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.tint)
                                }
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                }
            }
        }
    }

    private func toggle(_ item: Gear) {
        if let index = selection.firstIndex(of: item) {
            selection.remove(at: index)
        } else {
            selection.append(item)
        }
    }
}

/// Full-screen checklist pushed from the recording form.
struct GearPickerView: View {
    @Binding var selection: [Gear]

    var body: some View {
        List {
            GearChecklistSections(selection: $selection)
        }
        .navigationTitle("Gear")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    @Previewable @State var selection: [Gear] = []
    NavigationStack {
        GearPickerView(selection: $selection)
    }
    .modelContainer(PreviewData.container)
}
