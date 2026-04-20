# Privacy nutrition label

App Store Connect asks a sequence of questions. The honest answer for
Eightful is "we don't collect anything", but you still walk through the
questionnaire. Values below.

## Data linked to you

**None** - the app does not collect or link any data.

## Data not linked to you

**None** - the app does not collect data at all.

## Data used to track you

**None**.

## Question-by-question walkthrough

### "Do you or your third-party partners collect data from this app?"

**No.**

Because Eightful transmits nothing off-device, there is no collection.
Selecting "No" here skips the entire remaining questionnaire. Apple
then displays "Data Not Collected" on the App Store listing.

### Health & Fitness data category (if asked separately)

Eightful *reads* Health data via HealthKit with user permission, but
doesn't "collect" it in the App Store Connect sense (which means "we have
a copy that leaves the device"). Apple's definition of "collect" is explicit:
"to transmit it off the device in a way that allows you or your third-party
partners to access it for a period longer than what is necessary to service
the transmitted request in real time". We do none of that.

### HealthKit review notes

HealthKit apps should also explicitly state in their review notes that no
HealthKit data is transmitted off-device, and that the usage descriptions
accurately reflect what the app reads. Those strings live in:
- `App/iOS/Info.plist` -> `NSHealthShareUsageDescription`
- `App/Watch/Info.plist` -> `NSHealthShareUsageDescription`
- `App/Complication/Info.plist` -> `NSHealthShareUsageDescription`
- `App/Watch/Info.plist` -> `NSMotionUsageDescription`
- `App/Complication/Info.plist` -> `NSMotionUsageDescription`
