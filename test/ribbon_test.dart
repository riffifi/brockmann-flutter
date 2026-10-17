import 'package:brockmann/brockmann.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'Ribbon fits the complete palette and supports precise scrubbing',
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
      expect(tester.getSize(strip), const Size(320, 88));
      final origin = tester.getTopLeft(strip);
      await tester.tapAt(origin + const Offset(15, 42));
      await tester.pumpAndSettle();
      expect(selected, 1);
      await tester.dragFrom(
        origin + const Offset(15, 42),
        const Offset(290, 0),
      );
      await tester.pumpAndSettle();
      expect(selected, 30);
      expect(tester.takeException(), isNull);
    },
  );
}
