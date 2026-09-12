# FieldLog

Personal iOS app for logging metadata about field recordings. Single user, single developer. Design spec lives in `docs/design.md` — read it before any model or feature work.

## Stack

- Swift, SwiftUI, SwiftData. iOS 26 SDK, Xcode 26.
- Swift Testing for unit tests (`@Test`, `#expect`). XCTest only for UI tests.
- No third-party dependencies unless explicitly requested.
- No UIKit unless SwiftUI genuinely lacks the capability; say so in the PR/summary if you use it.

## Commands

Run these from the repo root. Adjust the simulator name to one that exists (`xcrun simctl list devices available`).

```sh
# Build
xcodebuild -scheme FieldLog -destination 'platform=iOS Simulator,name=iPhone 17' build

# Unit tests
xcodebuild -scheme FieldLog -destination 'platform=iOS Simulator,name=iPhone 17' test -only-testing:FieldLogTests

# Boot / launch in simulator
xcrun simctl boot "iPhone 17"
xcrun simctl launch booted com.wesklein.FieldLog

# UI smoke test (needs a fully booted, visible simulator or the runner is refused with RequestDenied)
xcrun simctl boot "iPhone 17"; xcrun simctl bootstatus "iPhone 17" -b; open -a Simulator
xcodebuild -scheme FieldLog -destination 'platform=iOS Simulator,name=iPhone 17' -parallel-testing-enabled NO test -only-testing:FieldLogUITests
# Prefix with TEST_RUNNER_FIELDLOG_SCREENSHOT_DIR=<dir> to have it save screenshots of each screen.
```

`GearSeeder` only runs against an empty store. After changing seed data, `xcrun simctl uninstall booted com.wesklein.FieldLog` (or delete the app on the device) before the next run, or the old rows stay.

Pipe through `xcbeautify` if installed; otherwise grep for `error:` and `** BUILD FAILED **`. A successful build ends with `** BUILD SUCCEEDED **`.

Device runs and SwiftUI previews are done manually in Xcode — don't attempt them.

## Deployment

- Paid Apple Developer Program membership is active (enrolled September 2026). WeatherKit, CloudKit, and TestFlight are all available; don't work around their absence.
- The app installs directly from Xcode to the developer's iPhone; that has been verified working. No App Store or TestFlight distribution is planned.
- Adding a capability (WeatherKit, iCloud, etc.) is done in Xcode's Signing & Capabilities tab by the developer. Say when a task needs one rather than editing entitlements or the project file.

## Layout

```
FieldLog.xcodeproj
FieldLog/            app target sources
FieldLogTests/       unit tests (Swift Testing)
FieldLogUITests/     one XCTest smoke test of the recording flow; runs against the simulator's real store
docs/design.md       spec — data model and scope
docs/plan.md         roadmap plus detailed plan for the current step
```

Read `docs/plan.md` at the start of a task. When a step finishes, mark it done there and write the detailed plan for the next one.

Organize sources by feature, not by type: `FieldLog/Models/`, `FieldLog/Recordings/`, `FieldLog/Gear/`, etc. Add folders as needed.

## Data model rules

All SwiftData models must stay CloudKit-compatible even though sync is off for now:

- Every stored property has a default value or is optional.
- All relationships are optional.
- No `@Attribute(.unique)`.
- No non-optional relationship arrays — use `[Foo]? = []` or `[Foo] = []` per SwiftData's current rules, and be consistent.

Entities and their shape are defined in `docs/design.md`. Don't add entities, rename fields, or change relationships without being asked; propose it instead.

## Conventions

- Match existing code style. When there is none yet, follow Swift API Design Guidelines and Xcode's default formatting.
- Views are small and composable. Extract subviews before a body exceeds ~50 lines.
- Prefer `@Query` and `@Environment(\.modelContext)` in views over view-model wrappers for simple CRUD.
- Call `modelContext.save()` after inserts and deletes and in a form's `onDisappear`. Autosave only flushes on backgrounding and on a timer, so an abrupt kill loses unsaved edits.
- Keep business logic (weather fetch, location, export) out of views — put it in plain types under `FieldLog/Services/`.
- Every model change gets a unit test that inserts and reads back through an in-memory `ModelContainer`.
- In tests, hold the `ModelContainer` in a local and take `mainContext` from it. Returning only the context lets the container deallocate, and the next insert traps inside SwiftData with a zero-second test failure.
- Inside `FieldLogTests`, write `FieldLog.Tag`. Swift Testing exports its own `Tag` type, and the bare name is ambiguous there.

## Project file

Do not edit `FieldLog.xcodeproj/project.pbxproj` by hand except to register a newly added source file, and prefer letting the build system pick up files via the synchronized folder groups Xcode 16+ uses. If a file isn't compiling because it isn't in the target, say so rather than rewriting the project file.

## Git

- Commit after each completed task with a short imperative message.
- Never commit `xcuserdata/`, `DerivedData/`, or build output — `.gitignore` covers this; don't remove entries.
- Don't push, rebase, or force anything.

## Developer context

This is the developer's first iOS app and first time using Xcode. They are an experienced programmer but new to the Apple toolchain, and want to use this project to learn it.

- When a task touches an Xcode or platform concept for the first time (targets, schemes, entitlements, Info.plist keys, signing, simulators, SwiftData containers, `@Query`, etc.), explain it in a sentence or two the first time it comes up. Don't re-explain later.
- Prefer showing the standard, idiomatic way over a clever shortcut, and say why it's the standard way.
- When something has to be done in Xcode by hand, give the exact menu or panel path, not just "add the capability."
- If a build or test failure has an Xcode-specific cause (stale derived data, simulator not booted, file not in target), name the cause and the fix so it's recognizable next time.
- Don't pad with tutorials. Explanations attach to the work being done, not to things that might come up.

## Scope discipline

Build what the task asks for. Don't add features, settings, onboarding, or abstractions "for later." If something in the spec is ambiguous, ask or state your assumption in one line and proceed.
