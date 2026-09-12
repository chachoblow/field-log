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
| 3 | Gear screen, kit presets, tag autocomplete | **Current** | Pure SwiftData/SwiftUI, no permissions. Needs the real gear list and preset contents from the developer |
| 4 | Location service: Core Location + reverse geocoding | Todo | First Info.plist usage string; test with simulator location menu |
| 5 | Weather service: WeatherKit | Todo | Needs WeatherKit capability in Xcode; decide field set |
| 6 | Markers and photos | Todo | PhotosPicker in simulator; camera needs device |
| 7 | Export | Todo | Decide format first (markdown to Obsidian likely); shapes which fields matter |
| 8 | Field use and iteration | Todo | Install, log real recordings, fix what hurts |
| — | CloudKit sync | Deferred | Model is already compatible; enable when a second device exists |

Decisions still open (from the spec): export format (step 7), WeatherKit field set (step 5). Photo storage decided in step 1: Photos-library references.

## Current step: 3 — Gear screen, kit presets, tag autocomplete

### Goal

Stop typing gear and tags. A gear screen manages the seeded `Gear` list and `KitPreset`s. The recording form gains a gear section (multi-select plus one-tap preset) and a tags section (chips plus autocomplete). Selecting a recorder defaults sample rate and bit depth. No permissions, no services, no new entities.

### Needs from the developer first

The real gear list (name and type for each recorder, mic, windshield, mount, accessory, plus default sample rate and bit depth for recorders) and the preset names with their contents. `GearSeeder` currently holds only the two recorders and no presets. Existing installs are already seeded, so after the seed lists change, delete the app from the simulator or device and reinstall to see the new rows.

### Deliverables

```
FieldLog/Gear/GearListView.swift          // gear grouped by type, presets section, add buttons, swipe to delete
FieldLog/Gear/GearFormView.swift          // name, type picker, recorder-only default sample rate and bit depth
FieldLog/Gear/KitPresetFormView.swift     // name plus gear multi-select
FieldLog/Gear/GearPickerView.swift        // reusable multi-select checklist over all Gear, grouped by type
FieldLog/Recordings/GearSection.swift     // form section: preset menu, selected gear summary, link to picker
FieldLog/Recordings/TagsSection.swift     // form section: tag chips with remove, entry field with suggestions
FieldLog/Services/RecorderDefaults.swift  // fills sampleRateHz and bitDepth from the selected recorder
FieldLog/Services/TagResolver.swift       // case-insensitive lookup-or-create and prefix suggestions
FieldLog/Services/GearSeeder.swift        // real gear and preset lists
```

### Tasks

1. **Seed data.** Replace the placeholder lists in `GearSeeder` with the developer's real gear and presets. Extend `GearSeederTests` to assert the counts and that every preset resolves all of its gear names.
2. **Gear screen.** Reached from a toolbar button on the recording list that presents a sheet (a `NavigationStack` inside `.sheet`), since the list's typed path only knows `Recording`. `@Query` all gear sorted by name; group in the view with `Dictionary(grouping:by:)` on `type`, one `Section` per type in the fixed order recorder, mic, windshield, mount, accessory. A final *Presets* section lists each preset with its gear count. Swipe to delete on both. Adding uses the same insert-then-push pattern as recordings.
3. **Gear and preset forms.** `GearFormView`: name field, `type` picker over the five type strings, and sample rate and bit depth pickers shown only when type is recorder. `KitPresetFormView`: name field plus an embedded `GearPickerView`.
4. **Gear picker.** `GearPickerView(selection: Binding<[Gear]>)`: a checklist grouped by type, tapping toggles membership. Both `Recording.gear` and `KitPreset.gear` are `[Gear]?`, so the callers bind through a small `Binding` that reads `?? []`. Assigning the array is enough; SwiftData maintains the inverse.
5. **Recording form gear section.** A `Menu("Apply preset")` listing presets; choosing one replaces `recording.gear` with the preset's gear. Below it, the selected gear names as one line of text and a `NavigationLink` to `GearPickerView`. After any change to gear, call `RecorderDefaults.apply(to: recording)`, which fills `sampleRateHz` and `bitDepth` from the first selected recorder only when they are nil, so a manual choice is never overwritten.
6. **Tags section.** Existing tags shown as removable chips in a wrapping row. A text field beneath; as the user types, `TagResolver.suggestions(matching:in:)` lists existing tags by case-insensitive prefix, excluding ones already on the recording. Tapping a suggestion or submitting the field calls `TagResolver.resolve(name:in:)`, which returns the existing tag with that name (case-insensitive) or inserts a new one, then appends it to `recording.tags`. Removing a chip only unlinks; the tag entity stays for reuse.
7. **Tests.** `RecorderDefaults` and `TagResolver` are plain types under `Services/` and get unit tests through an in-memory container: defaults fill only nil fields, resolve reuses an existing tag regardless of case, suggestions exclude already-applied tags.
8. **Build, test, commit.** Extend the UI smoke test with one preset apply if it stays under a minute; otherwise leave it. Manual check: apply a preset, see sample rate and bit depth fill, add a tag, relaunch, confirm both survived.

### Xcode and SwiftUI concepts this step introduces

- **Sheets versus pushes** and why a sheet is the right container for a screen outside the list's typed path.
- **Editing many-to-many relationships** in SwiftData: assigning the array on one side, inverse maintained automatically, nullify on delete.
- **`Menu`** as a compact picker for one-tap actions.
- **Grouping query results in the view** with `Dictionary(grouping:by:)` rather than multiple queries.
- **`onSubmit`** and keyboard return handling for the tag field.

### Done when

- Build and unit tests pass.
- The gear screen shows every seeded item grouped by type, and gear and presets can be added, edited, and deleted.
- Applying a preset fills the recording's gear in one tap and defaults sample rate and bit depth from its recorder.
- Typing a tag suggests existing tags, and submitting reuses or creates one.
- Gear and tag edits survive an app relaunch, and the roadmap row is marked Done.
