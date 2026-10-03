import SwiftData
import SwiftUI

/// Create-and-edit form for one recording. Edits write straight to the model,
/// so there is no Save button. The context autosaves in the background and on
/// backgrounding; the explicit save on dismiss also covers an abrupt kill.
///
/// Section order follows what the form is for: the entry is filled in after the
/// recording, so the start time (which defaults to now and usually needs
/// correcting) and the fields that are typed come first, and the auto-filled
/// context sits below them. Review is last because it happens days later.
struct RecordingFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var recording: Recording

    var body: some View {
        Form {
            WhenSection(recording: recording)
            CaptureSection(recording: recording)
            GearSection(recording: recording)
            TagsSection(recording: recording)
            PhotosSection(recording: recording)
            FileSection(recording: recording)
            WhereSection(recording: recording)
            WeatherSection(recording: recording)
            ReviewSection(recording: recording)
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
}

#Preview("Without filename") {
    NavigationStack {
        RecordingFormView(recording: PreviewData.recordings[1])
    }
    .modelContainer(PreviewData.container)
    .environment(LocationService())
    .environment(WeatherFetcher())
}
