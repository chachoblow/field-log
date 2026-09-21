import Foundation
import SwiftData

@Model
final class Photo {
    /// A JPEG downscaled at import (see `PhotoImporter`). The app owns the
    /// bytes, so viewing needs no Photos permission and nothing goes missing
    /// if the library changes. External storage keeps the blob out of the
    /// SQLite file; CloudKit would sync it as an asset.
    @Attribute(.externalStorage) var imageData: Data?
    var takenAt: Date?
    var recording: Recording?

    init(imageData: Data? = nil, takenAt: Date? = nil) {
        self.imageData = imageData
        self.takenAt = takenAt
    }
}
