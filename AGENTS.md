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
```

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
FieldLogUITests/     UI tests (rarely used)
docs/design.md       spec — data model and scope
```

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
- Keep business logic (weather fetch, location, export) out of views — put it in plain types under `FieldLog/Services/`.
- Every model change gets a unit test that inserts and reads back through an in-memory `ModelContainer`.

## Project file

Do not edit `FieldLog.xcodeproj/project.pbxproj` by hand except to register a newly added source file, and prefer letting the build system pick up files via the synchronized folder groups Xcode 16+ uses. If a file isn't compiling because it isn't in the target, say so rather than rewriting the project file.

## Git

- Commit after each completed task with a short imperative message.
- Never commit `xcuserdata/`, `DerivedData/`, or build output — `.gitignore` covers this; don't remove entries.
- Don't push, rebase, or force anything.

## Scope discipline

Build what the task asks for. Don't add features, settings, onboarding, or abstractions "for later." If something in the spec is ambiguous, ask or state your assumption in one line and proceed.
