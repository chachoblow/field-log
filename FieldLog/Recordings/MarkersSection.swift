import SwiftData
import SwiftUI

/// Recording form section: markers in time order, each with an editable note,
/// and a button that drops a new one at the current offset from the start time.
struct MarkersSection: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var recording: Recording
    @FocusState private var focusedNote: PersistentIdentifier?

    private var markers: [Marker] {
        (recording.markers ?? []).sorted { $0.offsetSeconds < $1.offsetSeconds }
    }

    var body: some View {
        Section("Markers") {
            ForEach(markers) { marker in
                MarkerRow(marker: marker)
                    .focused($focusedNote, equals: marker.persistentModelID)
            }
            .onDelete(perform: delete)
            Button("Add Marker", systemImage: "flag", action: add)
        }
    }

    private func add() {
        let marker = Marker(offsetSeconds: MarkerOffset.seconds(from: recording.startedAt))
        modelContext.insert(marker)
        recording.markers = (recording.markers ?? []) + [marker]
        try? modelContext.save()
        focusedNote = marker.persistentModelID
    }

    private func delete(at offsets: IndexSet) {
        let doomed = offsets.map { markers[$0] }
        recording.markers?.removeAll { doomed.contains($0) }
        for marker in doomed {
            modelContext.delete(marker)
        }
        try? modelContext.save()
    }
}

private struct MarkerRow: View {
    @Bindable var marker: Marker

    var body: some View {
        HStack {
            Text(MarkerOffset.label(marker.offsetSeconds))
                .monospacedDigit()
                .foregroundStyle(.secondary)
            TextField("Note", text: $marker.note)
        }
    }
}

#Preview {
    NavigationStack {
        Form {
            MarkersSection(recording: PreviewData.recordings[0])
        }
    }
    .modelContainer(PreviewData.container)
}
