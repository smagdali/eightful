# Notes for Apple Review

Paste this into the "Notes" field in App Store Connect. Pre-empts the
common questions for a HealthKit + Apple-Watch + third-party-brand-adjacent
app.

---

**Testing**

No login, no sign-up, no backend account. HealthKit permission is required;
Reviewer can grant via the iOS permission sheet on first launch. On the
watch companion, the same HealthKit sheet appears on first run.

To demonstrate step tiers end-to-end without walking: add step samples to
the Apple Health app on the review device (Health -> Browse -> Activity
-> Steps -> Add Data). Values that demonstrate each tier:
- 3,000 -> red
- 6,700 -> red (nudge zone under 7,000)
- 8,000 -> orange
- 9,700 -> red (nudge zone under 10,000)
- 11,000 -> yellow
- 12,200 -> red (nudge zone under 12,500)
- 13,000 -> green

**Trademark / affiliation**

Eightful is an independent third-party tool. It is NOT an official app from
Vitality Health Insurance or any other insurance provider. The term
"Vitality" appears in the app description and in the app's UI only to
describe the type of insurance activity rewards programme the app is
designed to complement, consistent with App Store Review Guideline 5.2.1
("referential use of trademarks for the purpose of describing compatibility").
The in-app About screen states this disclaimer explicitly.

The app does not use any Vitality-owned logos, imagery, branding, or
artwork. The icon is an original design.

**Background modes / HealthKit background delivery**

The iOS target registers for HealthKit background delivery so evening
nudge notifications can be evaluated even if the app isn't in the
foreground. No data is transmitted as a result of these wake-ups;
the app reads HealthKit, evaluates locally, and schedules (or suppresses)
a local notification.

**Privacy policy URL**

[your hosted URL]

**Contact for technical questions**

stefan@whitelabel.org
