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
| 7 | Export | **Current** | Decide format first (markdown to Obsidian likely); shapes which fields matter |
| 8 | Field use and iteration | Todo | Install, log real recordings, fix what hurts |
| — | CloudKit sync | Deferred | Model is already compatible; enable when a second device exists |

Decisions still open (from the spec): export format (step 7). Photo storage decided in step 1: Photos-library references. WeatherKit field set decided in step 5: all eight fields. Photo storage revised in step 6: copies in the store, not library references (see `docs/design.md`).

## Current step: 7 — Export

### Decide first: the format

This is the developer's call, not the agent's. The options, with what each costs:

- **Markdown, one file per recording, into Obsidian.** Lands where notes already live and reads without tooling. YAML front matter carries the structured fields (date, coordinates, weather, gear, tags), the body carries description, markers, and notes, and photos are written next to the file and embedded with `![[...]]`. Cost: re-importing is lossy, so it is a publish, not a backup.
- **JSON, one file with every recording.** Lossless, trivial to re-import or feed to a script that matches filenames against BWF origination times. Cost: not readable in Obsidian without a plugin.
- **CSV.** Only worth it if a spreadsheet is the destination; markers and photos do not fit a row.

Recommendation to discuss: markdown for the human-facing copy, with JSON added later if the BWF matching script wants it. Whatever is chosen, record it in `docs/design.md` under Open questions before starting.

### Goal

From a recording's form, share that recording as a file (or files) in the chosen format, with its stored photos written alongside it. Every stored field appears in the output; nothing is invented.

### Deliverables

```
FieldLog/Services/RecordingExporter.swift     // pure: Recording -> document text; unit tested
FieldLog/Recordings/ExportButton.swift         // toolbar ShareLink / fileExporter on the form
FieldLogTests/RecordingExporterTests.swift     // golden-string tests over a fully populated recording and an empty one
```

### Tasks

1. **Document text.** `RecordingExporter.render(_:)` builds the file body from a `Recording`. Keep it a pure function over the model so tests can compare against a golden string. Markers as `m:ss — note` lines (reuse `MarkerOffset.label`). Optional fields that are nil are omitted, not written as empty.
2. **Photos.** Write each `Photo.imageData` JPEG to a temporary folder next to the document, named from the recording's start time plus an index. No library access is involved.
3. **Sharing.** `ShareLink` with a `Transferable` folder or zip, or `.fileExporter` with a `FileDocument`, from the form's toolbar. Prefer `ShareLink`: it reaches Files, AirDrop, and the Obsidian app's share extension without extra code. Zip if more than one file must travel together (`NSFileCoordinator` + `forReadingItemAt:options:.forUploading` produces a zip without a library).
4. **Tests.** Golden-string tests for the renderer. Photo export and sharing are checked by hand on the simulator (seed with `xcrun simctl addmedia`).
5. **Build, test, commit.** Then step 8: install on the phone, log real recordings, add camera capture if photos from the library turn out to be a detour.

### Xcode and SwiftUI concepts this step introduces

- **`Transferable` and `ShareLink`**: how SwiftUI hands data to the share sheet without UIKit.
- **Temporary and security-scoped files**: `FileManager.temporaryDirectory`, and why files for the share sheet live there.

### Done when

- Build and unit tests pass.
- Sharing a recording produces a file in the chosen format with every stored field, plus copies of its photos.
- The format decision is recorded in `docs/design.md`.
- The roadmap row is marked Done.
