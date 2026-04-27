# Screenshot checklist

Apple requires iPhone screenshots at specific sizes. Apple Watch screenshots
are separate and also mandatory for watch apps. You don't need screenshots
for every listed device size - Apple upscales - but you do need the
largest supported.

## iPhone

Required: one set at **6.9"** (iPhone 16 Pro Max class, 1320x2868). Three
to ten shots.

Recommended shot list:

1. **Today screen** - ideally showing workout-green banner with the HIIT
   details (we have this: `docs/website/screenshots/iphone-today.png`)
2. **Today screen** - a non-green state with a colour-tier number, so
   reviewers see the tiering in action
3. **Week tab** - last week's points day by day, showing different colours
   on different days *(still to capture)*
4. **Settings** section expanded (nudge time picker, DOB field)
5. **About** section with the privacy disclaimer visible

Tool tip: capture on real device with **Volume Up + Side button**. Airdrop
to Mac. Do not annotate for v1. Apple rejects heavily photoshopped
composites.

## Apple Watch

Required: one set at **49mm / Ultra** size (410x502). Optional: 45mm, 41mm.

Recommended shot list:

1. **Watch face with the circular complication** in the "workout-green
   ring" state (we have this: `docs/website/screenshots/watch-circular.png`)
2. **Watch app main screen** with the big number and points (we have this:
   `docs/website/screenshots/watch-app.png`)
3. Optional: **watch face with rectangular complication** on a Modular face,
   to show the second layout

## How to capture a real watch screenshot

1. iPhone Watch app -> General -> **Enable Screenshots** -> On (one-time)
2. On the watch, bring up what you want to capture
3. Press **side button + Digital Crown** briefly
4. Screenshot lands in iPhone Photos
5. AirDrop to Mac

## Naming

App Store Connect re-orders by filename. Name them `01-today.png`,
`02-week.png`, etc. The files currently in `docs/website/screenshots/` are
suitable for direct upload to App Store Connect - they're captured at full
device resolution.
