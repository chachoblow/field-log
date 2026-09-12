# FieldLog — Plan

Living document. The roadmap lists every step in order; the section below it holds the detailed plan for whichever step is current. When a step finishes, mark it done in the roadmap, delete its detailed plan, and write the next one.

Spec: `docs/design.md`. Working rules: `AGENTS.md`.

## Roadmap

Each step is one or a few tasks, ends with a runnable app, and gets its own commit(s).

| # | Step | Status | Notes |
|---|------|--------|-------|
| 0 | Project setup: Xcode template, docs, paid developer account, verified device install | Done | Sept 2026 |
| 1 | Data model: six SwiftData entities, seed gear, round-trip tests | Done | Sept 2026. Photos are library references |
| 2 | Recording list and manual create/edit form | **Current** | No auto-population yet; already beats the Shortcut on editing |
| 3 | Gear screen, kit presets, tag autocomplete | Todo | Pure SwiftData/SwiftUI, no permissions. Needs the real gear list and preset contents from the developer |
| 4 | Location service: Core Location + reverse geocoding | Todo | First Info.plist usage string; test with simulator location menu |
| 5 | Weather service: WeatherKit | Todo | Needs WeatherKit capability in Xcode; decide field set |
| 6 | Markers and photos | Todo | PhotosPicker in simulator; camera needs device |
| 7 | Export | Todo | Decide format first (markdown to Obsidian likely); shapes which fields matter |
| 8 | Field use and iteration | Todo | Install, log real recordings, fix what hurts |
| — | CloudKit sync | Deferred | Model is already compatible; enable when a second device exists |

Decisions still open (from the spec): export format (step 7), WeatherKit field set (step 5). Photo storage decided in step 1: Photos-library references.

## Current step: 2 — Recording list and manual create/edit form

### Goal

Make the app usable for manual logging: a list of recordings, a form to create and edit one, and swipe to delete. Every scalar field on `Recording` is editable. Nothing auto-populates yet, and gear and tag pickers wait for step 3.

### Deliverables

```
FieldLog/Recordings/RecordingListView.swift     // @Query list, newest first, + button, swipe to delete
FieldLog/Recordings/RecordingRow.swift          // one list row: date, place or fallback, "no filename" badge
FieldLog/Recordings/RecordingFormView.swift     // Form bound to one Recording; same view for create and edit
FieldLog/Recordings/RecordingFormSections.swift // extracted section subviews if the form body passes ~50 lines
```

`ContentView.swift` is deleted; `FieldLogApp` shows `RecordingListView` directly.

### Tasks

1. **List.** `@Query(sort: \Recording.startedAt, order: .reverse)`. Each row is a `NavigationLink(value: recording)` inside a `NavigationStack` with `navigationDestination(for: Recording.self)` pushing the form. `onDelete` removes from the context. Empty state uses `ContentUnavailableView` with a one-line hint.
2. **Row.** Start date and time on the first line. Second line is place name, or "No location" in secondary style. A small "No filename" badge when `filename` is nil or empty, per the spec.
3. **Create.** The + button inserts a `Recording()` (defaults `startedAt` to now), then appends it to the navigation path so the form opens immediately. There is no cancel: a new recording exists once created and can be swiped away from the list. This keeps create and edit one code path and matches the spec's "editable at any time".
4. **Form.** `@Bindable var recording: Recording`, edits go straight to the model and the main context autosaves. Sections:
   - *When*: `DatePicker` for `startedAt`; `endedAt` as a toggle that reveals a second picker when on.
   - *Where*: `placeName` text field. Latitude and longitude shown read-only if set, otherwise hidden. Step 4 fills them.
   - *Weather*: read-only summary if any weather field is set, otherwise the section is hidden. Step 5 fills them.
   - *File*: `filename` text field; `sampleRateHz` picker (44100, 48000, 96000, none); `bitDepth` picker ("32-bit float", "24-bit", "16-bit", none).
   - *Capture*: `micTechnique` text field, `captureDescription` text editor, `isCompromised` toggle.
   - *Review*: `notes` text editor, `rating` picker (none, 1–5).
   Optional string fields bind through a small `Binding` helper that maps empty text to nil so the "No filename" badge stays honest.
5. **Previews.** Each view gets a `#Preview` using `ModelContainer.fieldLog(inMemory: true)` with two sample recordings inserted, one with a filename and one without.
6. **Tests.** No model changes, so no new model tests. If task 4's empty-to-nil binding helper lives in its own type, give it a unit test. Views are not unit tested.
7. **Build, test, commit.** Build and unit tests pass from the command line. Manual check in the simulator: create a recording, edit several fields, relaunch the app, confirm the edits survived, swipe to delete.

### Xcode and SwiftUI concepts this step introduces

- **`NavigationStack` with a typed path** and `navigationDestination(for:)`, versus the template's `NavigationSplitView`.
- **`@Bindable`** for editing a `@Model` object's properties from a form.
- **Main-context autosave**: why the form has no Save button.
- **`Form` and `Section`** as the standard settings-style editing layout.
- **`ContentUnavailableView`** for empty states.
- **Previews with sample data** and why they use the in-memory container.

### Done when

- Build and unit tests pass.
- A recording can be created, every field edited, and the edits survive an app relaunch.
- Rows without a filename show the badge; swipe to delete works.
- `ContentView.swift` is gone and the roadmap row is marked Done.
