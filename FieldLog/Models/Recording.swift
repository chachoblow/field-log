import Foundation
import SwiftData

@Model
final class Recording {
    var startedAt: Date = Date()
    var endedAt: Date?
    var latitude: Double?
    var longitude: Double?
    var placeName: String?          // reverse-geocoded, user-editable
    var weatherSummary: String?     // conditions text
    var temperatureC: Double?
    var windSpeedKph: Double?
    var windDirectionDeg: Double?
    var filename: String?           // deferred until the recording stops
    var sampleRateHz: Int?          // defaulted from recorder
    var bitDepth: String?           // "32-bit float", "24-bit"
    var micTechnique: String?       // "spaced pair 40cm", "ORTF"
    var captureDescription: String = ""   // written in the field
    var notes: String = ""                // written later
    var isCompromised: Bool = false       // noise / interruption
    var rating: Int?                      // post-review

    @Relationship(inverse: \Gear.recordings) var gear: [Gear]? = []
    @Relationship(inverse: \Tag.recordings) var tags: [Tag]? = []
    @Relationship(deleteRule: .cascade, inverse: \Marker.recording) var markers: [Marker]? = []
    @Relationship(deleteRule: .cascade, inverse: \Photo.recording) var photos: [Photo]? = []

    init(
        startedAt: Date = Date(),
        endedAt: Date? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        placeName: String? = nil,
        weatherSummary: String? = nil,
        temperatureC: Double? = nil,
        windSpeedKph: Double? = nil,
        windDirectionDeg: Double? = nil,
        filename: String? = nil,
        sampleRateHz: Int? = nil,
        bitDepth: String? = nil,
        micTechnique: String? = nil,
        captureDescription: String = "",
        notes: String = "",
        isCompromised: Bool = false,
        rating: Int? = nil,
        gear: [Gear] = [],
        tags: [Tag] = [],
        markers: [Marker] = [],
        photos: [Photo] = []
    ) {
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.latitude = latitude
        self.longitude = longitude
        self.placeName = placeName
        self.weatherSummary = weatherSummary
        self.temperatureC = temperatureC
        self.windSpeedKph = windSpeedKph
        self.windDirectionDeg = windDirectionDeg
        self.filename = filename
        self.sampleRateHz = sampleRateHz
        self.bitDepth = bitDepth
        self.micTechnique = micTechnique
        self.captureDescription = captureDescription
        self.notes = notes
        self.isCompromised = isCompromised
        self.rating = rating
        self.gear = gear
        self.tags = tags
        self.markers = markers
        self.photos = photos
    }
}
