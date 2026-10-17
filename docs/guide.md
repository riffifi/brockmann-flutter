# Usage guide

## Application and theme

Install `BrockmannApp` at the root, or add `BrockmannThemeData` to your own `ThemeData.extensions`. Read tokens with `context.brockmann`. `BrockmannPage` handles safe areas, keyboard resizing, and a scrolling body. Put persistent navigation in its `header`; use `scroll: false` when the child owns its scrolling viewport.

The showcase stores theme, accent, reduce-motion and sound preferences through `BrockmannPreferences`. This optional Android adapter stores simple primitive values in private application preferences. Application domain data belongs in your own storage.

Set `brightness`, `accent`, and optionally `reduceMotion`. The platform's animation accessibility setting is respected even when your own setting is false. `motionScale` is a study/debug setting, not an animation speed control to expose in every application.

## Controls

Update controlled values in `onChanged`. Disable with a null callback. Buttons separate primary, secondary and text styles. Use one primary action in a decision group. Text fields retain Flutter's IME, selection, clipboard and obscured entry behavior; supply either a controller or an initial value.

Sliders accept `min`, `max`, `step`, `defaultValue`, and `formatValue`. Keep labels above values; format units explicitly. Direct dragging follows the finger immediately; external slider changes animate over 240 ms. Double-tap restores `defaultValue`. Knobs use vertical drag with Shift for fine adjustment on hardware keyboards; also expose TalkBack increment and decrement. Prefer sliders when precision and discoverability matter on phones.

A switch animates both directions over 180 ms, with the desktop’s inset thumb geometry, retargeting from the current visual state if interrupted. Its value commits immediately; do not delay application state until the animation ends. Tapping a label operates the switch. Scrolling past it must not toggle it.

## Navigation and dropdowns

`BrockmannPivot` keeps all options in the layout. It scrolls only when needed and reveals the selected item with minimal movement; earlier destinations remain available by touch. Compact mode is appropriate for a catalogue with many destinations. Use short, distinct names.

Rapid page changes preserve each outgoing page’s current position and give it the full 250 ms exit. Outgoing pages stop receiving input and accessibility focus; incoming content retains its staggered entry. Use stable page identities and let `BrockmannPageSwitcher` own the transition.

`BrockmannPicker` opens a full selection page on phones, with the current item visible. Android Back or the visible close action cancels. A tap commits once and closes with a short fade/translation. On wider screens the bordered list is anchored around the selected row and clamped to the safe viewport. Enlarged text switches back to the full-page presentation. Closed controls have 16 dp of internal inset, separating the hover/press outline, label and value. The wide list reveals over 220 ms and closes over 200 ms, carrying a single selected label into its live field position even when the new value wraps. Early cancellation closes from the current geometry. Arrow keys, Home and End move the candidate with a 140 ms outline glide; Enter or Space commits, and Escape cancels. Candidate navigation never changes the model until commitment.

Dialog, menu and command surfaces extend edge to edge as flat bands; their content stays inset and is limited to 560 dp for readability. Horizontal system cutouts inset content without shrinking the surface. Dialog, menu and command helpers return the chosen string, or null on cancellation. Act on the returned result after checking `context.mounted`. Use confirmations only when they help the user make a real decision. Toasts are brief status messages; meaningful failures also need persistent visible text.

## Colour schemes

```dart
BrockmannColorPicker(
  label: 'Personal colour',
  schemes: windows8Palette(),
  selected: selected,
  companionCount: 2, // 0, 1, 2 or 3
  variant: BrockmannPaletteVariant.grid,
  onChanged: (index) => setState(() => selected = index),
)
```

Grid is the mobile default. `swatches` gives a larger scrolling strip; `ribbon` preserves the dense Windows 8 composition with tinted columns, small colour samples, and opposing hollow triangles. Set `axis: Axis.vertical` for a vertical strip and `verticalExtent` to constrain its scrolling viewport. The dense ribbon is best for deliberate comparison; use the grid for comfortable finger selection.

Schemes have a primary and up to three companion colours. Companions describe the selected palette; they do not automatically recolour the whole interface. Apply the selected primary to the app theme explicitly. Supply your own named schemes for a curated palette. Selection moves smoothly, remains visible, and includes a text name and hexadecimal value so colour alone never communicates selection.

## Tiles and reordering

Use flexible wraps or lists, allowing a tile to grow with its label and the user's text scale. A label and value occupy separate lines. Avoid fixed row heights that can overlap type.

`BrockmannReorderableList` owns its scroll viewport. Give every child a stable identity key. Hold for 250 ms to drag; neighbours animate into the opening. The proxy stays flat, without tilt or a shadow. TalkBack exposes Move earlier and Move later.

```dart
onReorder: (oldIndex, newIndex) {
  setState(() => items.insert(newIndex, items.removeAt(oldIndex)));
}
```

`newIndex` is already adjusted for removal by Flutter 3.47's `onReorderItem` API. Do not decrement it a second time. For longer lists, leave `shrinkWrap` false and place the list in an `Expanded` viewport rather than nesting it inside another scrolling list.

## Optional sound

Create one `BrockmannSoundController` for the application and dispose it with the owner. Pass it to `BrockmannApp(feedback: controller)`. Sound starts off. Explicitly enable `essential` or `subtle` with `configure`. Store the user's preference in your application. Default volume is 0.35.

Essential allows switches and confirm/reject outcomes; Subtle also allows selection, opening, closing, and primary activation. Continuous input, hover, focus, dragging and scrolling stay silent. Emit confirm/reject when an operation actually succeeds/fails, not when a button is pressed. `controller.play(BrockmannSound.confirm)` is the explicit outcome API.

Native Android uses a preloaded SoundPool, drops unavailable cues, and stops/releases on background or mute. Nothing waits to play later. A failed backend leaves the interface fully usable. To test without audio, inject a `BrockmannSoundBackend`. Do not create a controller per widget or request audio focus for UI clicks.

## Haptic feedback

Use `BrockmannFeedbackController` for independent audio and touch preferences. Essential haptics are enabled by default and defer to Android's system setting. Configure `haptics: BrockmannHapticMode.off` to disable them. Confirm is a short double tick; reject is a triple tick. Reorder pickup/landing use one native gesture effect each. Sound can stay off. See [haptic integration and guidelines](haptics.md).
