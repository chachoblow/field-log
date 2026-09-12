import Foundation
import SwiftData

/// In-memory container with two sample recordings for `#Preview` blocks.
/// Never used by the running app.
@MainActor
enum PreviewData {
    static let container: ModelContainer = {
        let container = try! ModelContainer.fieldLog(inMemory: true)
        let context = container.mainContext
        try? GearSeeder.seedIfNeeded(context: context)
        let presets = (try? context.fetch(FetchDescriptor<KitPreset>())) ?? []
        let fieldKit = presets.first { $0.name == "Field kit" }?.gear ?? []
        let birds = Tag(name: "birds")
        context.insert(birds)
        context.insert(Recording(
            startedAt: .now.addingTimeInterval(-3_600),
            endedAt: .now.addingTimeInterval(-3_000),
            latitude: 38.0421,
            longitude: -122.9930,
            placeName: "Point Reyes",
            weatherSummary: "Fog",
            temperatureC: 12.5,
            windSpeedKph: 18,
            windDirectionDeg: 290,
            humidity: 0.93,
            pressureHPa: 1016,
            cloudCover: 1.0,
            precipitationMmPerHour: 0,
            filename: "ZOOM0001.WAV",
            sampleRateHz: 48_000,
            bitDepth: "32-bit float",
            micTechnique: "ORTF",
            captureDescription: "Surf and gulls from the bluff.",
            rating: 4,
            gear: fieldKit,
            tags: [birds]
        ))
        context.insert(Recording(
            startedAt: .now.addingTimeInterval(-86_400),
            captureDescription: "Dawn chorus, some traffic.",
            isCompromised: true
        ))
        return container
    }()

    static var recordings: [Recording] {
        let descriptor = FetchDescriptor<Recording>(sortBy: [SortDescriptor(\.startedAt, order: .reverse)])
        return (try? container.mainContext.fetch(descriptor)) ?? []
    }
}
