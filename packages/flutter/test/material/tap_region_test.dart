// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> tapOutside(WidgetTester tester) async {
  // Find the RenderBox of the top-most Scaffold and tap outside any region.
  final RenderBox renderBox = tester.firstRenderObject(find.byType(Scaffold).last);
  final Offset outsidePoint = renderBox.localToGlobal(Offset.zero) + const Offset(200, 200);

  await tester.tapAt(outsidePoint);
  await tester.pump();
}

void main() {
  // Regression test for https://github.com/flutter/flutter/issues/153093.
  testWidgets('TapRegion onTapOutside should only trigger on the current route during navigation', (
    WidgetTester tester,
  ) async {
    const tapRegion1Key = ValueKey<String>('TapRegion');
    const tapRegion2Key = ValueKey<String>('TapRegion2');

    var count1 = 0;
    var count2 = 0;

    final tapRegion1 = TapRegion(
      key: tapRegion1Key,
      onTapOutside: (PointerEvent event) {
        count1 += 1;
      },
      behavior: HitTestBehavior.opaque,
      child: const SizedBox.square(dimension: 100),
    );

    final tapRegion2 = TapRegion(
      key: tapRegion2Key,
      onTapOutside: (PointerEvent event) {
        count2 += 1;
      },
      behavior: HitTestBehavior.opaque,
      child: const SizedBox.square(dimension: 100),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(child: tapRegion1),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                tester.element(find.byType(FloatingActionButton)),
                MaterialPageRoute<void>(
                  builder: (BuildContext context) => Scaffold(body: Center(child: tapRegion2)),
                ),
              );
            },
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap outside the first TapRegion to trigger onTapOutside.
    await tapOutside(tester);
    expect(count1, 1);
    expect(count2, 0);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // Tap outside the second TapRegion to trigger onTapOutside
    await tapOutside(tester);
    expect(count1, 2); // When the Fab is pressed, the first TapRegion is still active.
    expect(count2, 1);

    // Back to the first page.
    Navigator.pop(tester.element(find.byType(Scaffold).last));
    await tester.pumpAndSettle();

    // Tap outside the first TapRegion to trigger onTapOutside
    await tapOutside(tester);
    expect(count1, 3);
    expect(count2, 1);
  });

  // Regression test for https://github.com/flutter/flutter/issues/153093.
  testWidgets('TapRegion on non-current routes should not respond to onTapOutside events', (
    WidgetTester tester,
  ) async {
    const tapRegion1Key = ValueKey<String>('TapRegion1');
    const tapRegion2Key = ValueKey<String>('TapRegion2');

    var count1 = 0;
    var count2 = 0;

    final tapRegion1 = TapRegion(
      key: tapRegion1Key,
      onTapOutside: (PointerEvent event) {
        count1 += 1;
      },
      behavior: HitTestBehavior.opaque,
      child: const SizedBox.square(dimension: 100),
    );

    final tapRegion2 = TapRegion(
      key: tapRegion2Key,
      onTapOutside: (PointerEvent event) {
        count2 += 1;
      },
      behavior: HitTestBehavior.opaque,
      child: const SizedBox.square(dimension: 100),
    );

    await tester.pumpWidget(
      MaterialApp(
        initialRoute: '/',
        routes: <String, WidgetBuilder>{
          '/': (BuildContext context) => Scaffold(body: Center(child: tapRegion1)),
          '/second': (BuildContext context) => Scaffold(body: Center(child: tapRegion2)),
        },
        onGenerateInitialRoutes: (String initialRouteName) {
          return <Route<void>>[
            MaterialPageRoute<void>(
              builder: (BuildContext context) => Scaffold(body: Center(child: tapRegion1)),
            ),
            MaterialPageRoute<void>(
              builder: (BuildContext context) => Scaffold(body: Center(child: tapRegion2)),
            ),
          ];
        },
      ),
    );

    await tester.pumpAndSettle();

    // At this point, tapRegion2 is on top of tapRegion1.
    // Tap outside tapRegion2.
    await tapOutside(tester);
    expect(count1, 0); // tapRegion1 should not respond.
    expect(count2, 1); // tapRegion2 should respond.

    // Now pop the top route to reveal tapRegion1.
    Navigator.pop(tester.element(find.byType(Scaffold).last));
    await tester.pumpAndSettle();

    // Tap outside tapRegion1.
    await tapOutside(tester);
    expect(count1, 1); // tapRegion1 should respond.
    expect(count2, 1); // tapRegion2 should not respond anymore.
  });

  // Regression test for the consumeOutsideTaps issue when navigating between pages
  testWidgets('TapRegion with consumeOutsideTaps should not consume taps after navigation', (
    WidgetTester tester,
  ) async {
    const tapRegionKey = ValueKey<String>('TapRegion');
    const buttonKey = ValueKey<String>('Button');

    var buttonTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: TapRegion(
              key: tapRegionKey,
              consumeOutsideTaps: true,
              onTapOutside: (PointerEvent event) {},
              behavior: HitTestBehavior.opaque,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    tester.element(find.byType(GestureDetector)),
                    MaterialPageRoute<void>(
                      builder: (BuildContext context) => Scaffold(
                        body: Center(
                          child: ElevatedButton(
                            key: buttonKey,
                            onPressed: () {
                              buttonTapped = true;
                            },
                            child: const Text('Test Button'),
                          ),
                        ),
                      ),
                    ),
                  );
                },
                child: Container(width: 250.0, height: 250.0, color: Colors.blue),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Navigate to the second page
    await tester.tap(find.byKey(tapRegionKey));
    await tester.pumpAndSettle();

    // Verify that the button on the second page can be tapped
    // If consumeOutsideTaps is still active from the first page's TapRegion,
    // this tap would be consumed and buttonTapped would remain false
    await tester.tap(find.byKey(buttonKey));
    await tester.pumpAndSettle();

    expect(
      buttonTapped,
      true,
      reason: 'Button tap was not consumed by a TapRegion on a non-current route',
    );
  });
}
