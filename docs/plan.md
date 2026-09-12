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
| 4 | Location service: Core Location + reverse geocoding | **Current** | First Info.plist usage string; test with simulator location menu |
| 5 | Weather service: WeatherKit | Todo | Needs WeatherKit capability in Xcode; decide field set |
| 6 | Markers and photos | Todo | PhotosPicker in simulator; camera needs device |
| 7 | Export | Todo | Decide format first (markdown to Obsidian likely); shapes which fields matter |
| 8 | Field use and iteration | Todo | Install, log real recordings, fix what hurts |
| — | CloudKit sync | Deferred | Model is already compatible; enable when a second device exists |

Decisions still open (from the spec): export format (step 7), WeatherKit field set (step 5). Photo storage decided in step 1: Photos-library references.

## Current step: 4 — Location service

### Goal

A new recording opens with coordinates and a reverse-geocoded place name already filled, per the spec. This is the first step that needs a permission, a usage string, and a service with real asynchronous work, so it is also where the app learns how to show "working", "done", and "denied" states in a form.

### Already in place

The usage string is set (Sept 2026): `INFOPLIST_KEY_NSLocationWhenInUseUsageDescription` in the target's Build Settings, for both Debug and Release. Nothing else is needed from the developer before starting.

### Deliverables

```
FieldLog/Services/LocationService.swift     // @Observable, @MainActor: one-shot fix plus reverse geocode, with a status
FieldLog/Services/PlaceNameFormatter.swift  // pure: "Locality, Region" from address parts, with fallbacks
FieldLog/Recordings/WhereSection.swift      // moved out of RecordingFormSections; status row, update button, Settings link
```

### Tasks

1. **Service.** `LocationService` wraps `CLLocationManager` for authorization and uses `CLLocationUpdate.liveUpdates()` (iOS 17+) as an async sequence to take the first fix with horizontal accuracy under about 100 m, giving up after 15 s. It exposes `status` (`idle`, `locating`, `located`, `denied`, `failed`) and one method, `fill(_ recording: Recording)`, that writes `latitude` and `longitude`, then reverse geocodes and writes `placeName` only if it is still nil, so text the user typed meanwhile is never overwritten. Reverse geocoding uses MapKit's `MKReverseGeocodingRequest`; `CLGeocoder` is deprecated in the iOS 26 SDK. Confirm the exact API shape against the SDK before writing it.
2. **Place name.** `PlaceNameFormatter.name(locality:administrativeArea:name:)` returns "Locality, Region" when both exist, otherwise whichever exists, otherwise the point-of-interest name, otherwise nil. Pure and unit tested.
3. **Wire up.** `RecordingListView.addRecording` starts a `Task` calling `fill` right after the insert, so the form opens while the fix is in flight. Hold one `LocationService` in the app and pass it through the environment (`.environment(service)` with `@Environment(LocationService.self)`), since permission state is app-wide.
4. **Where section.** Move `WhereSection` into its own file. Below the place field: a *Locating…* row with a `ProgressView` while `status == .locating`; the coordinates row once set; an *Update Location* button that calls `fill` again and overwrites coordinates and, this time, the place name; and when denied, a one-line note with a `Link` to the app's Settings page (`UIApplication.openSettingsURLString` is the one UIKit constant involved).
5. **Tests.** Unit tests for `PlaceNameFormatter`. `LocationService` is not unit tested. Extend the UI smoke test: before launch, run `xcrun simctl privacy booted grant location com.wesklein.FieldLog` and `xcrun simctl location booted set 38.0421,-122.9930` from the command line (or set them in the test with `XCUIDevice` if the SDK allows), then assert the coordinates row appears after creating a recording. Note the exact commands in `AGENTS.md`.
6. **Build, test, commit.** Manual check on the simulator via *Features → Location → Custom Location*, then on the device outdoors: create a recording, see the place name land within a few seconds, deny permission in Settings, confirm the denied note and link.

### Xcode and SwiftUI concepts this step introduces

- **Usage strings and `INFOPLIST_KEY_` build settings**: how a generated Info.plist gets its privacy keys.
- **`@Observable` services in the environment** versus per-view `@State`.
- **Async sequences** (`for await` over location updates) and cancelling with a timeout.
- **Simulator location and privacy controls** from the command line.
- **Reading permission state** and showing a Settings link instead of re-prompting, which iOS does not allow.

### Done when

- Build and unit tests pass.
- A new recording shows coordinates and a place name without any typing, on simulator and device.
- Denying permission shows the note and Settings link, and the form still works manually.
- The roadmap row is marked Done.
