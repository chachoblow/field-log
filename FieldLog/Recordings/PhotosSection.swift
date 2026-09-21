import PhotosUI
import SwiftData
import SwiftUI

/// Recording form section: thumbnails of the stored photos, a camera button
/// and a library picker to add more, tap to view, long-press to remove.
/// The sheet and camera cover hang off the rows that trigger them; on the
/// `Section` itself they never present.
/// Photos are copied into the store at import; the library is never read
/// again afterwards, so no Photos permission is involved.
struct PhotosSection: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var recording: Recording
    @State private var selection: [PhotosPickerItem] = []
    @State private var isImporting = false
    @State private var isShowingCamera = false
    @State private var viewing: Photo?

    private var photos: [Photo] {
        (recording.photos ?? []).sorted { ($0.takenAt ?? .distantFuture) < ($1.takenAt ?? .distantFuture) }
    }

    var body: some View {
        Section("Photos") {
            if !photos.isEmpty {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 80), spacing: 8)], spacing: 8) {
                    ForEach(photos) { photo in
                        Button {
                            viewing = photo
                        } label: {
                            PhotoThumbnail(photo: photo)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button("Remove Photo", systemImage: "trash", role: .destructive) { remove(photo) }
                        }
                    }
                }
                .padding(.vertical, 4)
                .sheet(item: $viewing) { photo in
                    PhotoViewer(photo: photo)
                }
            }
            if CameraPicker.isAvailable {
                Button("Take Photo", systemImage: "camera") { isShowingCamera = true }
                    .fullScreenCover(isPresented: $isShowingCamera) {
                        CameraPicker { data in
                            Task { await add(data, takenAt: .now) }
                        }
                        .ignoresSafeArea()
                    }
            }
            PhotosPicker(selection: $selection, matching: .images) {
                Label("Add Photos", systemImage: "photo.on.rectangle")
            }
            .onChange(of: selection) { _, items in
                Task { await attach(items) }
            }
            if isImporting {
                LabeledContent("Importing…") { ProgressView() }
            }
        }
    }

    /// Picker items arrive as the original bytes (HEIC, JPEG, PNG…); each is
    /// downscaled and stored, keeping its EXIF date when it has one.
    private func attach(_ items: [PhotosPickerItem]) async {
        guard !items.isEmpty else { return }
        isImporting = true
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self) {
                await add(data, takenAt: nil)
            }
        }
        selection = []
        isImporting = false
    }

    /// `takenAt` overrides the image's own date; the camera passes now, since
    /// its JPEG has no EXIF date yet.
    private func add(_ data: Data, takenAt: Date?) async {
        guard let imported = await Task.detached(operation: { PhotoImporter.importPhoto(data) }).value else { return }
        let photo = Photo(imageData: imported.jpeg, takenAt: takenAt ?? imported.takenAt)
        modelContext.insert(photo)
        recording.photos = (recording.photos ?? []) + [photo]
        try? modelContext.save()
    }

    private func remove(_ photo: Photo) {
        recording.photos?.removeAll { $0 == photo }
        modelContext.delete(photo)
        try? modelContext.save()
    }
}

/// Square thumbnail decoded from the stored JPEG at thumbnail size, off the
/// main thread. A placeholder shows while decoding or if the data is missing.
private struct PhotoThumbnail: View {
    let photo: Photo
    @Environment(\.displayScale) private var displayScale
    @State private var image: CGImage?

    private static let side: CGFloat = 160

    var body: some View {
        Color(.secondarySystemFill)
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                if let image {
                    Image(decorative: image, scale: displayScale)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: "photo")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .contentShape(RoundedRectangle(cornerRadius: 8))
            .accessibilityLabel("Photo")
            .task(id: photo.persistentModelID) {
                guard let data = photo.imageData else { return }
                let pixels = Int(Self.side * displayScale)
                image = await Task.detached(operation: { PhotoImporter.cgImage(from: data, maxPixelSize: pixels) }).value
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
}
