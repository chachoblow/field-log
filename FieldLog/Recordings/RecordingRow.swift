import SwiftData
import SwiftUI

/// One line in the recording list: when, where, and whether the file is named yet.
struct RecordingRow: View {
    let recording: Recording

    private var hasFilename: Bool {
        !(recording.filename ?? "").isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(recording.startedAt, format: .dateTime.month().day().year().hour().minute())
                Spacer()
                if !hasFilename {
                    Text("No filename")
                        .font(.caption2.weight(.medium))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.orange.opacity(0.15), in: Capsule())
                        .foregroundStyle(.orange)
                }
            }
            Text(recording.placeName ?? "No location")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    List(PreviewData.recordings) { recording in
        RecordingRow(recording: recording)
    }
    .modelContainer(PreviewData.container)
}
