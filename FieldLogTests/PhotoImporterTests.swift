import CoreGraphics
import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers
@testable import FieldLog

struct PhotoImporterTests {
    @Test func downscalesLargeImagesToTheLongSideLimit() throws {
        let imported = try #require(PhotoImporter.importPhoto(jpeg(width: 3_000, height: 2_000), maxPixelSize: 2_000))
        let size = try #require(pixelSize(of: imported.jpeg))
        #expect(size == (2_000, 1_333))
        #expect(imported.takenAt == nil)
    }

    @Test func leavesSmallImagesAlone() throws {
        let imported = try #require(PhotoImporter.importPhoto(jpeg(width: 640, height: 480)))
        let size = try #require(pixelSize(of: imported.jpeg))
        #expect(size == (640, 480))
    }

    @Test func readsTheCaptureDateFromExif() throws {
        let data = jpeg(width: 10, height: 10, exifDate: "2026:09:12 14:07:30", offset: "-07:00")
        let imported = try #require(PhotoImporter.importPhoto(data))
        var components = DateComponents(year: 2026, month: 9, day: 12, hour: 14, minute: 7, second: 30)
        components.timeZone = TimeZone(secondsFromGMT: -7 * 3_600)
        #expect(imported.takenAt == Calendar(identifier: .gregorian).date(from: components))
    }

    @Test func usesTheCurrentZoneWhenExifHasNoOffset() throws {
        let data = jpeg(width: 10, height: 10, exifDate: "2026:09:12 14:07:30")
        let date = try #require(PhotoImporter.captureDate(from: data))
        let parts = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        #expect(parts.hour == 14 && parts.minute == 7 && parts.second == 30 && parts.day == 12)
    }

    @Test func rejectsDataThatIsNotAnImage() {
        #expect(PhotoImporter.importPhoto(Data("not a photo".utf8)) == nil)
    }

    private func jpeg(width: Int, height: Int, exifDate: String? = nil, offset: String? = nil) -> Data {
        let context = CGContext(
            data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        )!
        context.setFillColor(red: 0.9, green: 0.5, blue: 0.1, alpha: 1)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        let image = context.makeImage()!
        let output = NSMutableData()
        let destination = CGImageDestinationCreateWithData(output, UTType.jpeg.identifier as CFString, 1, nil)!
        var exif: [CFString: Any] = [:]
        if let exifDate { exif[kCGImagePropertyExifDateTimeOriginal] = exifDate }
        if let offset { exif[kCGImagePropertyExifOffsetTimeOriginal] = offset }
        let properties: [CFString: Any] = exif.isEmpty ? [:] : [kCGImagePropertyExifDictionary: exif]
        CGImageDestinationAddImage(destination, image, properties as CFDictionary)
        CGImageDestinationFinalize(destination)
        return output as Data
    }

    private func pixelSize(of data: Data) -> (Int, Int)? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? Int,
              let height = properties[kCGImagePropertyPixelHeight] as? Int else {
            return nil
        }
        return (width, height)
    }
}
