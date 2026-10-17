import 'package:brockmann/brockmann.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Ribbon uses 48 dp colour targets and reveals selection', (
    tester,
  ) async {
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
    final strip = find.byType(SingleChildScrollView);
    expect(tester.getSize(strip).height, 176);
    final origin = tester.getTopLeft(strip);
    await tester.tapAt(origin + const Offset(72, 84));
    await tester.pumpAndSettle();
    expect(selected, 1);
    await tester.drag(strip, const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
