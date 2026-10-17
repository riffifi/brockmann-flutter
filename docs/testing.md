# Validation record

Validated on 17 October 2026 with Flutter 3.47.4 / Dart 3.13.3.

## Local checks

- `flutter analyze`: no issues.
- `flutter test` in the library: 27 passing tests.
- `flutter test` in the showcase: nine passing tests. Each catalogue page is sampled through intermediate animation frames at 320 and 412 dp, text scale 1 and 2, in both themes. A separate check verifies that editing survives navigation away and back.
- Android arm64 profile APK builds successfully with the native SoundPool and Activity-aware haptic plugin.

The library checks cover contrast, toggle reversal and drag commitment, active-tween continuity and idle scheduling, staggered entry, reduced spatial motion, retained pivot options, anchored text carry, first-step keyboard focus, early selection cancellation, overflowing lists, rapid page interruption, finger-scrubbed rotation and release continuity, fixed-size ribbon samples, pixel-checked neutral gutters and overflow scrolling, palette variants, flat reorder, independent audio/haptics, admission, lifecycle cancellation and native method-channel arguments.

## Physical Pixel 7

Connected device: Pixel 7, Android 17 / API 37. Profile-mode integration visits all eight pages, samples the animation frame by frame, selects from a full-page dropdown, preloads native sound without playing audio, and requests a short confirmation haptic. The run passed. Android accepted the haptic request; the exact physical feel remains a user/device judgment.

Recorded profile sample (before the ribbon sizing and finger-scrubbed turnstile refinements):

| Measurement | Result |
| --- | --- |
| Frames collected | 346 |
| Build duration, p95 | 6.639 ms |
| Raster duration, p95 | 15.704 ms |
| Native sound bank | Ready |
| Haptic request accepted | True |

The first five frames are omitted from percentile calculations. This is a single end-to-end sample with cold page/glyph work and the phone's normal background workload, not a controlled sustained-refresh benchmark. After adding page repaint boundaries, raster p95 measured 15.704 ms compared with 17.049 ms in the previous sample; workload variation also affects this comparison. The latest p95 fits a 60 Hz frame budget of 16.67 ms; individual frames can still exceed it, and this does not establish smooth rendering at every refresh rate.

## Reproduce

```sh
flutter analyze
flutter test
cd example
flutter test
flutter drive --profile --driver=test_driver/integration_test.dart \
  --target=integration_test/showcase_test.dart -d <device-id>
```

The driver writes `example/build/previews/pixel-profile-report.json`. Use an unlocked phone with the app in the foreground when checking haptics; a locked/background view intentionally declines tactile feedback. Do not change Android's haptic settings to force a passing result.

The normal interactive APK is `example/build/app/outputs/flutter-apk/app-profile.apk`. It is a development-signed profile build; the integration driver temporarily builds a different entry point, so rebuild the normal application before distributing that path to a reviewer.
