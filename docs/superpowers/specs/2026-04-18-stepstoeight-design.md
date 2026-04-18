# StepsToEight - Design Spec

**Date:** 2026-04-18
**Target:** watchOS 9+ / iOS 16+
**Distribution:** UK App Store (paid Apple Developer account)

## 1. Overview

StepsToEight is an Apple Watch complication with an iPhone companion app. It tracks progress toward Vitality's 8-point daily activity target, showing the day's step count with color tiers aligned to Vitality's step-point thresholds (3 / 5 / 8 pts). When a single workout independently earns 8 points via heart-rate rules, the complication turns green early. Notifications nudge the user across threshold boundaries in the evening.

## 2. Vitality rules (encoded)

| Event                                  | Vitality points |
|----------------------------------------|-----------------|
| 7,000 steps                            | 3               |
| 10,000 steps                           | 5               |
| 12,500 steps                           | 8 (daily cap)   |
| Workout 30 min @ avg HR >= 60% max HR  | 5               |
| Workout 60 min @ avg HR >= 60% max HR  | 8               |
| Workout 30 min @ avg HR >= 70% max HR  | 8               |

Max HR = 220 - age. Day boundaries are the user's local calendar day. Daily cap is 8 points; weekly cap is 40 (not tracked in v1).

## 3. Color tiers

| Steps               | Color  |
|---------------------|--------|
| 0 - 6,999           | Red    |
| 7,000 - 9,999       | Orange |
| 10,000 - 12,499     | Yellow |
| 12,500+             | Green  |

Workout-earned green (any single workout scoring 8 pts) overrides the step tier. Visually distinguished on the complication with a thin ring around the number; step-green has no ring.

## 4. Architecture (hybrid)

Both devices read HealthKit independently.

- **Apple Watch**: reads today's step count + workout history directly from HealthKit; maintains its own complication timeline via WidgetKit. Works with phone absent (e.g. run without phone).
- **iPhone**: reads HealthKit, schedules and delivers notifications (iOS's HKObserverQuery + background delivery is more reliable than watchOS's). Hosts settings UI and handles HealthKit authorization prompts.

No critical data crosses WatchConnectivity - both devices independently read the source of truth (HealthKit). Only settings sync across. Notifications are fired by the iPhone and ring through to the watch via the standard iOS/watchOS notification pairing.

## 5. Modules

```
watch-stepcounter/
  Sources/
    StepsToEightCore/           # Pure logic, no UIKit/HealthKit. Testable via swift test.
  Tests/
    StepsToEightCoreTests/
  App/
    iOS/                        # iPhone app target
    Watch/                      # Watch app target
    Complication/               # Watch widget extension
    Shared/                     # Health/Settings adapters shared by app targets
  project.yml                   # xcodegen spec
  docs/superpowers/specs/
    2026-04-18-stepstoeight-design.md
```

### 5.1 `StepsToEightCore` (Swift package)

Pure, testable. No platform dependencies.

- `StepTier { red, orange, yellow, green }` with `StepTier.from(steps:)`.
- `VitalityPoints.fromSteps(_ steps:) -> Int` returning 0/3/5/8.
- `VitalityPoints.fromWorkout(durationMinutes:, avgHR:, maxHR:) -> Int` returning 0/5/8 per the three rules.
- `MaxHeartRate.from(age:) -> Double`.
- `NudgeZone { below7k, below10k, below12500 }` with `NudgeZone.current(steps:)` returning the zone if `steps in 6500..6999 | 9500..9999 | 12000..12499`.
- `DayState { steps, workoutGreen, tier, nudgeZone }` computed from raw inputs.
- `NotificationDecision` - pure function:
  - inputs: `DayState`, `now: Date`, `Settings`, `NotificationHistory`
  - output: `.nudge(NudgeZone) | .report(DayState) | .suppress`

### 5.2 iPhone app (`StepsToEightPhone`)

- `StepsToEightApp.swift` - `@main` SwiftUI app.
- `RootView.swift` - onboarding (permissions) + settings UI.
- `HealthKitStore.swift` - authorization, DOB fetch, step `HKStatisticsCollectionQuery`, workout `HKSampleQuery`, `HKObserverQuery` with background delivery enabled for both.
- `NotificationScheduler.swift` - on each HealthKit observer fire: compute `DayState`, evaluate `NotificationDecision`, deliver via `UNUserNotificationCenter`.
- `SettingsStore.swift` - `@AppStorage`, synced via WatchConnectivity `updateApplicationContext`.

Info.plist: `NSHealthShareUsageDescription`, `UIBackgroundModes: ["processing", "fetch"]`, `NSUserActivityTypes` (for the settings deep-link).

### 5.3 Watch app (`StepsToEightWatch`)

- `StepsToEightWatchApp.swift` - `@main`.
- `MainView.swift` - shows today's step count, tier, workout-green flag (primarily a debug / "does the app work" surface; complication is the real product).
- `HealthKitStore.swift` - watch-local duplicate of iPhone's; shared logic via Core.
- On HealthKit update: call `WidgetCenter.shared.reloadAllTimelines()`.

### 5.4 Complication (`StepsToEightComplication`)

Watch widget extension.

