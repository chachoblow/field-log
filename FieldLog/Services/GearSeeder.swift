import Foundation
import SwiftData

/// Inserts the default gear and kit presets on first launch.
/// Does nothing if the `Gear` table already has rows, so it is safe to call every launch.
enum GearSeeder {
    struct GearSeed {
        let name: String
        let type: String
        var defaultSampleRateHz: Int? = nil
        var defaultBitDepth: String? = nil
    }

    struct PresetSeed {
        let name: String
        let gearNames: [String]
    }

    static let gear: [GearSeed] = [
        GearSeed(name: "Zoom F3", type: "recorder", defaultSampleRateHz: 48_000, defaultBitDepth: "32-bit float"),
        GearSeed(name: "Zoom H5studio", type: "recorder", defaultSampleRateHz: 48_000, defaultBitDepth: "32-bit float"),
    ]

    /// Empty until the real mic, windshield, mount, and accessory list is known.
    static let presets: [PresetSeed] = []

    @discardableResult
    static func seedIfNeeded(context: ModelContext) throws -> Bool {
        var descriptor = FetchDescriptor<Gear>()
        descriptor.fetchLimit = 1
        guard try context.fetchCount(descriptor) == 0 else { return false }

        var byName: [String: Gear] = [:]
        for seed in gear {
            let item = Gear(
                name: seed.name,
                type: seed.type,
                defaultSampleRateHz: seed.defaultSampleRateHz,
                defaultBitDepth: seed.defaultBitDepth
            )
            context.insert(item)
            byName[seed.name] = item
        }

        for seed in presets {
            let preset = KitPreset(name: seed.name, gear: seed.gearNames.compactMap { byName[$0] })
            context.insert(preset)
        }

        try context.save()
        return true
    }
}
