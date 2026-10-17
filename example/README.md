# Brockmann showcase

Eight interactive pages demonstrate the Flutter components, typography, colour schemes, desktop motion language and Android sound/haptics.

```sh
flutter pub get
flutter run --profile -d <android-device-id>
```

Use profile mode when assessing animation smoothness. Debug mode includes runtime checks and JIT work. The showcase starts on Controls; swipe or use the large title pivot to change pages. Previous titles remain in the scrollable strip.

Sound starts off. Essential haptics follow Android's touch-feedback setting. The Sound page contains independent audio/haptic modes and two-/three-tick previews. Preferences are saved locally. The motion page offers reduced motion, a ten-times-slower study mode, animated presets and a live flip tile.

```sh
flutter test
flutter drive --profile --driver=test_driver/integration_test.dart \
  --target=integration_test/showcase_test.dart -d <android-device-id>
```

The profile driver writes `build/previews/pixel-profile-report.json`. It samples intermediate animation frames while visiting all pages, exercises a dropdown, preloads native audio without playing it, and requests a brief confirmation haptic. A system-disabled haptic is a valid outcome.

To start at another page:

```sh
flutter run --profile --dart-define=BROCKMANN_PAGE=colour
```

See the library [README](../README.md) and [design guidelines](../docs/design-guidelines.md).
