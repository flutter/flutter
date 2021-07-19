// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Allowable error to still consider floats equal.
  const double epsilon = 1e-6;

  Widget _boilerplate(VoidCallback? onButtonPressed, {
    int itemCount = 100,
    double initialChildSize = .5,
    double maxChildSize = 1.0,
    double minChildSize = .25,
    bool snap = false,
    List<double>? snapTargets,
    double? itemExtent,
    Key? containerKey,
    Key? stackKey,
    NotificationListenerCallback<ScrollNotification>? onScrollNotification,
  }) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: const MediaQueryData(),
        child: Stack(
          key: stackKey,
          children: <Widget>[
            TextButton(
              onPressed: onButtonPressed,
              child: const Text('TapHere'),
            ),
            DraggableScrollableActuator(
              child: DraggableScrollableSheet(
                maxChildSize: maxChildSize,
                minChildSize: minChildSize,
                initialChildSize: initialChildSize,
                snap: snap,
                snapTargets: snapTargets,
                builder: (BuildContext context, ScrollController scrollController) {
                  return NotificationListener<ScrollNotification>(
                    onNotification: onScrollNotification,
                    child: Container(
                      key: containerKey,
                      color: const Color(0xFFABCDEF),
                      child: ListView.builder(
                        controller: scrollController,
                        itemExtent: itemExtent,
                        itemCount: itemCount,
                        itemBuilder: (BuildContext context, int index) => Text('Item $index'),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  testWidgets('Scrolls correct amount when maxChildSize < 1.0', (WidgetTester tester) async {
    const Key key = ValueKey<String>('container');
    await tester.pumpWidget(_boilerplate(
      null,
      maxChildSize: .6,
      initialChildSize: .25,
      itemExtent: 25.0,
      containerKey: key,
    ));

    expect(tester.getRect(find.byKey(key)), const Rect.fromLTRB(0.0, 450.0, 800.0, 600.0));
    await tester.drag(find.text('Item 5'), const Offset(0, -125));
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byKey(key)), const Rect.fromLTRB(0.0, 325.0, 800.0, 600.0));
  });

  testWidgets('Scrolls correct amount when maxChildSize == 1.0', (WidgetTester tester) async {
    const Key key = ValueKey<String>('container');
    await tester.pumpWidget(_boilerplate(
      null,
      maxChildSize: 1.0,
      initialChildSize: .25,
      itemExtent: 25.0,
      containerKey: key,
    ));

    expect(tester.getRect(find.byKey(key)), const Rect.fromLTRB(0.0, 450.0, 800.0, 600.0));
    await tester.drag(find.text('Item 5'), const Offset(0, -125));
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byKey(key)), const Rect.fromLTRB(0.0, 325.0, 800.0, 600.0));
  });

  for (final TargetPlatform platform in TargetPlatform.values) {
    group('$platform Scroll Physics', () {
      debugDefaultTargetPlatformOverride = platform;

      testWidgets('Can be dragged up without covering its container', (WidgetTester tester) async {
        int taps = 0;
        await tester.pumpWidget(_boilerplate(() => taps++));

        expect(find.text('TapHere'), findsOneWidget);
        await tester.tap(find.text('TapHere'));
        expect(taps, 1);
        expect(find.text('Item 1'), findsOneWidget);
        expect(find.text('Item 21'), findsOneWidget);
        expect(find.text('Item 31'), findsNothing);

        await tester.drag(find.text('Item 1'), const Offset(0, -200));
        await tester.pumpAndSettle();
        expect(find.text('TapHere'), findsOneWidget);
        await tester.tap(find.text('TapHere'));
        expect(taps, 2);
        expect(find.text('Item 1'), findsOneWidget);
        expect(find.text('Item 21'), findsOneWidget);
        expect(find.text('Item 31'), findsOneWidget);
      }, variant: TargetPlatformVariant.all());

      testWidgets('Can be dragged down when not full height', (WidgetTester tester) async {
        await tester.pumpWidget(_boilerplate(null));
        expect(find.text('Item 1'), findsOneWidget);
        expect(find.text('Item 21'), findsOneWidget);
        expect(find.text('Item 36'), findsNothing);

        await tester.drag(find.text('Item 1'), const Offset(0, 325));
        await tester.pumpAndSettle();
        expect(find.text('Item 1'), findsOneWidget);
        expect(find.text('Item 21'), findsNothing);
        expect(find.text('Item 36'), findsNothing);
      }, variant: TargetPlatformVariant.all());

      testWidgets('Can be dragged down when list is shorter than full height', (WidgetTester tester) async {
        await tester.pumpWidget(_boilerplate(null, itemCount: 30, initialChildSize: .25));

        expect(find.text('Item 1').hitTestable(), findsOneWidget);
        expect(find.text('Item 29').hitTestable(), findsNothing);

        await tester.drag(find.text('Item 1'), const Offset(0, -325));
        await tester.pumpAndSettle();
        expect(find.text('Item 1').hitTestable(), findsOneWidget);
        expect(find.text('Item 29').hitTestable(), findsOneWidget);

        await tester.drag(find.text('Item 1'), const Offset(0, 325));
        await tester.pumpAndSettle();
        expect(find.text('Item 1').hitTestable(), findsOneWidget);
        expect(find.text('Item 29').hitTestable(), findsNothing);
      }, variant: TargetPlatformVariant.all());

      testWidgets('Can be dragged up and cover its container and scroll in single motion, and then dragged back down', (WidgetTester tester) async {
        int taps = 0;
        await tester.pumpWidget(_boilerplate(() => taps++));

        expect(find.text('TapHere'), findsOneWidget);
        await tester.tap(find.text('TapHere'));
        expect(taps, 1);
        expect(find.text('Item 1'), findsOneWidget);
        expect(find.text('Item 21'), findsOneWidget);
        expect(find.text('Item 36'), findsNothing);

        await tester.drag(find.text('Item 1'), const Offset(0, -325));
        await tester.pumpAndSettle();
        expect(find.text('TapHere'), findsOneWidget);
        await tester.tap(find.text('TapHere'), warnIfMissed: false);
        expect(taps, 1);
        expect(find.text('Item 1'), findsOneWidget);
        expect(find.text('Item 21'), findsOneWidget);
        expect(find.text('Item 36'), findsOneWidget);

        await tester.dragFrom(const Offset(20, 20), const Offset(0, 325));
        await tester.pumpAndSettle();
        await tester.tap(find.text('TapHere'));
        expect(taps, 2);
        expect(find.text('Item 1'), findsOneWidget);
        expect(find.text('Item 18'), findsOneWidget);
        expect(find.text('Item 36'), findsNothing);
      }, variant: TargetPlatformVariant.all());

      testWidgets('Can be flung up gently', (WidgetTester tester) async {
        int taps = 0;
        await tester.pumpWidget(_boilerplate(() => taps++));

        expect(find.text('TapHere'), findsOneWidget);
        await tester.tap(find.text('TapHere'));
        expect(taps, 1);
        expect(find.text('Item 1'), findsOneWidget);
        expect(find.text('Item 21'), findsOneWidget);
        expect(find.text('Item 36'), findsNothing);
        expect(find.text('Item 70'), findsNothing);

        await tester.fling(find.text('Item 1'), const Offset(0, -200), 350);
        await tester.pumpAndSettle();
        expect(find.text('TapHere'), findsOneWidget);
        await tester.tap(find.text('TapHere'));
        expect(taps, 2);
        expect(find.text('Item 1'), findsOneWidget);
        expect(find.text('Item 21'), findsOneWidget);
        expect(find.text('Item 36'), findsOneWidget);
        expect(find.text('Item 70'), findsNothing);
      }, variant: TargetPlatformVariant.all());

      testWidgets('Can be flung up', (WidgetTester tester) async {
        int taps = 0;
        await tester.pumpWidget(_boilerplate(() => taps++));

        expect(find.text('TapHere'), findsOneWidget);
        await tester.tap(find.text('TapHere'));
        expect(taps, 1);
        expect(find.text('Item 1'), findsOneWidget);
        expect(find.text('Item 21'), findsOneWidget);
        expect(find.text('Item 70'), findsNothing);

        await tester.fling(find.text('Item 1'), const Offset(0, -200), 2000);
        await tester.pumpAndSettle();
        expect(find.text('TapHere'), findsOneWidget);
        await tester.tap(find.text('TapHere'), warnIfMissed: false);
        expect(taps, 1);
        expect(find.text('Item 1'), findsNothing);
        expect(find.text('Item 21'), findsNothing);
        expect(find.text('Item 70'), findsOneWidget);
      }, variant: TargetPlatformVariant.all());

      testWidgets('Can be flung down when not full height', (WidgetTester tester) async {
        await tester.pumpWidget(_boilerplate(null));
        expect(find.text('Item 1'), findsOneWidget);
        expect(find.text('Item 21'), findsOneWidget);
        expect(find.text('Item 36'), findsNothing);

        await tester.fling(find.text('Item 1'), const Offset(0, 325), 2000);
        await tester.pumpAndSettle();
        expect(find.text('Item 1'), findsOneWidget);
        expect(find.text('Item 21'), findsNothing);
        expect(find.text('Item 36'), findsNothing);
      }, variant: TargetPlatformVariant.all());

      testWidgets('Can be flung up and then back down', (WidgetTester tester) async {
        int taps = 0;
        await tester.pumpWidget(_boilerplate(() => taps++));

        expect(find.text('TapHere'), findsOneWidget);
        await tester.tap(find.text('TapHere'));
        expect(taps, 1);
        expect(find.text('Item 1'), findsOneWidget);
        expect(find.text('Item 21'), findsOneWidget);
        expect(find.text('Item 70'), findsNothing);

        await tester.fling(find.text('Item 1'), const Offset(0, -200), 2000);
        await tester.pumpAndSettle();
        expect(find.text('TapHere'), findsOneWidget);
        await tester.tap(find.text('TapHere'), warnIfMissed: false);
        expect(taps, 1);
        expect(find.text('Item 1'), findsNothing);
        expect(find.text('Item 21'), findsNothing);
        expect(find.text('Item 70'), findsOneWidget);

        await tester.fling(find.text('Item 70'), const Offset(0, 200), 2000);
        await tester.pumpAndSettle();
        expect(find.text('TapHere'), findsOneWidget);
        await tester.tap(find.text('TapHere'), warnIfMissed: false);
        expect(taps, 1);
        expect(find.text('Item 1'), findsOneWidget);
        expect(find.text('Item 21'), findsOneWidget);
        expect(find.text('Item 70'), findsNothing);

        await tester.fling(find.text('Item 1'), const Offset(0, 200), 2000);
        await tester.pumpAndSettle();
        expect(find.text('TapHere'), findsOneWidget);
        await tester.tap(find.text('TapHere'));
        expect(taps, 2);
        expect(find.text('Item 1'), findsOneWidget);
        expect(find.text('Item 21'), findsNothing);
        expect(find.text('Item 70'), findsNothing);
      }, variant: TargetPlatformVariant.all());

      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('Does not snap away from initial child on build', (WidgetTester tester) async {
      const Key containerKey = ValueKey<String>('container');
      const Key stackKey = ValueKey<String>('stack');
      await tester.pumpWidget(_boilerplate(null,
        snap: true,
        initialChildSize: .7,
        containerKey: containerKey,
        stackKey: stackKey,
      ));
      await tester.pumpAndSettle();
      final double screenHeight = tester.getSize(find.byKey(stackKey)).height;

      // The sheet should not have snapped.
      expect(tester.getSize(find.byKey(containerKey)).height / screenHeight, closeTo(.7, epsilon));
    }, variant: TargetPlatformVariant.all());

    testWidgets('Does not snap away from initial child on reset', (WidgetTester tester) async {
      const Key containerKey = ValueKey<String>('container');
      const Key stackKey = ValueKey<String>('stack');
      await tester.pumpWidget(_boilerplate(null,
        snap: true,
        containerKey: containerKey,
        stackKey: stackKey,
      ));
      await tester.pumpAndSettle();
      final double screenHeight = tester.getSize(find.byKey(stackKey)).height;

      await tester.drag(find.text('Item 1'), Offset(0, -.4 * screenHeight));
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byKey(containerKey)).height / screenHeight, closeTo(1.0, epsilon));

      DraggableScrollableActuator.reset(tester.element(find.byKey(containerKey)));
      await tester.pumpAndSettle();

      // The sheet should have reset without snapping away from initial child.
      expect(tester.getSize(find.byKey(containerKey)).height / screenHeight, closeTo(.5, epsilon));
    }, variant: TargetPlatformVariant.all());

    testWidgets('Zero velocity drag snaps to nearest snap target', (WidgetTester tester) async {
      const Key stackKey = ValueKey<String>('stack');
      const Key containerKey = ValueKey<String>('container');
      await tester.pumpWidget(_boilerplate(null,
        snap: true,
        stackKey: stackKey,
        containerKey: containerKey,
        snapTargets: <double>[.25, .5, .75, 1.0],
      ));
      await tester.pumpAndSettle();
      final double screenHeight = tester.getSize(find.byKey(stackKey)).height;

      // We are dragging up, but we'll snap down because we're closer to .75 than 1.
      await tester.drag(find.text('Item 1'), Offset(0, -.35 * screenHeight));
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byKey(containerKey)).height / screenHeight, closeTo(.75, epsilon));

      // Drag up and snap up.
      await tester.drag(find.text('Item 1'), Offset(0, -.2 * screenHeight));
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byKey(containerKey)).height / screenHeight, closeTo(1.0, epsilon));

      // Drag down and snap up.
      await tester.drag(find.text('Item 1'), Offset(0, .1 * screenHeight));
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byKey(containerKey)).height / screenHeight, closeTo(1.0, epsilon));

      // Drag down and snap down.
      await tester.drag(find.text('Item 1'), Offset(0, .45 * screenHeight));
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byKey(containerKey)).height / screenHeight, closeTo(.5, epsilon));

      // Fling up with negligible velocity and snap down.
      await tester.fling(find.text('Item 1'), Offset(0, .1 * screenHeight), 1);
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byKey(containerKey)).height / screenHeight, closeTo(.5, epsilon));
    }, variant: TargetPlatformVariant.all());

    for (final List<double>? snapTargets in <List<double>?>[null, <double>[]]) {
      testWidgets('Setting snapTargets to $snapTargets resolves to min and max', (WidgetTester tester) async {
        const Key stackKey = ValueKey<String>('stack');
        const Key containerKey = ValueKey<String>('container');
          await tester.pumpWidget(_boilerplate(null,
            snap: true,
            stackKey: stackKey,
            containerKey: containerKey,
            snapTargets: snapTargets,
          ));
          await tester.pumpAndSettle();
          final double screenHeight = tester.getSize(find.byKey(stackKey)).height;

          await tester.drag(find.text('Item 1'), Offset(0, -.4 * screenHeight));
          await tester.pumpAndSettle();
          expect(tester.getSize(find.byKey(containerKey)).height / screenHeight, closeTo(1.0, epsilon));

          await tester.drag(find.text('Item 1'), Offset(0, .7 * screenHeight));
          await tester.pumpAndSettle();
          expect(tester.getSize(find.byKey(containerKey)).height / screenHeight, closeTo(.25, epsilon));
      }, variant: TargetPlatformVariant.all());
    }

    testWidgets('Min and max are implicitly added to snapTargets.', (WidgetTester tester) async {
      const Key stackKey = ValueKey<String>('stack');
      const Key containerKey = ValueKey<String>('container');
      await tester.pumpWidget(_boilerplate(null,
        snap: true,
        stackKey: stackKey,
        containerKey: containerKey,
        snapTargets: <double>[.5],
      ));
      await tester.pumpAndSettle();
      final double screenHeight = tester.getSize(find.byKey(stackKey)).height;

      await tester.drag(find.text('Item 1'), Offset(0, -.4 * screenHeight));
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byKey(containerKey)).height / screenHeight, closeTo(1.0, epsilon));

      await tester.drag(find.text('Item 1'), Offset(0, .7 * screenHeight));
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byKey(containerKey)).height / screenHeight, closeTo(.25, epsilon));
    }, variant: TargetPlatformVariant.all());

    testWidgets('Fling snaps in direction of momentum', (WidgetTester tester) async {
      const Key stackKey = ValueKey<String>('stack');
      const Key containerKey = ValueKey<String>('container');
      await tester.pumpWidget(_boilerplate(null,
        snap: true,
        stackKey: stackKey,
        containerKey: containerKey,
        snapTargets: <double>[.5, .75],
      ));
      await tester.pumpAndSettle();
      final double screenHeight = tester.getSize(find.byKey(stackKey)).height;

      await tester.fling(find.text('Item 1'), Offset(0, -.1 * screenHeight), 1000);
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byKey(containerKey)).height / screenHeight, closeTo(.75, epsilon));

      await tester.fling(find.text('Item 1'), Offset(0, .3 * screenHeight), 1000);
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byKey(containerKey)).height / screenHeight, closeTo(.25, epsilon));

    }, variant: TargetPlatformVariant.all());

    testWidgets('ScrollNotification correctly dispatched when flung without covering its container', (WidgetTester tester) async {
      final List<Type> notificationTypes = <Type>[];
      await tester.pumpWidget(_boilerplate(
        null,
        onScrollNotification: (ScrollNotification notification) {
          notificationTypes.add(notification.runtimeType);
          return false;
        },
      ));

      await tester.fling(find.text('Item 1'), const Offset(0, -200), 200);
      await tester.pumpAndSettle();

      // TODO(itome): Make sure UserScrollNotification and ScrollUpdateNotification are called correctly.
      final List<Type> types = <Type>[
        ScrollStartNotification,
        ScrollEndNotification,
      ];
      expect(notificationTypes, equals(types));
    });

    testWidgets('ScrollNotification correctly dispatched when flung with contents scroll', (WidgetTester tester) async {
      final List<Type> notificationTypes = <Type>[];
      await tester.pumpWidget(_boilerplate(
        null,
        onScrollNotification: (ScrollNotification notification) {
          notificationTypes.add(notification.runtimeType);
          return false;
        },
      ));

      await tester.flingFrom(const Offset(0, 325), const Offset(0, -325), 200);
      await tester.pumpAndSettle();

      final List<Type> types = <Type>[
        ScrollStartNotification,
        UserScrollNotification,
        ...List<Type>.filled(5, ScrollUpdateNotification),
        ScrollEndNotification,
        UserScrollNotification,
      ];
      expect(notificationTypes, types);
    });
  }
}
