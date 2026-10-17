import 'package:brockmann/brockmann.dart';
import 'package:brockmann_example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final width in [320.0, 412.0]) {
    for (final scale in [1.0, 2.0]) {
      for (final light in [false, true]) {
        testWidgets('Catalogue width $width / scale $scale / light $light', (
          tester,
        ) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = Size(width, 900);
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(() {
            tester.view.resetDevicePixelRatio();
            tester.view.resetPhysicalSize();
            tester.platformDispatcher.clearTextScaleFactorTestValue();
          });
          await tester.pumpWidget(Showcase(preferences: {'light': light}));
          await tester.pumpAndSettle();
          for (var page = 0; page < pages.length; page++) {
            tester
                .widget<BrockmannPivot>(find.byType(BrockmannPivot))
                .onChanged!(page);
            await tester.pump();
            for (var frame = 0; frame < 38; frame++) {
              await tester.pump(const Duration(milliseconds: 16));
            }
            expect(tester.takeException(), isNull, reason: pages[page]);
          }
          await tester.pumpWidget(const SizedBox());
        });
      }
    }
  }
  testWidgets('Editing survives navigation to another page and back', (
    tester,
  ) async {
    await tester.pumpWidget(const Showcase());
    final field = find.byType(TextFormField).first;
    await tester.ensureVisible(field);
    await tester.enterText(field, 'a new session');
    tester.widget<BrockmannPivot>(find.byType(BrockmannPivot)).onChanged!(0);
    await tester.pumpAndSettle();
    tester.widget<BrockmannPivot>(find.byType(BrockmannPivot)).onChanged!(1);
    await tester.pumpAndSettle();
    expect(find.text('a new session'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
