import Foundation
import Testing
@testable import FieldLog

struct MarkerOffsetTests {
    private let start = Date(timeIntervalSince1970: 1_800_000_000)

    @Test func offsetIsSecondsSinceStart() {
        #expect(MarkerOffset.seconds(from: start, now: start.addingTimeInterval(90.5)) == 90.5)
    }

    @Test func offsetClampsAtZeroWhenStartIsInTheFuture() {
        #expect(MarkerOffset.seconds(from: start, now: start.addingTimeInterval(-30)) == 0)
    }

    @Test func labelIsMinutesAndPaddedSeconds() {
        #expect(MarkerOffset.label(0) == "0:00")
        #expect(MarkerOffset.label(5) == "0:05")
        #expect(MarkerOffset.label(65) == "1:05")
        #expect(MarkerOffset.label(4_502) == "75:02")
    }

    @Test func labelDropsFractionalSecondsAndNegatives() {
        #expect(MarkerOffset.label(65.9) == "1:05")
        #expect(MarkerOffset.label(-3) == "0:00")
    }
}
