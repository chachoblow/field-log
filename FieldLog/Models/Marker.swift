import Foundation
import SwiftData

@Model
final class Marker {
    var offsetSeconds: Double = 0
    var note: String = ""
    var recording: Recording?

    init(offsetSeconds: Double = 0, note: String = "") {
        self.offsetSeconds = offsetSeconds
        self.note = note
    }
}
