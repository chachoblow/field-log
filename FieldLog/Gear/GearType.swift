import Foundation

/// The five gear categories the UI offers. `Gear.type` stores the raw string
/// so the schema never changes when a case is added.
enum GearType: String, CaseIterable, Identifiable {
    case recorder, mic, windshield, mount, accessory

    var id: String { rawValue }

    var label: String {
        switch self {
        case .recorder: "Recorder"
        case .mic: "Mic"
        case .windshield: "Windshield"
        case .mount: "Mount"
        case .accessory: "Accessory"
        }
    }

    var pluralLabel: String {
        switch self {
        case .recorder: "Recorders"
        case .mic: "Mics"
        case .windshield: "Windshields"
        case .mount: "Mounts"
        case .accessory: "Accessories"
        }
    }
}
