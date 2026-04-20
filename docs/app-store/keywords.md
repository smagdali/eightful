# Keywords (100 characters max, comma-separated, no spaces after commas)

**Recommended string:**

```
steps,activity,points,target,complication,tracker,health,insurance,vitality,nudge,rewards,daily
```

*(99 characters)*

## Reasoning

- `steps,activity,points,target` - core functional terms
- `complication,tracker` - feature type (App Store search commonly includes "complication")
- `health,insurance` - audience intent
- `vitality` - direct intent match. Including this as a keyword (not in visible title/subtitle) is how most "compatible with X insurer" apps do it. Walks the line — check section 5.2.1 of App Store Review Guidelines before submission.
- `nudge,rewards,daily` - secondary hooks

## Keywords to avoid

- Brand names other than the one you've committed to risking ("Vitality"): Fitbit, Garmin, etc. — you don't integrate with them.
- Anything medical ("diagnosis", "treatment", "clinical") — triggers extra review.
- Vague superlatives ("best", "top") — Apple Review may ask you to drop.

## Per-locale overrides

You'll submit for the UK storefront (`en-GB`) as primary. Use `insurance,uk,british` only if you're adding a local variant. For `en-US` storefront, drop `vitality` (US Vitality is a different brand arrangement and the confusion risk is higher).
