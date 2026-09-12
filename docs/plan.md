# FieldLog — Plan

Living document. The roadmap lists every step in order; the section below it holds the detailed plan for whichever step is current. When a step finishes, mark it done in the roadmap, delete its detailed plan, and write the next one.

Spec: `docs/design.md`. Working rules: `AGENTS.md`.

## Roadmap

Each step is one or a few tasks, ends with a runnable app, and gets its own commit(s).

| # | Step | Status | Notes |
|---|------|--------|-------|
| 0 | Project setup: Xcode template, docs, paid developer account, verified device install | Done | Sept 2026 |
| 1 | Data model: six SwiftData entities, seed gear, round-trip tests | Done | Sept 2026. Photos are library references |
| 2 | Recording list and manual create/edit form | Done | Sept 2026. Explicit saves on insert, delete, and form dismiss; UI smoke test covers the flow |
| 3 | Gear screen, kit presets, tag autocomplete | Done | Sept 2026. 13 gear items, 3 presets seeded; reinstall to reseed |
| 4 | Location service: Core Location + reverse geocoding | Done | Sept 2026. `CLLocationUpdate.liveUpdates()` + `MKReverseGeocodingRequest`; smoke test needs simctl grant + location set |
| 5 | Weather service: WeatherKit | **Current** | Needs WeatherKit capability in Xcode; decide field set |
| 6 | Markers and photos | Todo | PhotosPicker in simulator; camera needs device |
| 7 | Export | Todo | Decide format first (markdown to Obsidian likely); shapes which fields matter |
| 8 | Field use and iteration | Todo | Install, log real recordings, fix what hurts |
| — | CloudKit sync | Deferred | Model is already compatible; enable when a second device exists |

Decisions still open (from the spec): export format (step 7), WeatherKit field set (step 5). Photo storage decided in step 1: Photos-library references.

## Current step: 5 — Weather service

### Goal

A new recording opens with weather already filled from WeatherKit for its coordinates and start time, and the Weather section shows it. Runs right after the location fix, since it needs coordinates.

### Decide first: the field set (open in the spec)

The model already has `weatherSummary`, `temperatureC`, `windSpeedKph`, `windDirectionDeg`. WeatherKit's `CurrentWeather` also offers humidity, pressure, cloud cover, UV index, visibility, and precipitation intensity. Options, for the developer to choose before the step starts:

- **Keep the four fields.** Nothing to add to the model; what the Shortcut captured. Cheapest, and nothing else is looked at today.
- **Add humidity and pressure.** Two optional `Double` columns (`humidity` 0–1, `pressureHPa`). Cheap to store; pressure trends matter for wind and weather changes on multi-day trips; both export as two more lines.
- **Add cloud cover and precipitation.** Useful for reading a recording's "feel" later (overcast dawn chorus versus clear), and rain is the one condition that ruins takes. `conditions` text mostly already says this.

Any added field is one optional property on `Recording`, one round-trip test line, one row in `WeatherSection`, and one line in export. The spec's own question is whether anyone will look at them; the export format (step 7) decides what is worth carrying.

### Before starting (developer, in Xcode)

Add the WeatherKit capability: select the FieldLog target → Signing & Capabilities → **+ Capability** → WeatherKit. Then in the Apple Developer portal, the App ID needs the WeatherKit service enabled (Certificates, Identifiers & Profiles → Identifiers → com.wesklein.FieldLog → App Services → WeatherKit). Xcode usually does the portal part when the capability is added with automatic signing; it can take up to half an hour to propagate. WeatherKit does not work in the simulator without the capability, and requires the paid membership already in place.

### Deliverables

```
FieldLog/Services/WeatherService.swift     // @Observable: status + fill(_ recording:), calls WeatherService.shared.weather(for:)
FieldLog/Recordings/WeatherSection.swift   // moved out of RecordingFormSections; status row, Update Weather button, attribution
```

### Tasks

1. **Service.** `WeatherService` (name it `WeatherFetcher` if the WeatherKit type clashes) takes a recording with coordinates, fetches `CurrentWeather` for the location, and writes the chosen fields. Use `hourly` forecast for the hour containing `startedAt` when the recording is edited later than a few hours after the fact; otherwise current conditions. Status `idle`, `loading`, `loaded`, `failed`, same shape as `LocationService`.
2. **Chain from location.** `LocationService.fill` cannot know about weather; instead `RecordingListView.addRecording` awaits the fix, then triggers the weather fill. Simplest: give `LocationService.fill` a completion, or make `fill` async and start weather from the same `Task`.
3. **Weather section.** Move to its own file. Show a *Loading…* row, an *Update Weather* button, a failed note, and the required attribution: WeatherKit terms require showing the Apple Weather mark and a link to the legal attribution page (`WeatherAttribution`). Keep it as a small footer in the section.
4. **Tests.** WeatherKit cannot be unit tested; test any pure mapping (e.g. `Measurement` → stored units, compass direction → degrees) if there is one. UI smoke test: weather is not asserted, since the simulator's availability depends on signing.
5. **Build, test, commit.** Manual check on the simulator with the capability, then on device.

### Xcode and SwiftUI concepts this step introduces

- **Capabilities and entitlements**: what the Signing & Capabilities tab writes and how it ties to the App ID in the portal.
- **WeatherKit attribution** requirements.
- **Chaining async services** without one service knowing about the other.

### Done when

- Build and unit tests pass.
- A new recording with a location shows weather within a few seconds on the device.
- The roadmap row is marked Done.
