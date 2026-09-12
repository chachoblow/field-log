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
| 6 | Markers and photos | **Current** | PhotosPicker in simulator; camera needs device |
| 7 | Export | Todo | Decide format first (markdown to Obsidian likely); shapes which fields matter |
| 8 | Field use and iteration | Todo | Install, log real recordings, fix what hurts |
| — | CloudKit sync | Deferred | Model is already compatible; enable when a second device exists |

Decisions still open (from the spec): export format (step 7). Photo storage decided in step 1: Photos-library references. WeatherKit field set decided in step 5: all eight fields.

## Current step: 6 — Markers and photos

### Goal

While a recording's form is open, one tap adds a marker at the current offset from `startedAt` with a short note, and any number of photos can be attached from the Photos library and shown as thumbnails. Both entities already exist in the model with cascade delete, so this step is UI plus one Photos-library service.

### Deliverables

```
FieldLog/Recordings/MarkersSection.swift   // list of markers, "Add Marker" button, inline note editing
FieldLog/Recordings/PhotosSection.swift    // thumbnail grid, PhotosPicker button, swipe/menu to remove
FieldLog/Services/PhotoLibrary.swift       // loads a thumbnail for a PHAsset.localIdentifier; placeholder when missing
FieldLogTests/MarkerOffsetTests.swift      // offset from start, clamped at zero; formatting mm:ss
```

### Tasks

1. **Markers.** `MarkersSection` lists markers sorted by `offsetSeconds`, each row showing the offset as `m:ss` and an editable note. *Add Marker* inserts one at `now - startedAt` (clamped to zero if the start time was edited into the future) and focuses its note. Keep the offset maths in a small pure helper so it can be tested. Swipe to delete, then `modelContext.save()`.
2. **Photos picker.** `PhotosSection` uses `PhotosPicker(selection:maxSelectionCount:matching:photoLibrary:)` from PhotosUI with `photoLibrary: .shared()`; that overload is the one whose `PhotosPickerItem.itemIdentifier` is a real `PHAsset.localIdentifier`, which is what `Photo.assetIdentifier` stores. Insert one `Photo` per new item, skipping identifiers already attached, and set `takenAt` from the asset's `creationDate`.
3. **Thumbnails.** `PhotoLibrary` wraps `PHImageManager.requestImage` for an identifier at thumbnail size, returning nil when the asset is gone so the view shows a placeholder. Reading assets by identifier needs read access, so the developer adds the `INFOPLIST_KEY_NSPhotoLibraryUsageDescription` build setting (same panel as the location string) and the app requests `PHPhotoLibrary` authorization for `.readWrite` the first time a thumbnail loads. Explain limited-library mode when it comes up: the user may grant access to only some photos, and picked ones are always in that set.
4. **Camera.** Out of scope for the simulator. If it is added in this step, use `UIImagePickerController` via `UIViewControllerRepresentable` only on device, save to the library, then store the resulting identifier; note the UIKit use in the summary. Otherwise defer to step 8.
5. **Tests.** Offset helper and formatting. Model round trip already covers `Marker` and `Photo`. UI smoke test: add a marker and check its row exists; photos are not asserted since the simulator's library is empty on a fresh boot (`xcrun simctl addmedia booted <image>` can seed one if wanted).
6. **Build, test, commit.** Manual check on the simulator; camera and Live Photos on device.

### Xcode and SwiftUI concepts this step introduces

- **PhotosUI and the Photos framework**: `PhotosPicker` runs out of process and needs no permission; reading an asset back by identifier does.
- **Photo library authorization** and the limited-library mode.
- **`UIViewControllerRepresentable`** if the camera is added.

### Done when

- Build and unit tests pass.
- A marker can be added while the form is open and its offset is right.
- A photo picked from the library shows as a thumbnail, survives relaunch, and shows a placeholder if deleted from the library.
- The roadmap row is marked Done.
