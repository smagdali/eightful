# Eightful

An Apple Watch complication and iPhone app that shows your progress toward the 8-point daily activity target used by [Vitality Health](https://www.vitality.co.uk).

The difference is the colour. White below 6,500 steps. **Red** when you're within 500 steps of 7,000, 10,000 or 12,500 — push now, there's a point on the other side. Orange at 7,000 (3 pts), yellow at 10,000 (5 pts), green at 12,500 (8 pts — you're done).

Or, skip the step count entirely: record a run, cycle or swim at 60 minutes of 60%+ of your max heart rate — or 30 minutes of 70%+ — and the complication flips green early. Same 8 points, different path.

## Why

The official Vitality app is great at telling you what you've already earned. It's not great at nudging you before you miss a point. A night at 6,847 steps costs you 3 activity points; nobody finds out until tomorrow. Eightful is the thing on your wrist that reminds you, at a glance, that 153 steps stands between you and a point.

## What it does

- **Live step count** on your watch face, colour-graded by points tier
- **One daily nudge** at a time you choose (default 8pm): if you're 500 away from a threshold, it tells you exactly how many steps to go. If you've hit green, it stays silent.
- **Compare tab** for reconciling what you see in the Vitality Member app against what your Health data says. Surfaces systematic mismatches (wrong DOB, missed workouts, sync lag).
- **Workout-green detection**: records any HR-qualifying workout that independently earns 8 points, and tells you *which* workout and at what intensity on the Today screen.

## What it doesn't do

- Sign in, create an account, or sync anything online. Your Health data never leaves your device.
- Run a server. We don't have one.
- Replace the Vitality Member app — it can't log points for you. It tells you what you should expect to earn, and helps you get there.

## Privacy

Everything happens on your devices. Step counts, workout data, settings, and any points you manually enter in the Compare tab are stored locally. Nothing is sent to us (we have nowhere to send it to), nothing is sent to Vitality, nothing goes anywhere else.

Full [privacy policy](/eightful/privacy).

## Disclaimer

Eightful is an independent tool, not affiliated with, endorsed by, or connected to Vitality Health Insurance. The 7,000 / 10,000 / 12,500 step thresholds and HR-based workout rules implement Vitality's published activity scoring. For authoritative rules and point awards, check your Vitality Member account.

## Get it

App Store link coming soon.

## Contact

[stefan@whitelabel.org](mailto:stefan@whitelabel.org)

[Source on GitHub](https://github.com/smagdali/eightful)