- `Widget.swift` - `@main` struct; supported families: `accessoryCircular`, `accessoryRectangular`, `accessoryCorner`, `accessoryInline`.
- `StepsProvider.swift` - `TimelineProvider`: reads `DayState` from HealthKit, builds a timeline spanning the current day with 15-min entries (and one at local midnight to force reset).
- `StepsEntry.swift` - `TimelineEntry { date, dayState }`.
- Per-family views:
  - `CircularView` - big number, color by tier, thin SF Symbols-style ring if workout-green.
  - `RectangularView` - "12,543 steps" + mini progress bar. Workout-green ring around the icon.
  - `CornerView` - arc + number.
  - `InlineView` - "12,543 steps" (plain text, no color, inline family restriction).

## 6. Data flow

1. First launch (iPhone): request HealthKit auth (step count read, workout read, DOB read); request notification authorization; enable background delivery for observer queries.
2. `HKObserverQuery` on `stepCount` and `workoutType()` fires when new data arrives.
3. Handler computes `DayState`, writes to shared storage, passes to `NotificationScheduler` which evaluates `NotificationDecision`.
4. If `.nudge` or `.report`, deliver via `UNMutableNotificationContent` (or schedule via `UNTimeIntervalNotificationTrigger` for future times). Record in `NotificationHistory` (per-day key).
5. Watch independently does the same observer + timeline reload. No data round-trip required.

## 7. Notification logic

Implemented as a pure function `NotificationDecision.evaluate(state:now:settings:history:) -> Action`:

Let `now` be the current time. Settings default: `reportTime = 20:00`, `nudgeStartTime = 19:00`, `notificationsEnabled = true`.

- If `!settings.notificationsEnabled`: return `.suppress`.
- If `now < settings.nudgeStartTime`: return `.suppress`.
- If `now >= settings.reportTime` and `!history.reportedToday`:
  - If `state.nudgeZone != nil`: return `.nudge(state.nudgeZone)` (overrides green suppression).
  - Else if `state.isGreen`: return `.suppress` (still record as "handled").
  - Else: return `.report(state)`.
- Else if `now >= settings.nudgeStartTime` and `state.nudgeZone != nil` and `!history.nudgedForZone(state.nudgeZone)`:
  - Return `.nudge(state.nudgeZone)`.
- Else: `.suppress`.

`NotificationHistory` resets at local midnight.

Zones:
- `below7k`: steps in 6500..6999
- `below10k`: steps in 9500..9999
- `below12500`: steps in 12000..12499 (8pm only, per user)

Notification copy:
- `.nudge(below7k)`: "200 to go - hit 7,000 today to earn 3 Vitality points."
- `.nudge(below10k)`: "Almost at 10,000 - 340 more for 5 points."
- `.nudge(below12500)`: "Nearly there - 180 steps to 12,500 and the full 8."
- `.report(state)`: "12,210 steps today - yellow tier, 5 points."
- `.report(state, workoutGreen: true)`: "Green via workout! 9,840 steps today - full 8 points already locked in."

## 8. Settings

Stored in `@AppStorage` on iPhone. Synced to Watch via `WCSession.updateApplicationContext`.

| Key                    | Type   | Default           | Notes                                              |
|------------------------|--------|-------------------|----------------------------------------------------|
| `notificationsEnabled` | Bool   | true              |                                                    |
| `nudgeStartTime`       | Date   | 19:00             | Minute precision; time-of-day only.                |
| `reportTime`           | Date   | 20:00             | 8pm notification.                                  |
| `dobOverride`          | Date?  | nil               | Used only when HealthKit DOB missing.              |

## 9. Error handling and edge cases

- **HealthKit authorization denied**: onboarding shows explainer with deep link to Settings app. Complication shows "-" in red (red = below 7k convention).
- **DOB missing from HealthKit and no override set**: onboarding prompts for DOB override. Without DOB the workout-green path is disabled - app still tracks steps normally.
- **Midnight rollover**: everything keyed to `Calendar.current.startOfDay(for:)`. Notification history resets per-day. Timeline provider places an entry at next local midnight.
- **Multiple qualifying workouts**: each workout is scored independently (per Vitality's "from one type of workout" rule - points are not summed). If any single workout scores 8, `workoutGreen = true`.
- **Historical workout sync after the fact**: the observer query re-fires; state is recomputed; if `workoutGreen` newly becomes true, the 8pm evaluation will pick up the green status.
- **Watch without phone**: complication keeps working via local HealthKit. Notifications only fire from iPhone; if the phone is off, nudges may be delayed until it wakes.
- **App reinstall / permission reset**: observer queries are re-registered on `@main` launch.

## 10. Testing

### 10.1 Unit tests (`StepsToEightCoreTests` via `swift test`)

- `StepTierTests` - boundaries: 0, 6999, 7000, 9999, 10000, 12499, 12500.
- `VitalityPointsTests` - all three workout rule combinations + near-miss edges.
- `MaxHeartRateTests` - representative ages.
- `NudgeZoneTests` - zone boundaries.
- `NotificationDecisionTests` - full matrix of branches (pre-window, in-zone, green-suppress, green-nudge override, report-time, post-report, notifications-disabled, nudge-already-sent).

### 10.2 Manual device test checklist

Documented separately in `STATUS.md` for morning run-through.

## 11. Non-goals (YAGNI)

- Weekly 40-point total display.
- Historical charts / trends.
- Multi-user / account support.
- Other points-earning events (sleep, meditation, etc.).
- Other trackers (Fitbit, Garmin, Android).
