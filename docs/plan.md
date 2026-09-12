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

Decisions still open (from the spec): export format (step 7). Photo storage decided in step 1: Photos-library references. WeatherKit field set decided before step 5: all eight fields.

## Current step: 5 — Weather service

### Goal

A new recording opens with weather already filled from WeatherKit for its coordinates and start time, and the Weather section shows it. Runs right after the location fix, since it needs coordinates.

### Field set (decided Sept 2026)

Keep the four existing fields and add four optional `Double` columns to `Recording`: `humidity` (0–1), `pressureHPa`, `cloudCover` (0–1), `precipitationMmPerHour`. All come from one `CurrentWeather` value: `humidity`, `pressure` (a `Measurement<UnitPressure>`, convert to hectopascals), `cloudCover`, and `precipitationIntensity` (a `Measurement<UnitSpeed>`, convert to millimetres per hour). Adding optional properties migrates the on-device store automatically, so real recordings survive; this is the moment to explain lightweight migration versus a `VersionedSchema` and `SchemaMigrationPlan`, which renames and type changes would need. Update `ModelTests.recordingRoundTrips` for the new columns.

### Already in place

The WeatherKit capability was added in Xcode on Sept 12, 2026: `FieldLog/FieldLog.entitlements` holds `com.apple.developer.weatherkit`, both configurations reference it via `CODE_SIGN_ENTITLEMENTS`, and the regenerated team provisioning profile carries the entitlement, so the App ID is registered. A device build signs cleanly. Nothing else is needed from the developer before starting. If WeatherKit calls fail with a permission error on the first try, wait; Apple's servers can lag the portal by up to half an hour, and the simulator needs to be signed in to an Apple Account for WeatherKit (Settings → Sign in) if it fails there.

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

- **Capabilities and entitlements** were covered when the capability was added: the entitlements file is the app's half, signed into the binary; the provisioning profile is Apple's half, listing what the team may sign for this bundle ID.
- **WeatherKit attribution** requirements.
- **Chaining async services** without one service knowing about the other.

### Done when

- Build and unit tests pass.
- A new recording with a location shows weather within a few seconds on the device.
- The roadmap row is marked Done.
