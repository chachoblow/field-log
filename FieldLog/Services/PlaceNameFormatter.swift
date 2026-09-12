import Foundation

/// Picks the short place name shown in a recording from reverse-geocoded parts.
enum PlaceNameFormatter {
    /// The city with context ("Inverness, CA") when present, otherwise the
    /// point-of-interest name, otherwise nil. Blank parts count as missing.
    static func name(city: String?, pointOfInterest: String?) -> String? {
        nonBlank(city) ?? nonBlank(pointOfInterest)
    }

    private static func nonBlank(_ text: String?) -> String? {
        guard let trimmed = text?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else {
            return nil
        }
        return trimmed
    }
}
