import Foundation
import SwiftData

@Model
final class Tag {
    var name: String = ""
    var recordings: [Recording]? = []

    init(name: String = "") {
        self.name = name
    }
}
