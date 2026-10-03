# FieldLog — Plan

Living document. The roadmap lists every step in order; the section below it holds the detailed plan for whichever step is current. When a step finishes, mark it done in the roadmap, delete its detailed plan, and write the next one.

Spec: `docs/design.md`. Working rules: `AGENTS.md`.

## Roadmap

Each step is one or a few tasks, ends with a runnable app, and gets its own commit(s).

| # | Step | Status | Notes |
|---|------|--------|-------|
| 0 | Project setup: Xcode template, docs, paid developer account, verified device install | Done | Sept 2026 |
| 1 | Data model: six SwiftData entities, seed gear, round-trip tests | Done | Sept 2026. Photos are library references. Five entities now; `Marker` was removed in step 7 |
| 2 | Recording list and manual create/edit form | Done | Sept 2026. Explicit saves on insert, delete, and form dismiss; UI smoke test covers the flow |
| 3 | Gear screen, kit presets, tag autocomplete | Done | Sept 2026. 13 gear items, 3 presets seeded; reinstall to reseed |
| 4 | Location service: Core Location + reverse geocoding | Done | Sept 2026. `CLLocationUpdate.liveUpdates()` + `MKReverseGeocodingRequest`; smoke test needs simctl grant + location set |
| 5 | Weather service: WeatherKit | Done | Sept 2026. `WeatherFetcher` runs after the location fix; current conditions within 3 h of start, else the forecast hour. Verified on device after ticking WeatherKit on the App ID's Capabilities tab in the portal |
| 6 | Markers and photos | Done, markers later removed | Sept 2026. Markers were built here and taken out again in step 7 (Oct 2026) once real use showed the app is never open while recording. Photos are stored copies (≤ 2000 px JPEG in external storage) from the system camera or the library picker, with a full-size viewer; the library-reference design was built first and replaced. Camera needs `NSCameraUsageDescription` and a device |
| 7 | Field use and iteration | **Current** | Oct 2026: first outings done, friction round one worked and installed on the phone, schema change migrated the real store cleanly. Remaining: more real logging, then the step 8 plan |
| 8 | Import the old Apple Notes entries | Todo | The app is the system of record, so the Shortcut's notes come in, not out. Shape it after step 7 has shown what real entries look like |
| — | CloudKit sync | Deferred | Model is already compatible; enable when a second device exists |
| — | Export | Deferred | No consumer today: the app replaces the notes setup rather than feeding it, and iCloud device backup already carries the store. Pick a format when something needs the data |
| — | BWF filename matching | Possible | Fill `filename` by matching start time against the WAV's `bext` origination time. Typing the name is easy enough; revisit only if it becomes a chore |

Decisions from the spec: photo storage decided in step 1 (Photos-library references), revised in step 6 (copies in the store). WeatherKit field set decided in step 5 (all eight fields). Export format decided Sept 2026: deferred, no format chosen (see `docs/design.md`). Markers and the end time removed in step 7 (Oct 2026). Start-time default decided Oct 2026: left as is (see `docs/design.md`). Nothing is open.

## Current step: 7 — Field use and iteration

### Goal

Use the app for real recordings instead of the Shortcut, and fix whatever gets in the way. Every capture feature is in; the unknowns now are the ones only real use surfaces: what is slow to enter, what is missing, what is wrong on a phone outdoors.

### Before the first outing (done, October 2026)

Kept for the record. The first outings happened and the app has real recordings in it, which is what makes the two constraints under Fixing apply from here on.

1. **Install from Xcode** onto the phone (Product → Run with the phone selected). This is the last reinstall that costs nothing: once real recordings exist, the app is never deleted from the device, because the SQLite store goes with it (see `AGENTS.md`, Data model rules).
2. **Check that Take Photo appears** on the form on the phone. The camera usage string is set in the project; the button hides itself if the build somehow lacks it.
3. **Check that location and weather fill in** on the phone with the app freshly opened outdoors. Weather needs a network connection at capture time; note whether that holds where recordings happen.

### During

Log every recording in the app. Keep a friction list here, in this section, as short lines:

First round, October 2026, after a few real recordings:

