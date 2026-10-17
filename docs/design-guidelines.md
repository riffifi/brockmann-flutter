# Design and motion guidelines

Brockmann combines typographic hierarchy, open space, and direct manipulation. Android adaptation preserves the visual language while giving fingers and accessibility services room to work.

- Use black or white surfaces, one primary accent, square edges, and hairline divisions. Avoid shadows, rounded cards, gloss, ripples, and decoration that competes with content.
- Use the desktop’s 4 dp base rhythm, grouping content in multiples of 8 or 16 dp. Start phone content at 24 dp from the edge, wider layouts at 48 dp. Use at least 48 dp hit areas even where the painted glyph is smaller.
- Use Geist Sans for language, Mono with tabular figures for changing values, and Pixel cuts for short expressive text. Never compress a label into the same space as a large readout.
- Keep long text flexible. Test at 320 dp width and 200% text size. Break button groups into wraps; keep destination labels reachable by scrolling rather than removing them.
- Give a selected item both a visual marker and selected semantics. Use inset markers and internal padding so a border never touches glyphs. Derive readable accent text separately from the raw accent fill.
- Put the mobile colour picker in a touch grid by default. The historical ribbon is a comparison variant, not the only input method.

## Motion

Motion communicates causality and position. A switch wipes in and out symmetrically over 180 ms. A palette marker moves for 180 ms. Dropdown panels reveal over 220 ms, with phone rows staggered by 30 ms, and close over 200 ms; a modal fade lasts 160 ms. Continuous drag position follows the finger without spring lag; Flutter animates reorder neighbours.

Press feedback is brief (60 ms down, 160 ms release). Do not hold an action pending a visual transition. Retarget an animation from its current state when input reverses. Respect the system's Disable animations setting as well as the application's own reduce-motion choice. Reduced mode removes spatial navigation movement and uses a short live-tile crossfade and stops indeterminate travel.

Use live tiles sparingly and provide useful static content. Indeterminate progress belongs only to real work and must be removed when work ends. Do not run invisible animation loops; off-page catalogue content is removed, and continuous widgets respect TickerMode.

## Sound

Silence is the baseline. Enable sound only by user choice. A restrained switch pop or outcome cue can reinforce a discrete event; it must not be the only way the event is communicated. Do not sonify every pointer event, repeat continuously while dragging, or compete with the user's media. See the research document for the evidence and the distinction between evidence and our design choices.

## Platform behavior

Keep safe areas, Android Back cancellation, native IME/clipboard, screen-reader actions, hardware keyboard activation, and OS text scaling. Use the full selection page on compact screens instead of fitting a tiny desktop popup into the phone. Trackpad and mouse scrolling use Flutter's pointer pipeline and Android's input processing; this port does not apply a second custom acceleration curve.

## Haptic rhythms

A deliberate physical gesture can have one tactile response. Essential mode covers committed switches, reorder pickup/landing and explicit outcomes. Use a brief double tick for confirmation and three spaced ticks for rejection. Subtle mode can add selections and opening/closing. Never repeat pulses throughout a continuous gesture. Sound and haptics have independent preferences; honor Android's system touch-feedback choice. Do not let a rhythm substitute for readable outcome text. Details and API: [haptics](haptics.md).
