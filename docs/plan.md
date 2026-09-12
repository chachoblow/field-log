# FieldLog — Plan

Living document. The roadmap lists every step in order; the section below it holds the detailed plan for whichever step is current. When a step finishes, mark it done in the roadmap, delete its detailed plan, and write the next one.

Spec: `docs/design.md`. Working rules: `AGENTS.md`.

## Roadmap

Each step is one or a few tasks, ends with a runnable app, and gets its own commit(s).

| # | Step | Status | Notes |
|---|------|--------|-------|
| 0 | Project setup: Xcode template, docs, paid developer account, verified device install | Done | Sept 2026 |
| 1 | Data model: six SwiftData entities, seed gear, round-trip tests | **Current** | Replaces template `Item` |
| 2 | Recording list and manual create/edit form | Todo | No auto-population yet; already beats the Shortcut on editing |
| 3 | Gear screen, kit presets, tag autocomplete | Todo | Pure SwiftData/SwiftUI, no permissions |
| 4 | Location service: Core Location + reverse geocoding | Todo | First Info.plist usage string; test with simulator location menu |
| 5 | Weather service: WeatherKit | Todo | Needs WeatherKit capability in Xcode; decide field set |
| 6 | Markers and photos | Todo | PhotosPicker in simulator; camera needs device |
| 7 | Export | Todo | Decide format first (markdown to Obsidian likely); shapes which fields matter |
| 8 | Field use and iteration | Todo | Install, log real recordings, fix what hurts |
| — | CloudKit sync | Deferred | Model is already compatible; enable when a second device exists |

Decisions still open (from the spec): export format (step 7), photo storage (decide in step 1, leaning copy-into-container), WeatherKit field set (step 5).

## Current step: 1 — Data model

### Goal

Replace the template `Item` with the six entities from `docs/design.md`, seed the gear table on first launch, and prove every entity round-trips through an in-memory container. No UI beyond keeping the app launching.

### Deliverables

```
FieldLog/Models/Recording.swift
FieldLog/Models/Gear.swift
FieldLog/Models/KitPreset.swift
FieldLog/Models/Tag.swift
FieldLog/Models/Marker.swift
FieldLog/Models/Photo.swift
FieldLog/Models/ModelContainer+FieldLog.swift   // schema + container factory, in-memory option
FieldLog/Services/GearSeeder.swift              // inserts default gear + presets if the table is empty
FieldLogTests/ModelTests.swift                  // one round-trip test per entity
FieldLogTests/GearSeederTests.swift             // seeds once, is idempotent
```

Deleted: `FieldLog/Item.swift`. `ContentView` becomes a placeholder list of recordings so the app still launches.

### Tasks

1. **Models.** One file per entity, matching the spec exactly. Every property defaulted or optional, every relationship optional, no `@Attribute(.unique)`. Inverses declared explicitly on one side of each many-to-many (`Recording.gear` ↔ `Gear.recordings`, `Recording.tags` ↔ `Tag.recordings`, `KitPreset.gear` ↔ `Gear.presets`). Cascade delete on `Recording.markers` and `Recording.photos`. Each model gets a memberwise-style `init` with defaults so tests and previews can build one in a line.
2. **Container factory.** A single place that builds the `Schema` from all six types and returns a `ModelContainer`, with an `inMemory: Bool` parameter. `FieldLogApp` uses it for the real store; tests and previews use it in-memory. This replaces the closure currently inline in `FieldLogApp`.
3. **Seeder.** `GearSeeder.seedIfNeeded(context:)` inserts the default gear and kit presets when the `Gear` table is empty and does nothing otherwise. Called once at launch. Seed data is a static list in the seeder, not a JSON file — it is small and changes rarely.
4. **Photo storage decision.** Confirm copy-into-container. `Photo.filename` is a path relative to the app's Application Support directory. No file I/O in this step; just the field.
5. **Tests.** For each entity: create, insert, save, fetch through a fresh in-memory container, assert fields and relationships survive. Plus: cascade delete removes markers and photos but not gear or tags; seeder is idempotent across two calls.
6. **App still launches.** `ContentView` shows an empty `List` of recordings with a `@Query`. Nothing else.
7. **Build, test, commit.** `xcodebuild ... build` and `... test -only-testing:FieldLogTests` both pass. One commit, or one per numbered task if they are large.

### Seed data

Known recorders:

| Name | Type | Default sample rate | Default bit depth |
|------|------|--------------------:|-------------------|
| Zoom F3 | recorder | 48000 | 32-bit float |
| Zoom H5studio | recorder | 48000 | 32-bit float |

**Needs input:** the actual mics, windshields, mounts, and accessories, and the kit preset names and contents ("full kit", "minimal 3.5mm" are mentioned in the spec). Fill this in before or during task 3; until then the seeder ships with recorders only and placeholder presets are omitted.

### Xcode concepts this step introduces

Explained in context as they come up, listed here so nothing is skipped:

- **Target vs scheme.** `FieldLog` (app) and `FieldLogTests` (unit test bundle) are targets; the `FieldLog` scheme is what builds and tests them together.
- **Synchronized folder groups.** Xcode 16+ picks up new files under `FieldLog/` automatically; no project-file edits to add `Models/` or `Services/`.
- **`@Model`, `Schema`, `ModelContainer`, `ModelContext`.** The SwiftData stack: class annotation, the list of types, the store, and the unit of work.
- **In-memory containers** for tests, and why tests never touch the on-disk store.
- **`@testable import`** and how the test target sees app-target types.

### Done when

- All six models compile with no CloudKit-rule violations.
- Tests pass from the command line.
- App launches in the simulator to an empty recordings list.
- `Item.swift` is gone and the roadmap row is marked Done.
