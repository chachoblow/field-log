import Foundation

/// The maths behind a marker's position: seconds since the recording started,
/// and the `m:ss` label the form shows for it.
enum MarkerOffset {
    /// Seconds from `startedAt` to `now`, clamped at zero in case the start
    /// time was edited into the future.
    static func seconds(from startedAt: Date, now: Date = .now) -> Double {
        max(0, now.timeIntervalSince(startedAt))
    }

    /// Whole seconds as `m:ss`; minutes keep counting past an hour ("75:02").
    static func label(_ seconds: Double) -> String {
        Duration.seconds(max(0, seconds).rounded(.down)).formatted(.time(pattern: .minuteSecond))
    }
}
