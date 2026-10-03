# FieldLog

Personal iOS app for logging metadata about field recordings. Single user, single developer. Design spec lives in `docs/design.md` — read it before any model or feature work.

## Stack

- Swift, SwiftUI, SwiftData. iOS 26 SDK, Xcode 26.
- Swift Testing for unit tests (`@Test`, `#expect`). XCTest only for UI tests.
- No third-party dependencies unless explicitly requested.
- No UIKit unless SwiftUI genuinely lacks the capability; say so in the PR/summary if you use it. The one existing use is `CameraPicker` (`UIImagePickerController`): SwiftUI has no camera view.

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
# `open -a Simulator` fails on this machine: Xcode 27 ships no Simulator.app in the bundle and
# there is none in /Applications. The UI test runs fine against the booted device without it,
# so boot, wait for bootstatus, and go. Reinstall the app first to clear the previous run's store.
# The test expects a location fix, so grant access and set a position first. Set the position
# right before each run; it has been seen reset to Apple's default between runs.
xcrun simctl privacy booted grant location com.wesklein.FieldLog
xcrun simctl location booted set 38.0421,-122.9930
xcodebuild -scheme FieldLog -destination 'platform=iOS Simulator,name=iPhone 17' -parallel-testing-enabled NO test -only-testing:FieldLogUITests
# Prefix with TEST_RUNNER_FIELDLOG_SCREENSHOT_DIR=<dir> to have it save screenshots of each screen.
```

To see the denied state, `xcrun simctl privacy booted revoke location com.wesklein.FieldLog` and relaunch. `reset` instead of `revoke` returns to "not determined" so the prompt shows again.

If the UI smoke test fails partway, it leaves its "UI Test Cove" recording behind and the next run fails on a duplicate row; `xcrun simctl uninstall booted com.wesklein.FieldLog`, then `xcrun simctl install booted <path to FieldLog.app>` (newest under `DerivedData/FieldLog-*/Build/Products/Debug-iphonesimulator`), then grant location. Granting before the app is installed does not stick. Form rows below the fold don't exist to XCTest until scrolled in, so use the test's `scroll(_:until:)` before touching anything low on the form. The template `FieldLogUITestsLaunchTests` runs once per orientation and leaves the device in landscape, so any test that runs after it must set `XCUIDevice.shared.orientation = .portrait` first.

Driving `PhotosPicker` from XCTest works: its cells are `app.images` labelled `"Photo, <date>"`, the confirm button is "Done", and both must be tapped via `coordinate(...)` because the remote view reports them as not hittable. `xcrun simctl addmedia booted <image>` seeds a photo (it has crashed once when run right after boot; the library persists across app reinstalls, so seed once). A stored thumbnail shows up as `app.images["Photo"]`; tap and long-press it by coordinate too.

`GearSeeder` only runs against an empty store. After changing seed data, `xcrun simctl uninstall booted com.wesklein.FieldLog` before the next run, or the old rows stay. Never do this on the device: deleting the app deletes its SQLite store, recordings included. Once real recordings exist, changed seed data needs an in-app path (edit on the Gear screen, or a one-time migration), not a reinstall.

Pipe through `xcbeautify` if installed; otherwise grep for `error:` and `** BUILD FAILED **`. A successful build ends with `** BUILD SUCCEEDED **`.

Device runs and SwiftUI previews are done manually in Xcode — don't attempt them.

## Deployment

- Paid Apple Developer Program membership is active (enrolled September 2026). WeatherKit, CloudKit, and TestFlight are all available; don't work around their absence.
- The app installs directly from Xcode to the developer's iPhone; that has been verified working. No App Store or TestFlight distribution is planned.
- Adding a capability (WeatherKit, iCloud, etc.) is done in Xcode's Signing & Capabilities tab by the developer. Say when a task needs one rather than editing entitlements or the project file. WeatherKit is already added (September 2026); `FieldLog/FieldLog.entitlements` is the file Xcode wrote for it.
- To pull the app's data off the phone before a risky change (a schema change, especially), copy its container to the Mac. `xcrun devicectl list devices` for the name, then:

```sh
xcrun devicectl device copy from --device "<device name>" \
  --domain-type appDataContainer --domain-identifier com.wesklein.FieldLog \
  --source . --destination ~/Desktop/FieldLog-container
```

  That brings down the SQLite store and the external photo files. Xcode's GUI route is Window → Devices and Simulators → the phone → Installed Apps → FieldLog → the gear button beneath the list → Download Container, which writes an `.xcappdata` bundle.
- To check what a build is signed with: `codesign -d --entitlements - --xml <path to FieldLog.app> | plutil -p -`. To check what the team profile allows: `security cms -D -i <.mobileprovision> | plutil -extract Entitlements xml1 -o - -`.
- WeatherKit returning `WDSJWTAuthenticatorServiceListener.Errors Code=2` (a 401 from `weatherkit.apple.com/v3/token`, logged by `com.apple.weatherkit.authservice`) on both simulator and device means the App ID is not enabled for WeatherKit on Apple's side, even though the entitlement and profile look right. Xcode's capability checkbox alone was not enough in September 2026: the fix was developer.apple.com → Certificates, Identifiers & Profiles → Identifiers → `com.wesklein.FieldLog` → Capabilities tab → tick WeatherKit → Save. It worked without a rebuild. To see the WeatherKit log on the simulator: `xcrun simctl spawn booted log show --last 5m --predicate 'subsystem == "com.apple.weather"' --style compact`.
- Info.plist privacy strings are `INFOPLIST_KEY_*` build settings, since the plist is generated. The developer sets them: project editor → FieldLog target → Build Settings → All → search the key. Location when-in-use and camera are both set (September 2026): `INFOPLIST_KEY_NSLocationWhenInUseUsageDescription` and `INFOPLIST_KEY_NSCameraUsageDescription`. `CameraPicker.isAvailable` hides the Take Photo button when the camera key is missing, because the permission prompt crashes without it, and on the simulator, which has no camera. The Photos-library string was added and then removed in September 2026: photos are copied in through the picker, which needs no permission. To verify a usage string without touching the project file, pass it on the command line: `xcodebuild ... INFOPLIST_KEY_NSCameraUsageDescription="..." build`.

## Layout

```
FieldLog.xcodeproj
FieldLog/            app target sources; FieldLog.entitlements lives here
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
- `.sheet`, `.fullScreenCover`, and other presentation modifiers go on a real view inside a `Section` (a row, the grid), never on the `Section` itself; there they silently never present.
- The project's default actor isolation is `MainActor`. A type called from `Task.detached` (image decoding, anything CPU-bound) must be declared `nonisolated`, or the compiler warns now and errors under Swift 6.
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
