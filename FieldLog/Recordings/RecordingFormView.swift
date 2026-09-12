import SwiftData
import SwiftUI

/// Create-and-edit form for one recording. Edits write straight to the model,
/// so there is no Save button. The context autosaves in the background and on
/// backgrounding; the explicit save on dismiss also covers an abrupt kill.
struct RecordingFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var recording: Recording

    var body: some View {
        Form {
            WhenSection(recording: recording)
            WhereSection(recording: recording)
            WeatherSection(recording: recording)
            GearSection(recording: recording)
            FileSection(recording: recording)
            CaptureSection(recording: recording)
            MarkersSection(recording: recording)
            PhotosSection(recording: recording)
            ReviewSection(recording: recording)
            TagsSection(recording: recording)
        }
        .navigationTitle(Text(recording.startedAt, format: .dateTime.month().day().year()))
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { try? modelContext.save() }
    }
}

#Preview("With filename") {
    NavigationStack {
        RecordingFormView(recording: PreviewData.recordings[0])
    }
    .modelContainer(PreviewData.container)
    .environment(LocationService())
    .environment(WeatherFetcher())
    .environment(PhotoLibrary())
}

#Preview("Without filename") {
    NavigationStack {
        RecordingFormView(recording: PreviewData.recordings[1])
    }
    .modelContainer(PreviewData.container)
    .environment(LocationService())
    .environment(WeatherFetcher())
    .environment(PhotoLibrary())
}
