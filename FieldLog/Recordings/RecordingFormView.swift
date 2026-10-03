import SwiftData
import SwiftUI

/// Create-and-edit form for one recording. Edits write straight to the model,
/// so there is no Save button. The context autosaves in the background and on
/// backgrounding; the explicit save on dismiss also covers an abrupt kill.
///
/// Section order follows the shape of a take: when it started, the kit and the
/// shots of the setup, then what gets written about the capture and its tags,
/// then the context that fills itself in. File and Review are last because
/// neither exists until after the recording does.
struct RecordingFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var recording: Recording

    var body: some View {
        Form {
            WhenSection(recording: recording)
            GearSection(recording: recording)
            PhotosSection(recording: recording)
            CaptureSection(recording: recording)
            TagsSection(recording: recording)
            WhereSection(recording: recording)
            WeatherSection(recording: recording)
            FileSection(recording: recording)
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
