import SwiftData
import SwiftUI

/// Full-size view of one stored photo, presented as a sheet from the form.
struct PhotoViewer: View {
    let photo: Photo
    @Environment(\.dismiss) private var dismiss
    @Environment(\.displayScale) private var displayScale
    @State private var image: CGImage?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                if let image {
                    Image(decorative: image, scale: displayScale)
                        .resizable()
                        .scaledToFit()
                } else {
                    ProgressView()
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
        .task {
            guard let data = photo.imageData else { return }
            image = await Task.detached(operation: { PhotoImporter.cgImage(from: data, maxPixelSize: PhotoImporter.maxPixelSize) }).value
        }
    }

    private var title: Text {
        if let takenAt = photo.takenAt {
            Text(takenAt, format: .dateTime.month().day().hour().minute())
        } else {
            Text("Photo")
        }
    }
}

#Preview {
    PhotoViewer(photo: PreviewData.recordings[0].photos!.first!)
        .modelContainer(PreviewData.container)
}
