import Testing
@testable import FieldLog

struct PhotoLibraryTests {
    @Test func newIdentifiersSkipAttachedDuplicatesAndNil() {
        let result = PhotoLibrary.newIdentifiers(
            picked: ["a", nil, "b", "a", "c"],
            existing: ["b"]
        )
        #expect(result == ["a", "c"])
    }
}
