import 'package:brockmann/brockmann.dart';

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
  testWidgets(
    'Ribbon gutters have one neutral colour without neighbour bleed',
    (tester) async {
      final boundary = GlobalKey();
      const theme = BrockmannThemeData(brightness: Brightness.light);
      await tester.pumpWidget(
        BrockmannApp(
          theme: theme,
          home: Scaffold(
            body: RepaintBoundary(
              key: boundary,
              child: SizedBox(
                width: 320,
                height: 200,
                child: BrockmannColorPicker(
                  label: 'colour',
                  schemes: windows8Palette(),
                  selected: 0,
                  variant: BrockmannPaletteVariant.ribbon,
                  onChanged: (_) {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final strip = tester.getTopLeft(
        find.byKey(const ValueKey('brockmann-colour-ribbon')),
      );
      final root = tester.getTopLeft(find.byKey(boundary));
      await tester.runAsync(() async {
        final image =
            await (boundary.currentContext!.findRenderObject()
                    as RenderRepaintBoundary)
                .toImage();
        final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        final y = (strip.dy - root.dy + 36).round();
        int pixel(int x) {
          final i = (y * image.width + x) * 4;
          return (data!.getUint8(i + 3) << 24) |
              (data.getUint8(i) << 16) |
              (data.getUint8(i + 1) << 8) |
              data.getUint8(i + 2);
        }

        for (var x = 44; x < 52; x++) {
          expect(pixel(x), theme.surface.toARGB32());
        }
        expect(pixel(24), windows8Palette()[0].primary.toARGB32());
        expect(pixel(72), windows8Palette()[1].primary.toARGB32());
        image.dispose();
      });
    },
  );
}
