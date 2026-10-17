import 'package:brockmann/brockmann.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Page follows each finger delta and cancels a short drag', (
    tester,
  ) async {
    var selected = 0;
    await tester.pumpWidget(
      BrockmannApp(
        home: StatefulBuilder(
          builder: (c, set) => Scaffold(
            body: BrockmannPageSwitcher(
              selected: selected,
              pageCount: 3,
              onChanged: (v) => set(() => selected = v),
              child: Align(
                alignment: Alignment.topLeft,
                child: Text('page $selected'),
              ),
            ),
          ),
        ),
      ),
    );
    final finger = await tester.startGesture(const Offset(300, 200));
    await finger.moveBy(const Offset(-25, 0));
    await tester.pump();
    final before = tester.getTopLeft(find.text('page 0'));
    await finger.moveBy(const Offset(-20, 0));
    await tester.pump();
    expect(
      tester.getTopLeft(find.text('page 0')).dx - before.dx,
      closeTo(-20, .01),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await finger.up();
    await tester.pumpAndSettle();
    expect(selected, 0);
    expect(tester.getTopLeft(find.text('page 0')).dx, 0);
    final swipe = await tester.startGesture(const Offset(300, 200));
    await swipe.moveBy(const Offset(-140, 0));
    await tester.pump();
    final releasePosition = tester.getTopLeft(find.text('page 0')).dx;
    await swipe.up();
    await tester.pump();
    expect(selected, 1);
    expect(tester.getTopLeft(find.text('page 0')).dx, releasePosition);
    await tester.pump(const Duration(milliseconds: 100));
    final width = tester.view.physicalSize.width / tester.view.devicePixelRatio;
    expect(
      tester.getTopLeft(find.text('page 1')).dx -
          tester.getTopLeft(find.text('page 0')).dx,
      closeTo(width, .01),
    );
    await tester.pumpAndSettle();
    expect(find.text('page 0'), findsNothing);
    expect(tester.getTopLeft(find.text('page 1')).dx, 0);
  });

  testWidgets(
    'Title swipe selects one neighbour without manually panning labels',
    (tester) async {
      var selected = 0;
      await tester.pumpWidget(
        BrockmannApp(
          home: StatefulBuilder(
            builder: (c, set) => Scaffold(
              body: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: 320,
                  child: BrockmannPivot(
                    options: const ['one', 'two', 'three', 'four'],
                    selected: selected,
                    onChanged: (v) => set(() => selected = v),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.text('one')).dx, 12);
      final finger = await tester.startGesture(const Offset(250, 30));
      await finger.moveBy(const Offset(-100, 0));
      await tester.pump();
      expect(selected, 0);
      expect(tester.getTopLeft(find.text('one')).dx, 12);
      await finger.up();
      await tester.pumpAndSettle();
      expect(selected, 1);
      for (var i = 0; i < 2; i++) {
        await tester.drag(find.byType(BrockmannPivot), const Offset(-100, 0));
        await tester.pumpAndSettle();
      }
      expect(selected, 3);
      expect(tester.getBottomRight(find.text('four')).dx, closeTo(308, .1));
    },
  );
}
