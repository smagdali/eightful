# Privacy policy - Eightful

HealthKit apps are required by Apple to link to a hosted privacy policy.
This is the text; host it at a stable URL (e.g. `whitelabel.org/eightful/privacy`)
before submitting.

---

## Privacy policy

*Last updated: 2026-04-21*

Eightful ("the app") is an independent Apple Watch complication and iPhone
companion that tracks your daily activity against the 8-point target used
by Vitality Health Insurance. Eightful is not affiliated with, endorsed
by, or connected to Vitality.

### What data the app reads

With your explicit permission, Eightful reads the following from Apple Health:

- Step count
- Workout records (type, duration, start and end time)
- Heart rate samples that coincide with those workouts
- Your date of birth (used to compute your estimated maximum heart rate for
  activity scoring; falls back to a manually entered date if not set in
  Apple Health)

On the Apple Watch, Eightful also reads your step count directly from the
CoreMotion pedometer so the number on your watch face updates in real time.

### What data the app stores

All storage is local to your device. Eightful does not run any servers and
does not transmit any data to the developer or any third party.

- **Settings** (notification time, notifications on/off, optional date-of-birth
  override) are stored in the app's sandbox on your device.
- **Notification history** (whether today's notification has already fired)
  is stored on your device and resets at local midnight.
- **Last-known step state** is cached locally so the watch complication can
  show a sensible number even if a sensor read fails momentarily; it never
  leaves your device and resets at local midnight.

None of this data is synced to iCloud, shared with the developer, shared
with an insurance provider, or shared with any third-party service.

### What data the app transmits

None. Eightful has no network calls to developer-operated servers. It does
not include third-party SDKs for analytics, advertising, crash reporting,
or attribution.

### Notifications

If you enable notifications, Eightful schedules a local notification at a
time you choose (default 20:00) summarising your step progress. The
notification is delivered by iOS / watchOS locally and does not involve any
network service.

### Children

Eightful does not knowingly collect information from anyone, of any age.
The app requires iOS 16 / watchOS 9 and parental consent under Apple's
family sharing rules.

### Your rights and control

- You can revoke Apple Health permissions at any time in iOS Settings ->
  Privacy & Security -> Health -> Eightful.
- You can disable notifications at any time in the app, or in iOS Settings.
- Deleting Eightful from your device deletes all data it stored.
- Because no data ever leaves your device, there is no remote data retention
  or deletion request to be made.

### Changes

If this policy changes, the "Last updated" date at the top will change.
Any material change that would cause more data to be read, stored, or
transmitted will also trigger a new iOS permission prompt.

### Contact

stefan@whitelabel.org
