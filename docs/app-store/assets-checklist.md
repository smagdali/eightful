# Assets checklist

What needs to exist before you can hit Submit.

## Done

- [x] App icon (1024x1024, in `App/iOS/Assets.xcassets/AppIcon.appiconset`)
- [x] Watch app icon (same, in `App/Watch/Assets.xcassets/AppIcon.appiconset`)
- [x] Widget/complication icon (same, in `App/Complication/...`)
- [x] HealthKit usage descriptions in all three Info.plists
- [x] Motion usage descriptions in watch + widget Info.plists
- [x] Entitlements configured (HealthKit, HealthKit background delivery, App Group)
- [x] Privacy policy drafted (`privacy-policy.md`)
- [x] Listing copy drafted (`description.md`)

## To do before submitting

- [ ] **Host privacy policy** at a stable URL (e.g. `whitelabel.org/eightful/privacy`)
- [ ] **Paid Apple Developer Program enrolment** - you said you have this
- [ ] **App Store Connect record** created under the name "Eightful"
- [ ] **Bundle ID registered** in Apple Developer portal (done on first Xcode run — auto-provisioning should have handled it)
- [ ] **App Group registered** - ditto, check in portal
- [ ] **Capture screenshots** per `screenshot-checklist.md`
  - [ ] iPhone 6.9" - 3 to 10 shots
  - [ ] Apple Watch 49mm - 3 shots
- [ ] **Archive & upload build** via Xcode (Product -> Archive -> Distribute App -> App Store Connect)
- [ ] **TestFlight** - probably worth a round before full submission

## Optional polish (nice-to-have)

- [ ] **App preview video** (15-30 sec, device screen recording) - the one most likely
  to move conversion is a 20 sec clip of: open app -> watch face complication ->
  walk animation (simulated steps rising) -> colour transitions -> nudge.
- [ ] **Localisations** - English (UK) is your primary storefront. Skip others
  until there's reason to add them.
- [ ] **Dark / light marketing** images - if you do a promo site

## Things specifically NOT needed

- Server infrastructure (no servers exist)
- Terms of service (no account, no transactional relationship)
- Cookie policy (no website beyond privacy page)
- GDPR DPO details (no controller/processor relationship with users)
