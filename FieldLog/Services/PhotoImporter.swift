import Foundation
import ImageIO
import UniformTypeIdentifiers

/// Turns picked or captured image bytes into what a `Photo` stores: an
/// upright JPEG no larger than `maxPixelSize` on its long side, plus the
/// capture date from the original's EXIF when it has one. ImageIO does the
/// decoding, so this works on any format the system can read (HEIC included)
/// and never needs UIKit. `nonisolated` because the views call it from a
/// detached task so decoding stays off the main thread.
nonisolated enum PhotoImporter {
    static let maxPixelSize = 2000
    static let jpegQuality = 0.85

    struct Imported: Equatable {
        var jpeg: Data
        var takenAt: Date?
    }

    /// nil when the data isn't a decodable image.
    static func importPhoto(_ data: Data, maxPixelSize: Int = maxPixelSize) -> Imported? {
        guard let image = cgImage(from: data, maxPixelSize: maxPixelSize),
              let jpeg = jpegData(encoding: image) else {
            return nil
        }
        return Imported(jpeg: jpeg, takenAt: captureDate(from: data))
    }

    /// Decodes at most `maxPixelSize` on the long side, never upscaling, with
    /// the EXIF orientation applied so the result is upright.
    static func cgImage(from data: Data, maxPixelSize: Int) -> CGImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
        ]
        return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
    }

    static func jpegData(encoding image: CGImage) -> Data? {
        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(output, UTType.jpeg.identifier as CFString, 1, nil) else {
            return nil
        }
        let properties = [kCGImageDestinationLossyCompressionQuality: jpegQuality] as CFDictionary
        CGImageDestinationAddImage(destination, image, properties)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return output as Data
    }

    /// EXIF `DateTimeOriginal`, in the zone EXIF `OffsetTimeOriginal` gives or
    /// the current one when absent. nil when the image carries no date.
    static func captureDate(from data: Data) -> Date? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let exif = properties[kCGImagePropertyExifDictionary] as? [CFString: Any],
              let dateString = exif[kCGImagePropertyExifDateTimeOriginal] as? String else {
            return nil
        }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        formatter.timeZone = timeZone(fromOffset: exif[kCGImagePropertyExifOffsetTimeOriginal] as? String) ?? .current
        return formatter.date(from: dateString)
    }

    /// "+02:00" / "-07:00" as EXIF writes it.
    private static func timeZone(fromOffset offset: String?) -> TimeZone? {
        guard let offset, offset.count == 6, let sign = offset.first, sign == "+" || sign == "-",
              let hours = Int(offset.dropFirst().prefix(2)), let minutes = Int(offset.suffix(2)) else {
            return nil
        }
        return TimeZone(secondsFromGMT: (sign == "-" ? -1 : 1) * (hours * 3_600 + minutes * 60))
    }
}
