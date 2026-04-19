# Eightful - Status

## TL;DR

Xcode project scaffolded, all 35 core unit tests pass, both iOS and watchOS targets build cleanly in the simulator. Ready to open in Xcode, set your dev team, and run on your paired iPhone + Apple Watch.

## What's here

```
watch-stepcounter/
  docs/superpowers/specs/2026-04-18-eightful-design.md   # Full design spec
  Package.swift                                              # Core logic as an SPM library
  Sources/EightfulCore/                                  # Pure logic, no platform deps
    StepTier.swift                                           # Red/orange/yellow/green from steps
    VitalityPoints.swift                                     # Step + workout scoring rules
    MaxHeartRate.swift                                       # 220 - age
    NudgeZone.swift                                          # 6,500-6,999 / 9,500-9,999 / 12,000-12,499
    DayState.swift                                           # Composite of steps + workoutGreen
    Settings.swift                                           # TimeOfDay + AppSettings
    NotificationHistory.swift                                # Per-day history (resets at midnight)
    NotificationDecision.swift                               # Pure decision function
    NotificationCopy.swift                                   # User-facing strings
  Tests/EightfulCoreTests/                               # 35 unit tests
  App/
    iOS/         (Eightful app - phone)
    Watch/       (EightfulWatch app)
    Complication/(EightfulComplication - widget extension)
    Shared/      (HealthKitReader, SettingsStore, HistoryStore, TierColor)
  project.yml                                                # xcodegen spec
  Eightful.xcodeproj                                     # Generated. Regenerate via `xcodegen`.
```

## How to run

1. **Set your team.** Open `Eightful.xcodeproj`. In each of the three targets (Eightful, EightfulWatch, EightfulComplication), go to Signing & Capabilities and select your Apple Developer team. Xcode will auto-provision bundle IDs under `org.whitelabel.eightful.*`.

   - The bundle-ID prefix `org.whitelabel` is a placeholder; change to your own reverse-DNS in `project.yml` then run `xcodegen` to regenerate. (Or just change it in Xcode; next `xcodegen` run will overwrite unless you update the YAML too.)

2. **HealthKit capability.** Already declared in all three `.entitlements` files. Xcode should accept it automatically. If it flags a provisioning issue, confirm your team is set.

3. **App Groups.** The entitlements declare `group.org.whitelabel.eightful`. You'll need to create this App Group on your developer portal (or let Xcode create it for you when you click "Fix"). It's used for sharing settings between the phone, watch, and complication.

4. **First run.** Install on paired devices. The iPhone app will prompt for HealthKit and notification authorization. The watch app will prompt for HealthKit.

5. **Add the complication.** Long-press your watch face, edit, pick any of the four families (circular / rectangular / corner / inline), choose "Eightful".

## Manual device test checklist

| Check | How |
|---|---|
| Complication renders in each family | Add it to four different watch faces (Infograph, Modular, Modular Compact, Smart Stack) |
| Colour tiers switch correctly | Simulate steps in Health app on iPhone: import samples for today at 3k, 7.2k, 10.5k, 13k. Complication should recolour red -> orange -> yellow -> green. |
| Workout-green works | Record a workout (e.g. a walk with elevated HR). Complication should show ring around number and "8 pt" badge once the workout ends and HR is averaged. |
| 7pm+ nudge fires when entering 6,500-6,999 band | Manually add step samples in Health to land in the band after 7pm. Expect a nudge notification. |
| 8pm report fires | Ensure the iPhone is awake at 8pm and in a non-green state. Expect "N,NNN steps today - tier, N points." |
| Green suppresses 8pm | On a green day (12,500+ or workout-green), ensure no 8pm notification. |
| Nudge overrides green suppression at 12,000-12,499 | Be at 12,200 steps at 8pm. Expect "Nearly there (300 to go)". |
| No DOB fallback | In Health, clear DOB. Open the app, set a DOB override in Settings. Workout-green should still resolve. |
| Midnight rollover | Keep an 8pm-notified state into the next day; confirm new-day notifications fire cleanly. |

## Known gaps to address before App Store submission

- **App icons.** No icon assets yet. Add `AppIcon.appiconset` to each target.
- **LaunchScreen asset.** iOS uses `UILaunchScreen` dict (generic). A branded launch would need a storyboard or LaunchScreen asset catalog.
- **Privacy nutrition label / App Store description.** HealthKit usage description strings are in the Info.plists; the App Store listing needs aligned text.
- **Vitality trademark safety.** The App Store description should say "tracks steps to hit a Vitality-style 8-point daily target" - do not claim official affiliation. Current in-app copy is already neutral ("not affiliated with Vitality"). Double-check the listing text before submission.
- **WatchConnectivity settings sync.** The Settings code paths are sketched (SettingsStore uses UserDefaults) but I didn't wire a full WCSession bridge iPhone -> Watch. Settings entered on the phone won't automatically reach the watch app. For v1 that's acceptable (watch uses defaults), but polish before release.
- **Notification deduplication across iPhone+Watch.** The scheduler runs on iPhone only (per design), so there's no watch-side notification that could duplicate. Confirm this on-device.
- **Background delivery reliability.** The iPhone uses HKObserverQuery + enableBackgroundDelivery. iOS may coalesce these aggressively. The 7pm/8pm logic is evaluated on every observer fire, so as long as there's any step activity in the evening, it should trigger. If it misses, consider adding `BGAppRefreshTask` or a silent push trigger.
- **`NSHealthUpdateUsageDescription`.** Currently declared "Not used". Apple Review sometimes asks you to justify or remove - safer to remove (and the HealthKit entitlement `healthkit.access` can drop update).

## Regenerating the Xcode project

The project is committed, but if you edit `project.yml` (or add new source files under `App/`), run:

```sh
xcodegen
```

from the repo root. xcodegen is installed via `brew install xcodegen` (already done).

## Running tests from CLI

```sh
swift test
```

All 35 tests should pass. This covers the pure logic (tiers, points, zones, notification decision, history rollover) - the HealthKit/WidgetKit glue is not unit-tested because it requires an XCTest host target. Those paths are verified by on-device testing from the checklist above.

## One more thing

The spec decisions captured everything we agreed on:
- Colour tiers: red / orange / yellow / green at 7,000 / 10,000 / 12,500
- Workout green: any single workout scoring 8 Vitality points (30min@>=70% max HR OR 60min@>=60%)
- Workout-green indicator: thin ring around the step count
- 8pm notification: step count unless green. Nudges in 6,500-6,999 / 9,500-9,999 / 12,000-12,499 override suppression.
- Real-time nudges from 7pm onward on crossing 6,500 / 9,500 (once per day per zone)
- All four complication families supported
- DOB from HealthKit with override fallback
- Target: watchOS 9 / iOS 16
