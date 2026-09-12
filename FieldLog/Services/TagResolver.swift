import Foundation
import SwiftData

/// Finds or creates tags by name, ignoring case and surrounding whitespace.
enum TagResolver {
    /// Returns the existing tag whose name matches `name` case-insensitively,
    /// or inserts a new one. Returns nil for a blank name.
    static func resolve(name: String, in context: ModelContext) throws -> Tag? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let existing = try context.fetch(FetchDescriptor<Tag>())
        if let match = existing.first(where: { $0.name.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            return match
        }
        let tag = Tag(name: trimmed)
        context.insert(tag)
        return tag
    }

    /// Tags whose names start with `text` (case-insensitive), excluding any already applied.
    /// Empty text yields nothing, so the list only appears while typing.
    static func suggestions(matching text: String, excluding applied: [Tag], from all: [Tag]) -> [Tag] {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        return all.filter { tag in
            !applied.contains(tag)
                && tag.name.range(of: trimmed, options: [.caseInsensitive, .anchored]) != nil
        }
    }
}
