import 'package:brockmann/brockmann.dart';
import 'package:brockmann_example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'All six reorder variants fit a narrow screen at double text scale',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 900);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
        tester.platformDispatcher.clearTextScaleFactorTestValue();
      });
      await tester.pumpWidget(const Showcase());
      tester.widget<BrockmannPivot>(find.byType(BrockmannPivot)).onChanged!(3);
      await tester.pumpAndSettle();
      for (final axis in Axis.values) {
        tester
            .widget<BrockmannSegmentedControl<Axis>>(
              find.byType(BrockmannSegmentedControl<Axis>),
            )
            .onChanged!(axis);
        await tester.pumpAndSettle();
        for (final size in BrockmannTileSize.values) {
          tester
              .widget<BrockmannSegmentedControl<BrockmannTileSize>>(
                find.byType(BrockmannSegmentedControl<BrockmannTileSize>),
              )
              .onChanged!(size);
          await tester.pumpAndSettle();
          final tile = find.byWidgetPredicate(
            (w) => w is BrockmannTile && w.label == 'kick',
          );
          if (axis == Axis.vertical) {
            await tester.scrollUntilVisible(
              tile,
              200,
              scrollable: find
                  .descendant(
                    of: find.byType(BrockmannReorderableList),
                    matching: find.byType(Scrollable),
                  )
                  .first,
            );
          } else {
            await tester.ensureVisible(tile);
          }
          await tester.pumpAndSettle();
          expect(
            tester
                .widget<BrockmannReorderableList>(
                  find.byType(BrockmannReorderableList),
                )
                .axis,
            axis,
          );
          expect(tester.widget<BrockmannTile>(tile).size, size);
          expect(tester.getSize(tile).height, greaterThanOrEqualTo(88));
          expect(tester.takeException(), isNull, reason: '$axis $size');
          if (axis == Axis.vertical) {
            tester
                .state<ScrollableState>(
                  find
                      .descendant(
                        of: find.byType(BrockmannReorderableList),
                        matching: find.byType(Scrollable),
                      )
                      .first,
                )
                .position
                .jumpTo(0);
            await tester.pumpAndSettle();
          }
        }
      }
    },
  );

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
  testWidgets('Inputs keeps typography primary and actually removes tags', (
    tester,
  ) async {
    await tester.pumpWidget(const Showcase());
    tester.widget<BrockmannPivot>(find.byType(BrockmannPivot)).onChanged!(8);
    await tester.pumpAndSettle();
    expect(find.byType(BrockmannNavigationBar), findsNothing);
    final tag = find.byWidgetPredicate(
      (w) => w is BrockmannChip && w.label == 'removable',
    );
    await tester.ensureVisible(tag);
    await tester.tap(
      find.descendant(
        of: tag,
        matching: find.bySemanticsLabel('Remove removable'),
      ),
    );
    await tester.pumpAndSettle();
    expect(tag, findsNothing);
  });
}
