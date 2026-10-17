import 'package:brockmann/brockmann.dart';
import 'package:brockmann_example/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/material.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Android showcase, selection routes, and native audio preparation',
    (tester) async {
      final frames = <FrameTiming>[];
      void collect(List<FrameTiming> timings) => frames.addAll(timings);
      SchedulerBinding.instance.addTimingsCallback(collect);
      addTearDown(
        () => SchedulerBinding.instance.removeTimingsCallback(collect),
      );
      await tester.pumpWidget(const Showcase());
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BrockmannSwitch).first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      for (var page = 0; page < pages.length; page++) {
        tester.widget<BrockmannPivot>(find.byType(BrockmannPivot)).onChanged!(
          page,
        );
        await tester.pump();
        for (var frame = 0; frame < 38; frame++) {
          await tester.pump(const Duration(milliseconds: 16));
        }
        expect(tester.takeException(), isNull, reason: pages[page]);
      }
      tester.widget<BrockmannPivot>(find.byType(BrockmannPivot)).onChanged!(0);
      await tester.pumpAndSettle();
      final field = find.byType(BrockmannColorField);
      final plane = find.byKey(const ValueKey('brockmann-colour-plane'));
      await tester.ensureVisible(plane);
      final oldColour = tester.widget<BrockmannColorField>(field).value;
      final planeTouch = await tester.startGesture(
        tester.getRect(plane).center,
      );
      await planeTouch.moveBy(const Offset(110, 25));
      await tester.pump();
      await planeTouch.up();
      await tester.pumpAndSettle();
      expect(
        tester.widget<BrockmannPivot>(find.byType(BrockmannPivot)).selected,
        0,
      );
      final hue = find
          .descendant(
            of: find.byType(BrockmannColorField),
            matching: find.byType(BrockmannSlider),
          )
          .first;
      await tester.ensureVisible(hue);
      final hueTrack = find
          .descendant(of: hue, matching: find.byType(CustomPaint))
          .first;
      await tester.drag(hueTrack, const Offset(-110, 0));
      await tester.pumpAndSettle();
      expect(
        tester.widget<BrockmannPivot>(find.byType(BrockmannPivot)).selected,
        0,
      );
      expect(tester.widget<BrockmannColorField>(field).value, isNot(oldColour));
      tester.widget<BrockmannPivot>(find.byType(BrockmannPivot)).onChanged!(1);
      await tester.pumpAndSettle();
      final dial = find.byType(BrockmannKnob).first;
      await tester.ensureVisible(dial);
      final dialPaint = find
          .descendant(of: dial, matching: find.byType(CustomPaint))
          .first;
      final centre = tester.getCenter(dialPaint);
      final dialBefore = tester.widget<BrockmannKnob>(dial).value;
      final gesture = await tester.startGesture(centre + const Offset(36, 0));
      await gesture.moveTo(centre + const Offset(0, 36));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(tester.widget<BrockmannKnob>(dial).value, greaterThan(dialBefore));
      expect(
        tester.widget<BrockmannPivot>(find.byType(BrockmannPivot)).selected,
        1,
      );
      tester.widget<BrockmannPivot>(find.byType(BrockmannPivot)).onChanged!(9);
      await tester.pumpAndSettle();
      final anchored = find.byType(BrockmannPicker).last;
      await tester.ensureVisible(anchored);
      await tester.tap(anchored);
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(ListView),
          matching: find.text('about'),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<BrockmannPicker>(find.byType(BrockmannPicker).last)
            .selected,
        3,
      );
      final quick = await tester.startGesture(tester.getCenter(anchored));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 240));
      final quickOption = find.descendant(
        of: find.byType(ListView),
        matching: find.text('library'),
      );
      await quick.moveTo(tester.getCenter(quickOption));
      await tester.pump(const Duration(milliseconds: 160));
      expect(tester.widget<BrockmannPicker>(anchored).selected, 3);
      await quick.up();
      await tester.pumpAndSettle();
      expect(tester.widget<BrockmannPicker>(anchored).selected, 1);
      final actions = find.byWidgetPredicate(
        (w) => w is BrockmannButton && w.label == 'action sheet',
      );
      await tester.ensureVisible(actions);
      await tester.tap(actions);
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
      final sheetTitle = tester.widget<BrockmannText>(
        find.ancestor(
          of: find.text('Session actions'),
          matching: find.byType(BrockmannText),
        ),
      );
      expect(sheetTitle.role, BrockmannType.label);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      final dateButton = find.byWidgetPredicate(
        (w) => w is BrockmannButton && w.label.startsWith('date /'),
      );
      await tester.ensureVisible(dateButton);
      await tester.tap(dateButton);
      await tester.pumpAndSettle();
      final day = find.byKey(const ValueKey('brockmann-date-2026-10-19'));
      await tester.ensureVisible(day);
      await tester.tap(day);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('use date'));
      await tester.tap(find.text('use date'));
      await tester.pumpAndSettle();
      expect(find.text('date / 2026-10-19'), findsOneWidget);
      final timeButton = find.byWidgetPredicate(
        (w) => w is BrockmannButton && w.label.startsWith('time /'),
      );
      await tester.ensureVisible(timeButton);
      await tester.tap(timeButton);
      await tester.pumpAndSettle();
      final minute = find.byKey(const ValueKey('brockmann-time-minute'));
      await tester.ensureVisible(minute);
      await tester.drag(minute, const Offset(0, -80));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('use time'));
      await tester.tap(find.text('use time'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final backend = AndroidSoundBackend();
      expect(await backend.prepare(), isTrue);
      await backend.stop(); // Preload is tested without emitting a sound.
      final acceptedHaptic = await AndroidSoundBackend.channel
          .invokeMethod<bool>('haptics.play', {'cue': 'confirm'});
      expect(acceptedHaptic, isA<bool>());
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      await AndroidHapticBackend().cancel();
      tester.widget<BrockmannPivot>(find.byType(BrockmannPivot)).onChanged!(4);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BrockmannPicker));
      await tester.pumpAndSettle();
      await tester.tap(find.text('library'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<BrockmannPicker>(find.byType(BrockmannPicker)).selected,
        1,
      );
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(seconds: 1));
      double percentile(Iterable<int> values) {
        final sorted = values.toList()..sort();
        return sorted.isEmpty
            ? 0
            : sorted[((sorted.length - 1) * .95).round()] / 1000;
      }

      binding.reportData = {
        'frameCount': frames.length,
        'buildP95Ms': percentile(
          frames.skip(5).map((f) => f.buildDuration.inMicroseconds),
        ),
        'rasterP95Ms': percentile(
          frames.skip(5).map((f) => f.rasterDuration.inMicroseconds),
        ),
        'nativeAudioPreload': true,
        'nativeHapticsRequestAccepted': acceptedHaptic,
        'pages': pages,
      };
    },
  );
}
