import 'package:brockmann/brockmann.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'Ribbon retains large square samples and scrolls without shrinking',
    (tester) async {
      var selected = 0;
      await tester.pumpWidget(
        BrockmannApp(
          home: Scaffold(
            body: SizedBox(
              width: 320,
              child: StatefulBuilder(
                builder: (context, set) => BrockmannColorPicker(
                  label: 'colour',
                  schemes: windows8Palette(),
                  selected: selected,
                  variant: BrockmannPaletteVariant.ribbon,
                  onChanged: (value) => set(() => selected = value),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final strip = find.byKey(const ValueKey('brockmann-colour-ribbon'));
      expect(tester.getSize(strip), const Size(320, 72));
      final origin = tester.getTopLeft(strip);
      await tester.tapAt(origin + const Offset(72, 36));
      await tester.pumpAndSettle();
      expect(selected, 1);
      await tester.dragFrom(
        origin + const Offset(72, 36),
        const Offset(-290, 0),
      );
      await tester.pumpAndSettle();
      final scroll = tester.state<ScrollableState>(
        find.descendant(of: strip, matching: find.byType(Scrollable)),
      );
      expect(scroll.position.pixels, greaterThan(0));
      expect(selected, 1);
      expect(tester.takeException(), isNull);
    },
  );
}
