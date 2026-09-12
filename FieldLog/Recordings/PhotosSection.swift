import PhotosUI
import SwiftData
import SwiftUI

/// Recording form section: thumbnails of the attached library photos, a picker
/// to attach more, and a long-press menu to detach one. Detaching never touches
/// the library; the photo is only a reference.
struct PhotosSection: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(PhotoLibrary.self) private var library
    @Bindable var recording: Recording
    @State private var selection: [PhotosPickerItem] = []

    private var photos: [Photo] {
        (recording.photos ?? []).sorted { ($0.takenAt ?? .distantFuture) < ($1.takenAt ?? .distantFuture) }
    }

    var body: some View {
        Section("Photos") {
            if !photos.isEmpty {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 80), spacing: 8)], spacing: 8) {
                    ForEach(photos) { photo in
                        PhotoThumbnail(photo: photo)
                            .contextMenu {
                                Button("Remove Photo", systemImage: "trash", role: .destructive) { remove(photo) }
                            }
                    }
                }
                .padding(.vertical, 4)
            }
            // `.shared()` is the overload whose item identifiers are `PHAsset.localIdentifier`s.
            PhotosPicker(selection: $selection, matching: .images, photoLibrary: .shared()) {
                Label("Add Photos", systemImage: "photo.on.rectangle")
            }
            .onChange(of: selection) { _, items in attach(items) }
            accessNote
        }
    }

    @ViewBuilder
    private var accessNote: some View {
        if !photos.isEmpty, library.authorization == .denied || library.authorization == .restricted {
            Text("Thumbnails need Photos access. Turn it on in Settings › Apps › FieldLog.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private func attach(_ items: [PhotosPickerItem]) {
        guard !items.isEmpty else { return }
        let identifiers = PhotoLibrary.newIdentifiers(
            picked: items.map(\.itemIdentifier),
            existing: (recording.photos ?? []).map(\.assetIdentifier)
        )
        let added = identifiers.map { Photo(assetIdentifier: $0) }
        for photo in added {
            modelContext.insert(photo)
        }
        recording.photos = (recording.photos ?? []) + added
        try? modelContext.save()
        selection = []
        Task {
            for photo in added {
                photo.takenAt = await library.creationDate(for: photo.assetIdentifier)
            }
            try? modelContext.save()
        }
    }

    private func remove(_ photo: Photo) {
        recording.photos?.removeAll { $0 == photo }
        modelContext.delete(photo)
        try? modelContext.save()
    }
}

/// Square thumbnail loaded from the library on demand; a placeholder while
/// loading, and a different one if the asset is gone or unreadable.
private struct PhotoThumbnail: View {
    let photo: Photo
    @Environment(PhotoLibrary.self) private var library
    @Environment(\.displayScale) private var displayScale
    @State private var image: UIImage?
    @State private var isMissing = false

    private static let side: CGFloat = 120

    var body: some View {
        Color(.secondarySystemFill)
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: isMissing ? "photo.trianglebadge.exclamationmark" : "photo")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .accessibilityLabel(isMissing ? "Missing photo" : "Photo")
            .task(id: photo.assetIdentifier) {
                let pixels = Self.side * displayScale
                image = await library.thumbnail(for: photo.assetIdentifier, pixelSize: CGSize(width: pixels, height: pixels))
                isMissing = image == nil
            }
    }
}

#Preview {
    NavigationStack {
        Form {
            PhotosSection(recording: PreviewData.recordings[0])
        }
    }
    .modelContainer(PreviewData.container)
    .environment(PhotoLibrary())
}
