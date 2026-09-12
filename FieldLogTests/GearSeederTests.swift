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