- "Ended" is not that useful; worth removing for simplicity.
- "Marker" is not that useful either.
- The app is generally not open during a recording or after it, so anything that depends on being there live is dead weight. This is the reason for the two lines above.
- Keeping all the weather data is right, but the section should show a simpler display with the option to expand.
- The ordering of the data entries can be reworked.
- Show tags on the "Recordings" home screen when a recording has them.
- The app has no icon.

Found while reworking the order, not from an outing:

- "Started" defaults to now, which is the time the form was opened, not the time the recording began. **Deliberately not fixed**: the entry gets opened just before or just after the recorder starts, so the default is already within a minute or two, and the field is only there to sort the list and find an earlier log. Ballpark is good enough, and every fix costs more than the problem.
- The "Started" row could be renamed to something like "Logged", since that is closer to what it holds. **Deliberately not done**: cosmetic, and not worth a change on its own. Fold it into the next edit of that section.

Rules for the list: write it down in the moment, one line per item, no fixing in the field. Things that belong on it: fields that are always the same and should default, taps that are hard with cold hands, anything typed twice, anything the Shortcut did that is missed, anything wrong in the weather or place name.

### Fixing

Work the list in small commits, one item each, with the usual unit test for any model change. Two constraints that did not exist before real data:

- **No reinstall on the device.** Seed data changes need an in-app path or a migration.
- **Schema changes need verifying against a real store.** Adding an optional property or entity, and removing one, are both inferable by automatic lightweight migration; renames and type changes are what need a hand-written plan. Prove any change by opening a store written with the old schema against the new one before the phone sees it (see `AGENTS.md`, Data model rules).

Items that turn out to be features rather than fixes get a roadmap row instead of a commit.

### Triage of the first round

All seven items are worked. What changed:

- **"Ended" and markers are gone, model included.** Decided October 2026 to make the model match the app rather than hide the fields and leave dead columns behind; the reasoning is a key decision in `docs/design.md`. Removed `endedAt`, the `Marker` entity, `MarkerOffset`, `MarkersSection`, the marker unit tests, and the marker steps in the UI smoke test, which now checks that mic technique survives a relaunch instead.
- Correcting what an earlier version of this section claimed: deleting a property or an entity **is** inferable by SwiftData's automatic lightweight migration, because the new model has nowhere to put the old data. Renames and type changes are the ones needing a hand-written plan. Verified before shipping by opening a store written with the old schema against the new one: `ZENDEDAT` and `ZMARKER` are dropped, and recordings, gear, tags, and photos all survive, including the many-to-many join tables that get renumbered when an entity leaves the schema (`Z_5TAGS` became `Z_4TAGS` with all its rows).
- **Weather is one summary line** (conditions, temperature, wind) with all eight stored readings behind a disclosure. The line is built by `WeatherSummary`, unit tested on shape rather than exact numbers because units follow the locale.
- **The form is reordered** to When, Gear, Photos, Capture, Tags, Where, Weather, File, Review, following the shape of a take: the kit and the setup shots, then what gets written about the capture, then the context that fills itself in, with File and Review last because neither exists until after the recording does. The description leads the Capture section.
- **The list row shows tags** when a recording has them.
- **A placeholder icon is in.** Generated, not drawn: a flat waveform on a deep teal ground, light slot only, with iOS deriving the dark and tinted variants. Replace it with real artwork whenever.

The smoke test moved with the form, since it can only scroll downward and a row below the fold does not exist to it until reached. It now also checks the weather section renders and that the list row carries the tags.

### The install on the phone

Done, October 2026, and the store came through. The removal of `endedAt` and the `Marker` entity migrated the real device store on first launch with no trouble reported, which is the confirmation the synthetic fixture could only approximate.

The backup step stays worth doing before any future schema change, since it is the only undo: Xcode's Window → Devices and Simulators → the phone → Installed Apps → FieldLog → the gear button under the list → Download Container, or the command line, which is less fiddly (see `AGENTS.md`, Deployment).

### Done when

Where this stands as of October 2026: the first criterion is partly met, the second is met now that the start-time item is settled, and the third has not been started.

- A handful of real recordings are logged in the app and the Shortcut has not been used.
- The friction list is worked down to items that are deliberately not being fixed, each with a one-line reason.
- The detailed plan for step 8 (import) is written, informed by how the real entries compare to the old notes.
