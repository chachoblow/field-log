import SwiftData
import SwiftUI
import UIKit

/// Place name and coordinates, with the location fix's progress and a way to
/// retry. iOS never re-prompts once permission is denied, so the denied state
/// links to the app's page in Settings instead.
struct WhereSection: View {
    @Bindable var recording: Recording
    @Environment(LocationService.self) private var locationService

    var body: some View {
        Section("Where") {
            TextField("Place", text: $recording.placeName.orEmpty)
            if locationService.status == .locating {
                LabeledContent("Locating…") { ProgressView() }
            }
            if let latitude = recording.latitude, let longitude = recording.longitude {
                LabeledContent("Coordinates") {
                    Text("\(latitude, format: .number.precision(.fractionLength(4))), \(longitude, format: .number.precision(.fractionLength(4)))")
                }
            }
            Button("Update Location", systemImage: "location") {
                locationService.fill(recording, replacingPlaceName: true)
            }
            .disabled(locationService.status == .locating)
            statusNote
        }
    }

    @ViewBuilder
    private var statusNote: some View {
        switch locationService.status {
        case .denied:
            VStack(alignment: .leading, spacing: 4) {
                Text("Location access is off for FieldLog.")
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    Link("Turn it on in Settings", destination: url)
                }
            }
            .font(.footnote)
        case .failed:
            Text("Couldn't get a location. Try again with a clearer view of the sky.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        case .idle, .locating, .located:
            EmptyView()
        }
    }
}

#Preview {
    NavigationStack {
        Form {
            WhereSection(recording: PreviewData.recordings[0])
        }
    }
    .modelContainer(PreviewData.container)
    .environment(LocationService())
}
