import Foundation
import SwiftData
import Testing
@testable import FieldLog

@MainActor
struct ModelTests {
    @Test func recordingRoundTrips() throws {
        let container = try ModelContainer.fieldLog(inMemory: true)
        let context = container.mainContext
        let started = Date(timeIntervalSince1970: 1_800_000_000)
        let recording = Recording(
            startedAt: started,
            latitude: 38.0,
            longitude: -123.0,
            placeName: "Point Reyes",
            weatherSummary: "Fog",
            temperatureC: 12.5,
            filename: "ZOOM0001.WAV",
            sampleRateHz: 48_000,
            bitDepth: "32-bit float",
            micTechnique: "ORTF",
            captureDescription: "Surf and gulls",
            isCompromised: true,
            rating: 4
        )
        context.insert(recording)
        try context.save()

        let fetched = try #require(try context.fetch(FetchDescriptor<Recording>()).first)
        #expect(fetched.startedAt == started)
        #expect(fetched.endedAt == nil)
        #expect(fetched.latitude == 38.0)
        #expect(fetched.longitude == -123.0)
        #expect(fetched.placeName == "Point Reyes")
        #expect(fetched.weatherSummary == "Fog")
        #expect(fetched.temperatureC == 12.5)
        #expect(fetched.filename == "ZOOM0001.WAV")
        #expect(fetched.sampleRateHz == 48_000)
        #expect(fetched.bitDepth == "32-bit float")
        #expect(fetched.micTechnique == "ORTF")
        #expect(fetched.captureDescription == "Surf and gulls")
        #expect(fetched.notes == "")
        #expect(fetched.isCompromised)
        #expect(fetched.rating == 4)
    }

    @Test func gearRoundTripsAndLinksToRecordings() throws {
        let container = try ModelContainer.fieldLog(inMemory: true)
        let context = container.mainContext
        let recorder = Gear(name: "Zoom F3", type: "recorder", defaultSampleRateHz: 48_000, defaultBitDepth: "32-bit float")
        let recording = Recording(gear: [recorder])
        context.insert(recording)
        try context.save()

        let fetched = try #require(try context.fetch(FetchDescriptor<Gear>()).first)
        #expect(fetched.name == "Zoom F3")
        #expect(fetched.type == "recorder")
        #expect(fetched.defaultSampleRateHz == 48_000)
        #expect(fetched.defaultBitDepth == "32-bit float")
        #expect(fetched.recordings?.count == 1)
        #expect(recording.gear?.first?.name == "Zoom F3")
    }

    @Test func kitPresetRoundTripsWithGear() throws {
        let container = try ModelContainer.fieldLog(inMemory: true)
        let context = container.mainContext
        let recorder = Gear(name: "Zoom F3", type: "recorder")
        let mic = Gear(name: "Some mic", type: "mic")
        let preset = KitPreset(name: "full kit", gear: [recorder, mic])
        context.insert(preset)
        try context.save()

        let fetched = try #require(try context.fetch(FetchDescriptor<KitPreset>()).first)
        #expect(fetched.name == "full kit")
        #expect(Set(fetched.gear?.map(\.name) ?? []) == ["Zoom F3", "Some mic"])
        #expect(recorder.presets?.first?.name == "full kit")
    }

    @Test func tagRoundTripsAndLinksToRecordings() throws {
        let container = try ModelContainer.fieldLog(inMemory: true)
        let context = container.mainContext
        let tag = FieldLog.Tag(name: "birds")
        let recording = Recording(tags: [tag])
        context.insert(recording)
        try context.save()

        let fetched = try #require(try context.fetch(FetchDescriptor<FieldLog.Tag>()).first)
        #expect(fetched.name == "birds")
        #expect(fetched.recordings?.count == 1)
        #expect(recording.tags?.first?.name == "birds")
    }

    @Test func markerRoundTripsWithRecording() throws {
        let container = try ModelContainer.fieldLog(inMemory: true)
        let context = container.mainContext
        let marker = Marker(offsetSeconds: 42.5, note: "plane overhead")
        let recording = Recording(markers: [marker])
        context.insert(recording)
        try context.save()

        let fetched = try #require(try context.fetch(FetchDescriptor<Marker>()).first)
        #expect(fetched.offsetSeconds == 42.5)
        #expect(fetched.note == "plane overhead")
        #expect(fetched.recording?.persistentModelID == recording.persistentModelID)
    }

    @Test func photoRoundTripsWithRecording() throws {
        let container = try ModelContainer.fieldLog(inMemory: true)
        let context = container.mainContext
        let taken = Date(timeIntervalSince1970: 1_800_000_100)
        let photo = Photo(assetIdentifier: "ABC-123/L0/001", takenAt: taken)
        let recording = Recording(photos: [photo])
        context.insert(recording)
        try context.save()

        let fetched = try #require(try context.fetch(FetchDescriptor<Photo>()).first)
        #expect(fetched.assetIdentifier == "ABC-123/L0/001")
        #expect(fetched.takenAt == taken)
        #expect(fetched.recording?.persistentModelID == recording.persistentModelID)
    }

    @Test func deletingRecordingCascadesToMarkersAndPhotosOnly() throws {
        let container = try ModelContainer.fieldLog(inMemory: true)
        let context = container.mainContext
        let recording = Recording(
            gear: [Gear(name: "Zoom F3", type: "recorder")],
            tags: [FieldLog.Tag(name: "birds")],
            markers: [Marker(offsetSeconds: 1, note: "a")],
            photos: [Photo(assetIdentifier: "p")]
        )
        context.insert(recording)
        try context.save()

        context.delete(recording)
        try context.save()

        #expect(try context.fetchCount(FetchDescriptor<Recording>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<Marker>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<Photo>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<Gear>()) == 1)
        #expect(try context.fetchCount(FetchDescriptor<FieldLog.Tag>()) == 1)
    }
}
