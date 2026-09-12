import Foundation
import SwiftData
import Testing
@testable import FieldLog

@MainActor
struct GearSeederTests {
    @Test func seedsRecordersIntoEmptyStore() throws {
        let container = try ModelContainer.fieldLog(inMemory: true)
        let context = container.mainContext

        let didSeed = try GearSeeder.seedIfNeeded(context: context)

        #expect(didSeed)
        let names = try context.fetch(FetchDescriptor<Gear>()).map(\.name)
        #expect(Set(names) == Set(GearSeeder.gear.map(\.name)))
        let recorder = try #require(try context.fetch(FetchDescriptor<Gear>()).first { $0.name == "Zoom F3" })
        #expect(recorder.type == "recorder")
        #expect(recorder.defaultSampleRateHz == 48_000)
        #expect(recorder.defaultBitDepth == "32-bit float")
    }

    @Test func seedsEveryTypeAndAllPresets() throws {
        let container = try ModelContainer.fieldLog(inMemory: true)
        let context = container.mainContext

        try GearSeeder.seedIfNeeded(context: context)

        let gear = try context.fetch(FetchDescriptor<Gear>())
        #expect(gear.count == 13)
        #expect(Set(gear.map(\.type)) == ["recorder", "mic", "windshield", "mount", "accessory"])
        #expect(Set(gear.map(\.name)).count == gear.count, "gear names must be unique")

        let presets = try context.fetch(FetchDescriptor<KitPreset>())
        #expect(presets.count == 3)
        for seed in GearSeeder.presets {
            let preset = try #require(presets.first { $0.name == seed.name })
            #expect(Set((preset.gear ?? []).map(\.name)) == Set(seed.gearNames), "every gear name in \(seed.name) must resolve")
            #expect(preset.gear?.contains { $0.type == "recorder" } == true, "\(seed.name) needs a recorder")
        }
    }

    @Test func secondCallIsNoOp() throws {
        let container = try ModelContainer.fieldLog(inMemory: true)
        let context = container.mainContext

        try GearSeeder.seedIfNeeded(context: context)
        let didSeedAgain = try GearSeeder.seedIfNeeded(context: context)

        #expect(!didSeedAgain)
        #expect(try context.fetchCount(FetchDescriptor<Gear>()) == GearSeeder.gear.count)
    }

    @Test func doesNotSeedWhenGearAlreadyExists() throws {
        let container = try ModelContainer.fieldLog(inMemory: true)
        let context = container.mainContext
        context.insert(Gear(name: "User mic", type: "mic"))
        try context.save()

        let didSeed = try GearSeeder.seedIfNeeded(context: context)

        #expect(!didSeed)
        #expect(try context.fetchCount(FetchDescriptor<Gear>()) == 1)
    }
}
