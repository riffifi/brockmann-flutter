import 'package:brockmann/brockmann.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'Hold, drag and release commits once; releasing outside cancels',
    (tester) async {
      var value = 0;
      var commits = 0;
      await tester.pumpWidget(
        BrockmannApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                child: StatefulBuilder(
                  builder: (c, set) => BrockmannPicker(
                    label: 'choice',
                    options: const ['one', 'two', 'three'],
                    selected: value,
                    presentation: BrockmannPickerPresentation.anchored,
                    onChanged: (v) => set(() {
                      value = v;
                      commits++;
                    }),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      var gesture = await tester.startGesture(
        tester.getCenter(find.byType(BrockmannPicker)),
      );
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump();
      final option = find.descendant(
        of: find.byType(ListView),
        matching: find.text('two'),
      );
      expect(option, findsOneWidget);
      await gesture.moveTo(tester.getCenter(option));
      await tester.pump(const Duration(milliseconds: 100));
      expect(commits, 0);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(value, 1);
      expect(commits, 1);
      gesture = await tester.startGesture(
        tester.getCenter(find.byType(BrockmannPicker)),
      );
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump();
      await gesture.moveTo(const Offset(2, 2));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(commits, 1);
      gesture = await tester.startGesture(
        tester.getCenter(find.byType(BrockmannPicker)),
      );
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump();
      await tester.binding.handlePopRoute();
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(commits, 1);
      expect(find.byType(ListView), findsNothing);
      await tester.pumpWidget(
        BrockmannApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                child: BrockmannPicker(
                  label: 'long choice',
                  options: List.generate(40, (i) => 'option $i'),
                  selected: 0,
                  presentation: BrockmannPickerPresentation.anchored,
                  onChanged: (v) {
                    value = v;
                    commits++;
                  },
                ),
              ),
            ),
          ),
        ),
      );
      gesture = await tester.startGesture(
        tester.getCenter(find.byType(BrockmannPicker)),
      );
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump();
      final panel = tester.getRect(find.byType(ListView));
      await gesture.moveTo(Offset(panel.center.dx, panel.bottom - 10));
      for (var frame = 0; frame < 100; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(commits, 1);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(commits, 2);
      expect(value, greaterThan(8));
      expect(tester.takeException(), isNull);
    },
  );
}
