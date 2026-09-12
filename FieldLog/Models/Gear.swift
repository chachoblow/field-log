import Foundation
import SwiftData

@Model
final class Gear {
    var name: String = ""
    var type: String = ""            // recorder | mic | windshield | mount | accessory
    var defaultSampleRateHz: Int?    // recorders only
    var defaultBitDepth: String?
    var recordings: [Recording]? = []
    var presets: [KitPreset]? = []

    init(
        name: String = "",
        type: String = "",
        defaultSampleRateHz: Int? = nil,
        defaultBitDepth: String? = nil
    ) {
        self.name = name
        self.type = type
        self.defaultSampleRateHz = defaultSampleRateHz
        self.defaultBitDepth = defaultBitDepth
    }
}
