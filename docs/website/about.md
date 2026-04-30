# Eightful

<p align="center">
  <img src="screenshots/icon.png" alt="Eightful app icon: a magenta 8 on black" width="160">
</p>

An Apple Watch complication and iPhone app that shows your progress toward the 8-point daily activity target used by [Vitality Health](https://www.vitality.co.uk).

The colour changes as you approach or cross thresholds. White below 6,500 steps. **Red** when you're within 500 steps of 7,000, 10,000 or 12,500, as a visual cue that you're close. Orange, yellow and green as you reach 3, 5 and 8 points.

<p align="center">
  <img src="screenshots/watch-circular.png" alt="Apple Watch showing the Eightful circular complication with an orange 8.3k step count and 3 points" width="260">
</p>

## Why

The official Vitality app tells you what you've already earned. It's not great at nudging you before near misses. I created Eightful because I kept having near misses, and missing out when a few more steps would have got me to my daily 8 or weekly 40.

## What it does

- **Live step count** on your watch face, colour-coded by points tier
- **One daily nudge** at a time you choose - silent if you've hit green, loud when you're 500 steps from a point
- **Workout detection** - flips green early when a 60-min Zone 2 or 30-min Zone 3+ workout banks the 8 points ahead of steps, and tells you which workout and at what intensity
- **Week view** on iPhone - last week's points day by day in colour
- **Gentle on battery** - adaptive refresh: more frequent when you're walking, idle when you're not. NOTE: This sometimes means there is a bit of a lag, but unlike some other Pedometer apps, it should only ever undercount, not overcount. Clicking on the complication forces an update.

<p align="center">
  <img src="screenshots/iphone-today.png" alt="iPhone Today screen with 5,902 steps in green, 8 points, and an 8-point goal reached banner showing HIIT 52 min at 78% of max HR" width="260">
  <img src="screenshots/watch-app.png" alt="Eightful watch app showing 5,894 steps in green with 8 points and a heart, plus last-updated timestamp" width="260">
</p>

## Privacy

Everything happens on your devices. Step counts, workout data and settings stay on your watch and phone. Nothing is sent to Vitality, nothing goes anywhere else.

The apps I build track nothing.

Full [privacy policy](/eightful/privacy).

## Disclaimer

Eightful is an independent tool, not affiliated with, endorsed by, or connected to Vitality Health Insurance. The 7,000 / 10,000 / 12,500 step thresholds and HR-based workout rules implement Vitality's published activity scoring. For authoritative rules and point awards, check your Vitality Member account.

## Get it

[Download Eightful on the App Store](https://apps.apple.com/us/app/eightful/id6764133414)

## Support my work:

<a href="https://ko-fi.com/smagdali" target="_blank">☕ Buy Stef a coffee</a>

Eightful is free and always will be. If it's saving you points and you fancy it, you can throw a coffee my way.

## Contact

[stefan@whitelabel.org](mailto:stefan@whitelabel.org)

[Source on GitHub](https://github.com/smagdali/eightful)
