import SwiftUI

extension Binding where Value == String? {
    /// Presents an optional string as plain text for a `TextField`.
    /// Reads `nil` as empty text and writes empty text back as `nil`,
    /// so a cleared field really is "unset" rather than "".
    var orEmpty: Binding<String> {
        Binding<String>(
            get: { wrappedValue ?? "" },
            set: { wrappedValue = $0.isEmpty ? nil : $0 }
        )
    }
}
