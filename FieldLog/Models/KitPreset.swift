import Foundation
import SwiftData

@Model
final class KitPreset {
    var name: String = ""
    @Relationship(inverse: \Gear.presets) var gear: [Gear]? = []

    init(name: String = "", gear: [Gear] = []) {
        self.name = name
        self.gear = gear
    }
}
