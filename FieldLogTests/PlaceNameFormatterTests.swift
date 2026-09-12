import Testing
@testable import FieldLog

struct PlaceNameFormatterTests {
    @Test func prefersTheCity() {
        #expect(PlaceNameFormatter.name(city: "Inverness, CA", pointOfInterest: "Tomales Bay") == "Inverness, CA")
    }

    @Test func fallsBackToPointOfInterestName() {
        #expect(PlaceNameFormatter.name(city: nil, pointOfInterest: "Tomales Bay") == "Tomales Bay")
    }

    @Test func treatsBlankPartsAsMissing() {
        #expect(PlaceNameFormatter.name(city: "  ", pointOfInterest: " Pier ") == "Pier")
        #expect(PlaceNameFormatter.name(city: "", pointOfInterest: nil) == nil)
    }
}
