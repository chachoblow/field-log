import Foundation

/// Defaults a recording's format from its recorder.
enum RecorderDefaults {
    /// Fills `sampleRateHz` and `bitDepth` from the first selected recorder,
    /// touching only fields that are still nil so a manual choice survives.
    static func apply(to recording: Recording) {
        guard let recorder = (recording.gear ?? []).first(where: { $0.type == GearType.recorder.rawValue }) else {
            return
        }
        if recording.sampleRateHz == nil {
            recording.sampleRateHz = recorder.defaultSampleRateHz
        }
        if recording.bitDepth == nil {
            recording.bitDepth = recorder.defaultBitDepth
        }
    }
}
