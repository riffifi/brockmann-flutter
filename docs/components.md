# Building application interfaces

All controls are controlled: keep values in your owning state and update them in callbacks. Text controllers and domain data belong to the application. Null callbacks disable input. The library supplies presentation and interaction; it does not implement account systems, networking, file permissions or application storage.

## Choosing the right input

| Need | API | Guidance |
| --- | --- | --- |
| Boolean / mixed selection | `BrockmannCheckbox` | Enable `tristate` only for a meaningful mixed state. The label toggles too. |
| Immediate on/off | `BrockmannSwitch` | For settings that apply immediately. |
| Mutually exclusive list | `BrockmannRadioGroup<T>` | Keep short choices visible and name each using `labelFor`. |
| Few related modes | `BrockmannSegmentedControl<T>` | Wraps at small widths rather than hiding modes. |
| Long selection | `BrockmannPicker` | `fullPage` for focus; `anchored` to retain context; `adaptive` to choose by width. |
| Single number | `BrockmannSlider`, `BrockmannKnob` | Slider for general input, dial for spatial/audio parameter interfaces. |
| Numeric interval | `BrockmannRangeSlider` | Uses `RangeValues`, optional `min`, `max` and `divisions`. |
| Exact small counts | `BrockmannStepper` | Set a sensible `min`, `max` and positive `step`. |
| Calendar / time | `showBrockmannDatePicker`, `showBrockmannTimePicker` | Returns null on cancellation. Custom calendar and numeral-wheel dialogs keep a draft until confirmation. Calendar headers and date names use the active locale; the time editor uses explicit 24-hour numerals. |
| Curated colour | `BrockmannColorPicker` | `brockmannPalette()` is the new default data set; custom named schemes are supported. |
| Arbitrary colour | `BrockmannColorField` | HSV plane with labelled sliders; enable `showAlpha` only when transparency is useful. |
| Search | `BrockmannSearchField` | Large query text and a written clear action, with no search pictogram. Supply a controller. Clear emits an empty query through `onChanged`. Filtering belongs to the caller. |

Dial arc dragging tracks relative angular movement without wrap jumps. Tapping the arc sets the corresponding value. Dragging the centre vertically changes the value gently. External updates animate; direct touch updates immediately. Continuous controls stay silent.

## Menus and secondary actions

Use `BrockmannMenuEntry<T>` to define typed actions once:

```dart
const actions = [
  BrockmannMenuEntry(value: 'copy', label: 'Copy', icon: BrockmannIcon.copy),
  BrockmannMenuEntry(value: 'delete', label: 'Delete',
    icon: BrockmannIcon.trash, destructive: true),
];
```

`BrockmannContextMenu<T>` wraps a child and opens on hold or secondary click; it delivers the selected value through `onSelected`. Its child should offer a visible alternate action for users who cannot discover long press. `showBrockmannContextMenu` accepts a global `position` for an explicit menu button. Disabled entries never return a result.

`showBrockmannActionSheet(context, title: ..., entries: actions)` presents the same actions in a touch-friendly bottom sheet. Both menu helpers return null on cancellation. They are text-only by default, even if entries carry optional icon metadata. `showIcons: true` is available on the explicit helper functions for unusual cases where imagery is the content, not as the default action language. Marking an action destructive only changes its presentation; your application performs the action and decides whether confirmation is necessary.

## Composition

`BrockmannChip` represents a tag or filter, with an optional separate written remove target. The owner must remove the item from its collection inside `onDeleted`; the showcase demonstrates actual removal. `BrockmannBadge` is noninteractive status text. `BrockmannBanner` combines a title and persistent explanation, with an optional icon, optionally dismissible. Banners and empty states omit icons unless a caller explicitly supplies one. `BrockmannEmptyState` provides a title, message and optional icon/action.

`BrockmannAccordion` is controlled by `expanded` and `onChanged`; its content animates height while hidden content leaves hit testing and accessibility. Keep critical actions outside collapsed content.

The primary navigation pattern is the typographic pivot. The optional compatibility widget `BrockmannNavigationBar` takes `BrockmannDestination(label, icon)` values and a controlled index. It is no longer demonstrated or recommended as the default bottom-navigation treatment. Use `BrockmannPivot` for the large typographic screen switcher. Neither widget creates domain routes on its own.

## Typography and optional iconography

Typography is the primary design feature. Name actions directly: close, clear, remove, previous month, use date, and cancel. Action sheets, context menus and search use words. Simple arrows and carets are the core icon exceptions for back/previous/next navigation and disclosure. Icons are not a substitute for a clear label or the default decoration on every row.

Phosphor remains available when a visual symbol carries useful content: 45 icons, regular at normal sizes and bold at 16 dp or below. Use `BrockmannGlyph` for deliberate illustrations and `BrockmannIconButton` for explicit icon-based tools. Arrows and carets are allowed structural cues. Selection checks and numeric-control symbols describe state and values; they are not a general action language. Assets retain the [Phosphor MIT license](https://github.com/phosphor-icons/core).

## Direct manipulation and handle feedback

`BrockmannInteractionRegion` gives a custom direct-input surface priority over `BrockmannPageSwitcher`. A pointer beginning in that region is excluded from page navigation before the page recognizer enters the gesture arena. Region-local drag thresholds are small so a surrounding scrolling list does not capture an intentional colour or dial drag. Page whitespace remains swipeable. Wrap custom pads, editors and other continuous surfaces in the same widget.

Built-in colour planes, dials, sliders, range sliders and time wheels already use the region. Disabled controls do not claim gestures.

Slider and range handles emit one tactile pickup after a 160 ms hold, or when dragging starts first. The same gesture never repeats an impact and emits no sound. Feedback uses the shared controller's native drag-start cue and respects haptic mute, lifecycle and Android settings. Supplying `BrockmannApp(feedback: controller)` enables this independently of audio.

## Custom calendar and time editor

Use `BrockmannCalendar(value: ..., firstDate: ..., lastDate: ..., onChanged: ...)` inline. Month navigation, year selection, weekday headers and date cells are all typographic. Out-of-range days are disabled, leap days are represented by actual calendar dates, and the selected day has a clear inverse fill. `showBrockmannDatePicker` wraps this in an edge-to-edge band with use date and cancel actions.

`BrockmannTimePicker(value: ..., onChanged: ...)` is an inline 24-hour editor with hour and minute numeral wheels, selection rules and TalkBack increment/decrement actions. Wheel dimensions adapt to text scaling. `showBrockmannTimePicker` keeps wheel changes as a draft until use time is pressed. Neither helper delegates its UI to Material's calendar or clock dialog.

## Android integration

The full-screen choice is a page route using Flutter’s [predictive-back transition](https://docs.flutter.dev/platform-integration/android/predictive-back). Anchored choices retain the selected-row reveal/text handoff. Use `PopScope` for an ahead-of-time pop decision; cancellation must leave selection unchanged.

The showcase includes separate adaptive icon foreground/background layers and Android 13+ monochrome support, following [Android’s adaptive icon model](https://developer.android.com/develop/ui/views/launch/icon_design_adaptive). These assets brand the showcase; applications supply their own launcher identity.

Boundary stretch uses the actual scroll axis and direction, so top/bottom and left/right remain consistent for reversed lists. Retain the application scroll behavior when constructing custom scroll views. Use a live meter for signal levels and `BrockmannProgress` for work progress; a vertical meter stays 4 dp wide even inside a stretched layout.
