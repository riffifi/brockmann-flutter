## 0.2.0 (unreleased)

- Add an adaptive layout layer: `BrockmannWindowSize`, `context.brockmannLayout`, `BrockmannResponsive`, `BrockmannGrid`, `BrockmannColumns`, `BrockmannContent`, `BrockmannSplitView`, `BrockmannAdaptiveScaffold` and `BrockmannNavigationList`.
- Add building blocks: `BrockmannSpace`, `BrockmannGap`, `BrockmannStack`, `BrockmannSection`, `BrockmannPageHeader`, `BrockmannButtonBar`, `BrockmannDivider`, `BrockmannStat`, `BrockmannPropertyList`, `BrockmannPlaceholder`.
- `BrockmannPage` gains `title`, `subtitle`, `onBack`, `actions` and a readable `maxContentWidth` (960 dp); the 48 dp inset now starts at 600 dp.
- Buttons gain `.primary`/`.text` constructors, `icon`, `destructive` and `expand`. Text fields gain hint, helper, submit, focus, max length, autofill, mono and suffix. List items gain leading glyph, trailing widget and caret. Badges and banners gain `BrockmannTone`; badge text keeps contrast on custom fills; banners take a follow-up action.
- Stepper shows whole numbers without `.0`, uses tabular figures, supports `formatValue` and exposes TalkBack increase/decrease. Range slider supports `formatValue`.
- Press release now follows the 160 ms guideline; pressables without tilt skip the per-frame transform, and redundant pressed rebuilds are removed.

- Use familiar core glyphs consistently across search, clear, removal, calendar navigation and horizontal/vertical overflow menus, following Microsoft icon/command principles while keeping typography primary.

- Give direct-input surfaces ownership over page swipes and surrounding scrolling; add a reusable interaction region and one handle-pickup haptic.
- Replace Material calendar/time dialogs with a custom calendar and 24-hour numeral wheels, including draft confirmation, bounds and accessibility.
- Make core sheets, menus, search, disclosure and picker navigation typography-led; remove the bottom navbar showcase and make tag deletion real.

- Replace historical ribbon styling with animated palette tiles and a saturation/brightness editor with hue and optional alpha.
- Add full-page/anchored dropdown presentation, Android predictive-back routes, directional scroll-edge stretch, adaptive and monochrome launcher layers.
- Improve dial arc/centre interaction and slider grab offset; fix stretched vertical meter geometry.
- Add checkbox, radio group, segmented control, range slider, stepper, chip, accordion, badge, banner, empty state, search and bottom navigation.
- Add typed context menus, action sheets, date/time pickers, 28 Phosphor icons in two weights, and three new showcase pages.

## 0.1.0

- Android-first Flutter library and separate eight-page showcase.
- Geist typography, light/dark themes, one-accent contrast tokens, closed Phosphor icon set.
- Touch controls, symmetric switch motion, animated selection pages, persistent pivot options.
- Windows 8 inspired colour schemes: grid, swatches, ribbon, horizontal/vertical, zero to three companions.
- Flat reorderable tiles, display widgets, overlays and reduced-motion support.
- Optional preloaded Android sound, quiet original cues, lifecycle handling and local showcase preferences.

- Independent Android haptic modes, double/triple outcome rhythms, lifecycle cancellation and reorder pickup/landing feedback.

- Anchored wide dropdown text handoff, smooth early cancellation, overflowing choices and animated keyboard candidates.
- Stable interrupted page exits with cached page paint; expanded regression coverage and Pixel profile validation.
- Edge-to-edge overlay bands with inset readable content; explicit text decoration prevents Flutter fallback yellow underlines.
- Mobile colour ribbon doubled in scale with 48 dp targets; showcase screen switcher spans the available screen width.
- Ribbon samples fill the band as squares; title pivots have end spacing and neighbour-selection swipes, while page drags track the finger directly.
- Restore reference ribbon composition with a fitted full palette and scrub input; finger-controlled turnstile progress retains staggered page entry.
- Keep ribbon columns large while scrolling overflow; square samples fill the band height and its container reserves only marker/companion space.
- Replace competing tinted column edges with single neutral ribbon gutters and clip samples to their cells; add a pixel-level colour separation check.
- Restore the reference ribbon’s continuous tinted columns and smaller centered bright squares, preserving readable scale through overflow scrolling.
