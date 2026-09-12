import Foundation
import SwiftData

@Model
final class Photo {
    /// `PHAsset.localIdentifier` of a photo in the user's Photos library.
    /// The app references library photos rather than copying them; a deleted original shows as a placeholder.
    var assetIdentifier: String = ""
    var takenAt: Date?
    var recording: Recording?

    init(assetIdentifier: String = "", takenAt: Date? = nil) {
        self.assetIdentifier = assetIdentifier
        self.takenAt = takenAt
    }
}
