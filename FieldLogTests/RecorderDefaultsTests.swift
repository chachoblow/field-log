import Foundation
import SwiftData
import Testing
@testable import FieldLog

@MainActor
struct RecorderDefaultsTests {
    @Test func fillsFormatFromSelectedRecorder() throws {
        let container = try ModelContainer.fieldLog(inMemory: true)
        let context = container.mainContext
        let recorder = Gear(name: "Zoom F3", type: "recorder", defaultSampleRateHz: 48_000, defaultBitDepth: "32-bit float")
        let recording = Recording(gear: [recorder])
        context.insert(recording)

        RecorderDefaults.apply(to: recording)

        #expect(recording.sampleRateHz == 48_000)
        #expect(recording.bitDepth == "32-bit float")
    }

    @Test func keepsManualChoices() throws {
        let container = try ModelContainer.fieldLog(inMemory: true)
        let context = container.mainContext
        let recorder = Gear(name: "Zoom F3", type: "recorder", defaultSampleRateHz: 48_000, defaultBitDepth: "32-bit float")
        let recording = Recording(sampleRateHz: 96_000, gear: [recorder])
        context.insert(recording)

        RecorderDefaults.apply(to: recording)

        #expect(recording.sampleRateHz == 96_000)
        #expect(recording.bitDepth == "32-bit float")
    }

    @Test func doesNothingWithoutARecorder() throws {
        let container = try ModelContainer.fieldLog(inMemory: true)
        let context = container.mainContext
        let mic = Gear(name: "LOM mikroUši", type: "mic")
        let recording = Recording(gear: [mic])
        context.insert(recording)

        RecorderDefaults.apply(to: recording)

        #expect(recording.sampleRateHz == nil)
        #expect(recording.bitDepth == nil)
    }
}
