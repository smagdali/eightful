# Notes for Apple Review

Paste this into the "Notes" field in App Store Connect. Pre-empts the
common questions for a HealthKit + Apple-Watch + third-party-brand-adjacent
app.

---

**Testing**

No login, no sign-up, no backend account. On first launch:
- iPhone app asks for HealthKit read access (steps, workouts, heart rate,
  date of birth) and optionally notification permission.
- Watch app asks for HealthKit read access and CoreMotion (step counting).

Reviewers can grant both via the standard iOS / watchOS permission sheets.

To demonstrate the step tiers end-to-end without walking: add step samples
to the Apple Health app on the review device (Health -> Browse -> Activity
-> Steps -> Add Data). The big step number's colour follows:

- 3,000 -> **white** (below 6,500; no urgency yet)
- 6,700 -> **red** (nudge zone: 500 under 7,000)
- 8,000 -> **orange** (3 points earned)
- 9,700 -> **red** (nudge zone: 500 under 10,000)
- 11,000 -> **yellow** (5 points earned)
- 12,200 -> **red** (nudge zone: 500 under 12,500)
- 13,000 -> **green** (8 points, daily cap)

To test workout-green: add a workout sample in Health at 30+ minutes with
elevated heart rate, with the sample's heart-rate average > 70% of
(220 - age). The iPhone Today screen will show an "8-point goal reached"
banner with the workout's minutes and % max HR.

**Trademark / affiliation**

Eightful is an independent third-party tool, not an official app from
Vitality Health Insurance. "Vitality Health" appears in the app description
and UI as nominative / referential use: the app is designed specifically to
complement Vitality's published 8-point daily activity target, and no other
name accurately identifies that product. Consistent with App Store Review
Guideline 5.2.1, the use is purely descriptive; no Vitality logos, colours,
or artwork are used, and the in-app About screen states explicitly that
Eightful is not affiliated with or endorsed by Vitality. The app icon is
an original design (magenta "8" on black).

**CoreMotion (NSMotionUsageDescription)**

The watch app and widget extension read live step count from CMPedometer
to keep the complication fresh without the minutes-of-lag inherent in
HealthKit's sample-batching. All motion data stays on the device; nothing
is transmitted.

**HealthKit background delivery (iPhone only)**

The iOS target registers for HealthKit background delivery so the single
evening nudge notification can be evaluated even if the app isn't in the
foreground. No data is transmitted as a result of these wake-ups; the
app reads HealthKit, evaluates locally, and schedules or suppresses a
local notification. The watch target does NOT enable background delivery
to minimise battery impact.

**Privacy policy URL**

[your hosted URL]

**Contact for technical questions**

stefan@whitelabel.org
