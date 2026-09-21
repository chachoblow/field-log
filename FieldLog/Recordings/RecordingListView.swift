import SwiftData
import SwiftUI

/// Root screen: every recording, newest first.
struct RecordingListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(LocationService.self) private var locationService
    @Environment(WeatherFetcher.self) private var weatherFetcher
    @Query(sort: \Recording.startedAt, order: .reverse) private var recordings: [Recording]
    @State private var path = NavigationPath()
    @State private var isShowingGear = false

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
                ToolbarItem(placement: .topBarLeading) {
                    Button("Gear", systemImage: "backpack") { isShowingGear = true }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("New Recording", systemImage: "plus", action: addRecording)
                }
            }
            .sheet(isPresented: $isShowingGear) {
                GearListView()
            }
        }
    }

    private func addRecording() {
        let recording = Recording()
        modelContext.insert(recording)
        try? modelContext.save()
        path.append(recording)
        Task {
            await locationService.fill(recording).value
            if recording.latitude != nil {
                weatherFetcher.fill(recording)
            }
        }
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
        .environment(LocationService())
        .environment(WeatherFetcher())
    }

#Preview("Empty") {
    RecordingListView()
        .modelContainer(try! ModelContainer.fieldLog(inMemory: true))
        .environment(LocationService())
        .environment(WeatherFetcher())
    }
