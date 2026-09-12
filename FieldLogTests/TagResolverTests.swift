import Foundation
import SwiftData
import Testing
@testable import FieldLog

@MainActor
struct TagResolverTests {
    @Test func createsANewTagAndTrimsWhitespace() throws {
        let container = try ModelContainer.fieldLog(inMemory: true)
        let context = container.mainContext

        let tag = try #require(try TagResolver.resolve(name: "  birds ", in: context))

        #expect(tag.name == "birds")
        #expect(try context.fetchCount(FetchDescriptor<FieldLog.Tag>()) == 1)
    }

    @Test func reusesAnExistingTagIgnoringCase() throws {
        let container = try ModelContainer.fieldLog(inMemory: true)
        let context = container.mainContext
        let existing = FieldLog.Tag(name: "Birds")
        context.insert(existing)
        try context.save()

        let resolved = try TagResolver.resolve(name: "birds", in: context)

        #expect(resolved == existing)
        #expect(try context.fetchCount(FetchDescriptor<FieldLog.Tag>()) == 1)
    }

    @Test func blankNameResolvesToNothing() throws {
        let container = try ModelContainer.fieldLog(inMemory: true)
        let context = container.mainContext

        #expect(try TagResolver.resolve(name: "   ", in: context) == nil)
        #expect(try context.fetchCount(FetchDescriptor<FieldLog.Tag>()) == 0)
    }

    @Test func suggestionsMatchPrefixAndSkipAppliedTags() {
        let birds = FieldLog.Tag(name: "birds")
        let birthday = FieldLog.Tag(name: "Birthday")
        let surf = FieldLog.Tag(name: "surf")

        let suggested = TagResolver.suggestions(matching: "bi", excluding: [birds], from: [birds, birthday, surf])

        #expect(suggested == [birthday])
        #expect(TagResolver.suggestions(matching: "", excluding: [], from: [birds, surf]).isEmpty)
    }
}
