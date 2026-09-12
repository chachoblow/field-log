import SwiftData
import SwiftUI

/// Root screen: every recording, newest first.
struct RecordingListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Recording.startedAt, order: .reverse) private var recordings: [Recording]
    @State private var path: [Recording] = []

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if recordings.isEmpty {
                    ContentUnavailableView(
                        "No Recordings",
                        systemImage: "waveform",
                        description: Text("Tap + to log your first recording.")
                    )
                } else {
                    List {
                        ForEach(recordings) { recording in
                            NavigationLink(value: recording) {
                                RecordingRow(recording: recording)
                            }
                        }
                        .onDelete(perform: deleteRecordings)
                    }
                }
            }
            .navigationTitle("Recordings")
            .navigationDestination(for: Recording.self) { recording in
                RecordingFormView(recording: recording)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("New Recording", systemImage: "plus", action: addRecording)
                }
            }
        }
    }

    private func addRecording() {
        let recording = Recording()
        modelContext.insert(recording)
        try? modelContext.save()
        path.append(recording)
    }

    private func deleteRecordings(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(recordings[index])
        }
        try? modelContext.save()
    }
}

#Preview("Recordings") {
    RecordingListView()
        .modelContainer(PreviewData.container)
}

#Preview("Empty") {
    RecordingListView()
        .modelContainer(try! ModelContainer.fieldLog(inMemory: true))
}
