import 'package:brockmann/brockmann.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<Object?> backEvent(
  WidgetTester tester,
  String method, [
  double progress = 0,
]) async {
  Object? result;
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    'flutter/backgesture',
    const StandardMethodCodec().encodeMethodCall(
      MethodCall(method, {
        'touchOffset': [0.0, 200.0],
        'progress': progress,
        'swipeEdge': 0,
      }),
    ),
    (data) {
      if (data != null) {
        result = const StandardMethodCodec().decodeEnvelope(data);
      }
    },
  );
  return result;
}

void main() {
  testWidgets('Full-page choice supports predictive back cancel and commit', (
    tester,
  ) async {
    var value = 0;
    await tester.pumpWidget(
      BrockmannApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (c, set) => BrockmannPicker(
              label: 'destination',
              options: const ['studio', 'library'],
              selected: value,
              presentation: BrockmannPickerPresentation.fullPage,
              onChanged: (v) => set(() => value = v),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(BrockmannPicker));
    await tester.pumpAndSettle();
    expect(await backEvent(tester, 'startBackGesture'), true);
    await backEvent(tester, 'updateBackGestureProgress', .5);
    await tester.pump();
    await backEvent(tester, 'cancelBackGesture');
    await tester.pumpAndSettle();
    expect(find.text('destination'), findsOneWidget);
    expect(value, 0);
    expect(await backEvent(tester, 'startBackGesture'), true);
    await backEvent(tester, 'updateBackGestureProgress', .8);
    await tester.pump();
    await backEvent(tester, 'commitBackGesture');
    await tester.pumpAndSettle();
    expect(find.byType(BrockmannPicker), findsOneWidget);
    expect(value, 0);
  });
  testWidgets('Anchored choice is available at phone widths and commits once', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    var value = 0, commits = 0;
    await tester.pumpWidget(
      BrockmannApp(
        home: Scaffold(
          body: Center(
            child: StatefulBuilder(
              builder: (c, set) => BrockmannPicker(
                label: 'destination',
                options: const ['studio', 'library'],
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
    );
    await tester.tap(find.byType(BrockmannPicker));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(ListView),
        matching: find.text('library'),
      ),
    );
    await tester.pumpAndSettle();
    expect(value, 1);
    expect(commits, 1);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'Context menu honours disabled actions and returns typed choice',
    (tester) async {
      String? selected;
      await tester.pumpWidget(
        BrockmannApp(
          home: Scaffold(
            body: BrockmannContextMenu<String>(
              entries: const [
                BrockmannMenuEntry(
                  value: 'copy',
                  label: 'Copy',
                  icon: BrockmannIcon.copy,
                ),
                BrockmannMenuEntry(
                  value: 'delete',
                  label: 'Delete',
                  enabled: false,
                ),
              ],
              onSelected: (v) => selected = v,
              child: const SizedBox(
                width: 200,
                height: 100,
                child: Text('Hold'),
              ),
            ),
          ),
        ),
      );
      await tester.longPress(find.text('Hold'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(selected, isNull);
      await tester.tap(find.text('Copy'));
      await tester.pumpAndSettle();
      expect(selected, 'copy');
    },
  );
  testWidgets('Scroll feedback is installed for both axes', (tester) async {
    await tester.pumpWidget(
      BrockmannApp(
        home: Scaffold(
          body: Column(
            children: [
              Expanded(
                child: ListView(children: const [SizedBox(height: 1000)]),
              ),
              SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: const [SizedBox(width: 1000)],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.byType(StretchingOverscrollIndicator), findsNWidgets(2));
    await tester.drag(find.byType(ListView).first, const Offset(0, 100));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).last, const Offset(100, 0));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
