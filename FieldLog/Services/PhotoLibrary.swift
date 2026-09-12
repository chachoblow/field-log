import Observation
import Photos
import UIKit

/// Read access to the Photos library for the assets a recording references.
/// App-wide, since authorization state is shared; held in the SwiftUI environment.
///
/// `PhotosPicker` runs out of process and needs no permission, but loading a
/// picked asset back by its identifier does. The first load prompts for
/// read-write access, which is the only level that allows reading. In limited
/// mode the user grants a subset of the library; anything picked through the
/// picker is added to that subset, so picked photos always load.
@Observable
final class PhotoLibrary {
    private(set) var authorization = PHPhotoLibrary.authorizationStatus(for: .readWrite)

    var canRead: Bool {
        authorization == .authorized || authorization == .limited
    }

    /// Prompts on first use. Skipped, and reports no access, when the app has no
    /// `NSPhotoLibraryUsageDescription`, because the prompt would crash the app.
    @discardableResult
    func requestAccessIfNeeded() async -> Bool {
        if authorization == .notDetermined, Self.hasUsageDescription {
            authorization = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        }
        return canRead
    }

    /// The asset's creation date, or nil without access or if it was deleted.
    func creationDate(for identifier: String) async -> Date? {
        await asset(for: identifier)?.creationDate
    }

    /// A thumbnail sized to fill `pixelSize`, or nil without access or if the
    /// asset was deleted. Fetches from iCloud if the original is not local.
    func thumbnail(for identifier: String, pixelSize: CGSize) async -> UIImage? {
        guard let asset = await asset(for: identifier) else { return nil }
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat   // one callback, not a degraded preview then the real image
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = true
        return await withCheckedContinuation { continuation in
            PHImageManager.default().requestImage(
                for: asset, targetSize: pixelSize, contentMode: .aspectFill, options: options
            ) { image, _ in
                continuation.resume(returning: image)
            }
        }
    }

    /// Identifiers from a picker selection worth attaching: real identifiers,
    /// not already on the recording, each once.
    static func newIdentifiers(picked: [String?], existing: [String]) -> [String] {
        var seen = Set(existing)
        return picked.compactMap { identifier in
            guard let identifier, seen.insert(identifier).inserted else { return nil }
            return identifier
        }
    }

    private func asset(for identifier: String) async -> PHAsset? {
        guard await requestAccessIfNeeded() else { return nil }
        return PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil).firstObject
    }

    private static let hasUsageDescription =
        Bundle.main.object(forInfoDictionaryKey: "NSPhotoLibraryUsageDescription") != nil
}
