import Foundation
import SwiftData

extension Schema {
    /// Every FieldLog entity. The single source of truth for what the store holds.
    static let fieldLog = Schema([
        Recording.self,
        Gear.self,
        KitPreset.self,
        Tag.self,
        Marker.self,
        Photo.self,
    ])
}

extension ModelContainer {
    /// Builds the app's container. Pass `inMemory: true` for tests and previews
    /// so nothing touches the on-disk store.
    static func fieldLog(inMemory: Bool = false) throws -> ModelContainer {
        let configuration = ModelConfiguration(schema: .fieldLog, isStoredInMemoryOnly: inMemory)
        return try ModelContainer(for: .fieldLog, configurations: [configuration])
    }
}
