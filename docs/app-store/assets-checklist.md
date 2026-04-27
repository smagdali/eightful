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
- [x] Real device screenshots captured:
  - [x] Watch complication on Infograph face (`docs/website/screenshots/watch-circular.png`)
  - [x] Watch app main screen (`docs/website/screenshots/watch-app.png`)
  - [x] iPhone Today tab with workout-green banner (`docs/website/screenshots/iphone-today.png`)

## To do before submitting

- [ ] **Host privacy policy** at a stable URL (e.g. `whitelabel.org/eightful/privacy`). Paste `privacy-policy.md` contents; link from App Store Connect.
- [ ] **App Store Connect record** created under the name "Eightful"
- [ ] **Bundle ID** `org.whitelabel.eightful` registered in Apple Developer portal (done automatically on first Xcode device run)
- [ ] **App Group** `group.org.whitelabel.eightful` registered - ditto, check in portal
- [ ] **Capture the last missing screenshot**:
  - [ ] iPhone Week tab - should show last week's points day by day
- [ ] **Archive & upload build** via Xcode (Product -> Archive -> Distribute App -> App Store Connect). Current build number is 6.
- [ ] **TestFlight** - probably worth a round before full submission

## Optional polish (nice-to-have)

- [ ] **App preview video** (15-30 sec). Most compelling: 20-second clip showing app open, face with complication, walk animation causing colour transitions through the tiers, the nudge firing.
- [ ] **Localisations** - English (UK) is primary. Skip others until there's reason.
- [ ] **Dark / light marketing** images if you do a promo site.

## Things specifically NOT needed

- Server infrastructure (no servers exist)
- Terms of service (no account, no transactional relationship)
- Cookie policy (no website beyond privacy page + about page)
- GDPR DPO details (no controller/processor relationship with users)
