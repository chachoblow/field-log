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
| 5 | Weather service: WeatherKit | Done | Sept 2026. `WeatherFetcher` runs after the location fix; current conditions within 3 h of start, else the forecast hour. Verified on device after ticking WeatherKit on the App ID's Capabilities tab in the portal |
| 6 | Markers and photos | Done | Sept 2026. Markers at `now - startedAt` with `m:ss` labels. Photos are stored copies (≤ 2000 px JPEG in external storage) from the system camera or the library picker, with a full-size viewer; the library-reference design was built first and replaced. Camera needs `NSCameraUsageDescription` and a device |
| 7 | Field use and iteration | **Current** | Install, log real recordings, fix what hurts |
| 8 | Import the old Apple Notes entries | Todo | The app is the system of record, so the Shortcut's notes come in, not out. Shape it after step 7 has shown what real entries look like |
| — | CloudKit sync | Deferred | Model is already compatible; enable when a second device exists |
| — | Export | Deferred | No consumer today: the app replaces the notes setup rather than feeding it, and iCloud device backup already carries the store. Pick a format when something needs the data |
| — | BWF filename matching | Possible | Fill `filename` by matching start time against the WAV's `bext` origination time. Typing the name is easy enough; revisit only if it becomes a chore |

Decisions from the spec: photo storage decided in step 1 (Photos-library references), revised in step 6 (copies in the store). WeatherKit field set decided in step 5 (all eight fields). Export format decided Sept 2026: deferred, no format chosen (see `docs/design.md`). Nothing is open.

## Current step: 7 — Field use and iteration

### Goal

Use the app for real recordings instead of the Shortcut, and fix whatever gets in the way. Every capture feature is in; the unknowns now are the ones only real use surfaces: what is slow to enter, what is missing, what is wrong on a phone outdoors.

### Before the first outing

1. **Install from Xcode** onto the phone (Product → Run with the phone selected). This is the last reinstall that costs nothing: once real recordings exist, the app is never deleted from the device, because the SQLite store goes with it (see `AGENTS.md`, Data model rules).
2. **Check that Take Photo appears** on the form on the phone. The camera usage string is set in the project; the button hides itself if the build somehow lacks it.
3. **Check that location and weather fill in** on the phone with the app freshly opened outdoors. Weather needs a network connection at capture time; note whether that holds where recordings happen.

### During

Log every recording in the app. Keep a friction list here, in this section, as short lines:

- (empty)

Rules for the list: write it down in the moment, one line per item, no fixing in the field. Things that belong on it: fields that are always the same and should default, taps that are hard with cold hands, anything typed twice, anything the Shortcut did that is missed, anything wrong in the weather or place name.

### Fixing

Work the list in small commits, one item each, with the usual unit test for any model change. Two constraints that did not exist before real data:

- **No reinstall on the device.** Seed data changes need an in-app path or a migration.
- **Schema changes must be additive** (new optional property, new entity). Renames and type changes need a SwiftData migration plan, so prefer not to.

Items that turn out to be features rather than fixes get a roadmap row instead of a commit.

### Done when

- A handful of real recordings are logged in the app and the Shortcut has not been used.
- The friction list is worked down to items that are deliberately not being fixed, each with a one-line reason.
- The detailed plan for step 8 (import) is written, informed by how the real entries compare to the old notes.
