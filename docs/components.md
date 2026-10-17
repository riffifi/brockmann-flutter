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
| Calendar / time | `showBrockmannDatePicker`, `showBrockmannTimePicker` | Returns null on cancellation. Native Flutter dialogs retain localization and accessibility. |
| Curated colour | `BrockmannColorPicker` | `brockmannPalette()` is the new default data set; custom named schemes are supported. |
| Arbitrary colour | `BrockmannColorField` | HSV plane with labelled sliders; enable `showAlpha` only when transparency is useful. |
| Search | `BrockmannSearchField` | Supply a controller. Clear emits an empty query through `onChanged`. Filtering belongs to the caller. |

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

`showBrockmannActionSheet(context, title: ..., entries: actions)` presents the same actions in a touch-friendly bottom sheet. Both menu helpers return null on cancellation. Marking an action destructive only changes its presentation; your application performs the action and decides whether confirmation is necessary.

## Composition

`BrockmannChip` represents a tag or filter, with an optional separate remove target. `BrockmannBadge` is noninteractive status text. `BrockmannBanner` combines an icon, title and persistent explanation, optionally dismissible. `BrockmannEmptyState` provides a title, message, icon and optional action.

`BrockmannAccordion` is controlled by `expanded` and `onChanged`; its content animates height while hidden content leaves hit testing and accessibility. Keep critical actions outside collapsed content.

`BrockmannNavigationBar` takes `BrockmannDestination(label, icon)` values and a controlled index. Put it in `BrockmannPage.footer` for persistent bottom navigation. Use `BrockmannPivot` for the large typographic screen switcher. Neither widget creates domain routes on its own.

## Iconography

Phosphor is the single icon family: 45 icons, regular at normal sizes and bold at 16 dp or below. Use `BrockmannGlyph` for decoration and `BrockmannIconButton` for actions. An icon button always needs a meaningful spoken label. Do not replace a clear text action with an unfamiliar icon. New assets retain the [Phosphor MIT license](https://github.com/phosphor-icons/core).

## Android integration

The full-screen choice is a page route using Flutter’s [predictive-back transition](https://docs.flutter.dev/platform-integration/android/predictive-back). Anchored choices retain the selected-row reveal/text handoff. Use `PopScope` for an ahead-of-time pop decision; cancellation must leave selection unchanged.

The showcase includes separate adaptive icon foreground/background layers and Android 13+ monochrome support, following [Android’s adaptive icon model](https://developer.android.com/develop/ui/views/launch/icon_design_adaptive). These assets brand the showcase; applications supply their own launcher identity.

Boundary stretch uses the actual scroll axis and direction, so top/bottom and left/right remain consistent for reversed lists. Retain the application scroll behavior when constructing custom scroll views. Use a live meter for signal levels and `BrockmannProgress` for work progress; a vertical meter stays 4 dp wide even inside a stretched layout.
