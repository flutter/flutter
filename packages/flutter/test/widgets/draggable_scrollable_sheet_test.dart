// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';

import 'button_tester.dart';
import 'utils.dart';

void main() {
  Widget boilerplateWidget(
    VoidCallback? onButtonPressed, {
    DraggableScrollableController? controller,
    int itemCount = 100,
    double initialChildSize = .5,
    double maxChildSize = 1.0,
    double minChildSize = .25,
    bool snap = false,
    List<double>? snapSizes,
    Duration? snapAnimationDuration,
    double? itemExtent,
    double? cacheExtent,
    ScrollPhysics? physics,
    IndexedWidgetBuilder? itemBuilder,
    MediaQueryData mediaQueryData = const MediaQueryData(),
    Key? containerKey,
    Key? stackKey,
    NotificationListenerCallback<ScrollNotification>? onScrollNotification,
    NotificationListenerCallback<DraggableScrollableNotification>?
    onDraggableScrollableNotification,
    bool ignoreController = false,
    bool shouldCloseOnMinExtent = true,
  }) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: mediaQueryData,
        child: Stack(
          key: stackKey,
          children: <Widget>[
            TestButton(onPressed: onButtonPressed, child: const Text('TapHere')),
            DraggableScrollableActuator(
              child: DraggableScrollableSheet(
                controller: controller,
                maxChildSize: maxChildSize,
                minChildSize: minChildSize,
                initialChildSize: initialChildSize,
                snap: snap,
                snapSizes: snapSizes,
                snapAnimationDuration: snapAnimationDuration,
                shouldCloseOnMinExtent: shouldCloseOnMinExtent,
                builder: (BuildContext context, ScrollController scrollController) {
                  return NotificationListener<ScrollNotification>(
                    onNotification: onScrollNotification,
                    child: NotificationListener<DraggableScrollableNotification>(
                      onNotification: onDraggableScrollableNotification,
                      child: ColoredBox(
                        key: containerKey,
                        color: const Color(0xFFABCDEF),
                        child: ListView.builder(
                          controller: ignoreController ? null : scrollController,
                          physics: physics,
                          cacheExtent: cacheExtent,
                          itemExtent: itemExtent,
                          itemCount: itemCount,
                          itemBuilder:
                              itemBuilder ??
                              (BuildContext context, int index) => Text('Item $index'),
                        ),
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

  Widget buildKeyboardSheet({
    required DraggableScrollableController controller,
    FocusNode? focusNode,
    int focusIndex = 4,
  }) {
    final textControllers = List<TextEditingController>.generate(
      20,
      (int index) => TextEditingController(),
    );
    final focusNodes = List<FocusNode>.generate(
      20,
      (int index) => index == focusIndex && focusNode != null ? focusNode : FocusNode(),
    );
    addTearDown(() {
      for (final textController in textControllers) {
        textController.dispose();
      }
      for (final node in focusNodes) {
        if (node != focusNode) {
          node.dispose();
        }
      }
    });

    return TestWidgetsApp(
      home: Builder(
        builder: (BuildContext context) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
          child: boilerplateWidget(
            null,
            controller: controller,
            itemCount: textControllers.length,
            itemExtent: 50,
            mediaQueryData: MediaQuery.of(context),
            itemBuilder: (BuildContext context, int index) => EditableText(
              key: ValueKey<int>(index),
              controller: textControllers[index],
              focusNode: focusNodes[index],
              style: const TextStyle(fontSize: 16, color: Color(0xFF000000)),
              cursorColor: const Color(0xFF000000),
              backgroundCursorColor: const Color(0xFF808080),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('Do not crash when replacing scroll position during the drag', (
    WidgetTester tester,
  ) async {
    // Regression test for https://github.com/flutter/flutter/issues/89681
    var showScrollbars = false;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.2,
              maxChildSize: 0.9,
              expand: false,
              builder: (BuildContext context, ScrollController scrollController) {
                showScrollbars = !showScrollbars;
                // Change the scroll behavior will trigger scroll position replace.
                final ScrollBehavior behavior = const ScrollBehavior().copyWith(
                  scrollbars: showScrollbars,
                );
                return ScrollConfiguration(
                  behavior: behavior,
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    controller: scrollController,
                    itemCount: 100,
                    itemBuilder: (_, int index) => SizedBox(
                      height: 100,
                      child: ColoredBox(color: getTestColor(index), child: Text('Item $index')),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.fling(find.text('Item 1'), const Offset(0, 200), 350);
    await tester.pumpAndSettle();

    // Go without throw.
  });

  testWidgets('Scrolls correct amount when maxChildSize < 1.0', (WidgetTester tester) async {
    const Key key = ValueKey<String>('container');
    await tester.pumpWidget(
      boilerplateWidget(
        null,
        maxChildSize: .6,
        initialChildSize: .25,
        itemExtent: 25.0,
        containerKey: key,
      ),
    );

    expect(tester.getRect(find.byKey(key)), const Rect.fromLTRB(0.0, 450.0, 800.0, 600.0));
    await tester.drag(find.text('Item 5'), const Offset(0, -125));
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byKey(key)), const Rect.fromLTRB(0.0, 325.0, 800.0, 600.0));
  });

  testWidgets('Scrolls correct amount when maxChildSize == 1.0', (WidgetTester tester) async {
    const Key key = ValueKey<String>('container');
    await tester.pumpWidget(
      boilerplateWidget(null, initialChildSize: .25, itemExtent: 25.0, containerKey: key),
    );

    expect(tester.getRect(find.byKey(key)), const Rect.fromLTRB(0.0, 450.0, 800.0, 600.0));
    await tester.drag(find.text('Item 5'), const Offset(0, -125));
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byKey(key)), const Rect.fromLTRB(0.0, 325.0, 800.0, 600.0));
  });

  testWidgets(
    'Invalid snap targets throw assertion errors.',
    experimentalLeakTesting: LeakTesting.settings
        .withIgnoredAll(), // leaking by design because of exception
    (WidgetTester tester) async {
      await tester.pumpWidget(boilerplateWidget(null, maxChildSize: .8, snapSizes: <double>[.9]));
      expect(tester.takeException(), isAssertionError);

      await tester.pumpWidget(boilerplateWidget(null, snapSizes: <double>[.1]));
      expect(tester.takeException(), isAssertionError);

      await tester.pumpWidget(boilerplateWidget(null, snapSizes: <double>[.6, .6, .9]));
      expect(tester.takeException(), isAssertionError);
    },
  );

  group('Scroll Physics', () {
    testWidgets('Can be dragged up without covering its container', (WidgetTester tester) async {
      var taps = 0;
      await tester.pumpWidget(boilerplateWidget(() => taps++));

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
      await tester.pumpWidget(boilerplateWidget(null));
      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 21'), findsOneWidget);
      expect(find.text('Item 36'), findsNothing);

      await tester.drag(find.text('Item 1'), const Offset(0, 325));
      await tester.pumpAndSettle();
      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 21'), findsNothing);
      expect(find.text('Item 36'), findsNothing);
    }, variant: TargetPlatformVariant.all());

    testWidgets('Can be dragged down when list is shorter than full height', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(boilerplateWidget(null, itemCount: 30, initialChildSize: .25));

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

    testWidgets(
      'Can be dragged up and cover its container and scroll in single motion, and then dragged back down',
      (WidgetTester tester) async {
        var taps = 0;
        await tester.pumpWidget(boilerplateWidget(() => taps++));

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

        // Returning the list and shrinking the sheet need separate updates.
        final TestGesture gesture = await tester.startGesture(const Offset(20, 20));
        for (var i = 0; i < 20; i += 1) {
          await gesture.moveBy(const Offset(0, 325 / 20));
          await tester.pump();
        }
        await gesture.up();
        await tester.pumpAndSettle();
        await tester.tap(find.text('TapHere'));
        expect(taps, 2);
        expect(find.text('Item 1'), findsOneWidget);
        expect(find.text('Item 18'), findsOneWidget);
        expect(find.text('Item 36'), findsNothing);
      },
      variant: TargetPlatformVariant.all(),
    );

    testWidgets('Can be flung up gently', (WidgetTester tester) async {
      var taps = 0;
      await tester.pumpWidget(boilerplateWidget(() => taps++));

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
      var taps = 0;
      await tester.pumpWidget(boilerplateWidget(() => taps++));

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
      if (debugDefaultTargetPlatformOverride == TargetPlatform.macOS) {
        expect(find.text('Item 40'), findsOneWidget);
      } else {
        expect(find.text('Item 70'), findsOneWidget);
      }
    }, variant: TargetPlatformVariant.all());

    testWidgets('Can be flung down when not full height', (WidgetTester tester) async {
      await tester.pumpWidget(boilerplateWidget(null));
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
      var taps = 0;
      final controller = DraggableScrollableController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(boilerplateWidget(() => taps++, controller: controller));

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
      if (debugDefaultTargetPlatformOverride == TargetPlatform.macOS) {
        expect(find.text('Item 40'), findsOneWidget);
        await tester.fling(find.text('Item 40'), const Offset(0, 200), 2000);
      } else {
        expect(find.text('Item 70'), findsOneWidget);
        await tester.fling(find.text('Item 70'), const Offset(0, 200), 2000);
      }
      await tester.pumpAndSettle();
      // The remaining fling velocity shrinks the sheet once the list returns.
      expect(controller.size, lessThan(1));
      expect(find.text('TapHere'), findsOneWidget);
      await tester.tap(find.text('TapHere'));
      expect(taps, 2);
      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 70'), findsNothing);

      await tester.fling(find.text('Item 1'), const Offset(0, 200), 2000);
      await tester.pumpAndSettle();
      expect(find.text('TapHere'), findsOneWidget);
      await tester.tap(find.text('TapHere'));
      expect(taps, 3);
      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 21'), findsNothing);
      expect(find.text('Item 70'), findsNothing);
    }, variant: TargetPlatformVariant.all());

    testWidgets('Ballistic animation on fling can be interrupted', (WidgetTester tester) async {
      var taps = 0;
      await tester.pumpWidget(boilerplateWidget(() => taps++));

      expect(find.text('TapHere'), findsOneWidget);
      await tester.tap(find.text('TapHere'));
      expect(taps, 1);
      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 31'), findsNothing);
      expect(find.text('Item 70'), findsNothing);

      await tester.fling(find.text('Item 1'), const Offset(0, -200), 2000);
      // Don't pump and settle because we want to interrupt the ballistic scrolling animation.
      expect(find.text('TapHere'), findsOneWidget);
      await tester.tap(find.text('TapHere'), warnIfMissed: false);
      expect(taps, 2);
      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 31'), findsOneWidget);
      expect(find.text('Item 70'), findsNothing);

      // Use `dragFrom` here because calling `drag` on a list item without
      // first calling `pumpAndSettle` fails with a hit test error.
      await tester.dragFrom(const Offset(0, 200), const Offset(0, 200));
      await tester.pumpAndSettle();

      // Verify that the ballistic animation has canceled and the sheet has
      // returned to it's original position.
      await tester.tap(find.text('TapHere'));
      expect(taps, 3);
      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 31'), findsNothing);
      expect(find.text('Item 70'), findsNothing);
    }, variant: TargetPlatformVariant.all());

    testWidgets('Ballistic animation on fling should not leak Ticker', (WidgetTester tester) async {
      // Regression test for https://github.com/flutter/flutter/issues/101061
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: const MediaQueryData(),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: DraggableScrollableSheet(
                initialChildSize: 0.8,
                minChildSize: 0.2,
                maxChildSize: 0.9,
                expand: false,
                builder: (_, ScrollController scrollController) {
                  return ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    controller: scrollController,
                    itemCount: 100,
                    itemBuilder: (_, int index) => SizedBox(
                      height: 100,
                      child: ColoredBox(color: getTestColor(index), child: Text('Item $index')),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.flingFrom(tester.getCenter(find.text('Item 1')), const Offset(0, 50), 10000);

      // Pumps several times to let the DraggableScrollableSheet react to scroll position changes.
      const numberOfPumpsBeforeError = 22;
      for (var i = 0; i < numberOfPumpsBeforeError; i++) {
        await tester.pump(const Duration(milliseconds: 10));
      }

      // Dispose the DraggableScrollableSheet
      await tester.pumpWidget(const SizedBox.shrink());

      // When a Ticker leaks an exception is thrown
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('Does not snap away from initial child on build', (WidgetTester tester) async {
    const Key containerKey = ValueKey<String>('container');
    const Key stackKey = ValueKey<String>('stack');
    await tester.pumpWidget(
      boilerplateWidget(
        null,
        snap: true,
        initialChildSize: .7,
        containerKey: containerKey,
        stackKey: stackKey,
      ),
    );
    await tester.pumpAndSettle();
    final double screenHeight = tester.getSize(find.byKey(stackKey)).height;

    // The sheet should not have snapped.
    expect(
      tester.getSize(find.byKey(containerKey)).height / screenHeight,
      closeTo(.7, precisionErrorTolerance),
    );
  }, variant: TargetPlatformVariant.all());

  for (final useActuator in <bool>[false, true]) {
    testWidgets(
      'Does not snap away from initial child on ${useActuator ? 'actuator' : 'controller'}.reset()',
      (WidgetTester tester) async {
        const Key containerKey = ValueKey<String>('container');
        const Key stackKey = ValueKey<String>('stack');
        final controller = DraggableScrollableController();
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          boilerplateWidget(
            null,
            controller: controller,
            snap: true,
            containerKey: containerKey,
            stackKey: stackKey,
          ),
        );
        await tester.pumpAndSettle();
        final double screenHeight = tester.getSize(find.byKey(stackKey)).height;

        await tester.drag(find.text('Item 1'), Offset(0, -.4 * screenHeight));
        await tester.pumpAndSettle();
        expect(
          tester.getSize(find.byKey(containerKey)).height / screenHeight,
          closeTo(1.0, precisionErrorTolerance),
        );

        if (useActuator) {
          DraggableScrollableActuator.reset(tester.element(find.byKey(containerKey)));
        } else {
          controller.reset();
        }
        await tester.pumpAndSettle();

        // The sheet should have reset without snapping away from initial child.
        expect(
          tester.getSize(find.byKey(containerKey)).height / screenHeight,
          closeTo(.5, precisionErrorTolerance),
        );
      },
    );
  }

  for (final snapAnimationDuration in <Duration?>[null, const Duration(seconds: 2)]) {
    testWidgets('Zero velocity drag snaps to nearest snap target with '
        'snapAnimationDuration: $snapAnimationDuration', (WidgetTester tester) async {
      const Key stackKey = ValueKey<String>('stack');
      const Key containerKey = ValueKey<String>('container');
      await tester.pumpWidget(
        boilerplateWidget(
          null,
          snap: true,
          stackKey: stackKey,
          containerKey: containerKey,
          snapSizes: <double>[.25, .5, .75, 1.0],
          snapAnimationDuration: snapAnimationDuration,
        ),
      );
      await tester.pumpAndSettle();
      final double screenHeight = tester.getSize(find.byKey(stackKey)).height;

      // We are dragging up, but we'll snap down because we're closer to .75 than 1.
      await tester.drag(find.text('Item 1'), Offset(0, -.35 * screenHeight));
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byKey(containerKey)).height / screenHeight,
        closeTo(.75, precisionErrorTolerance),
      );

      // Drag up and snap up.
      await tester.drag(find.text('Item 1'), Offset(0, -.2 * screenHeight));
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byKey(containerKey)).height / screenHeight,
        closeTo(1.0, precisionErrorTolerance),
      );

      // Drag down and snap up.
      await tester.drag(find.text('Item 1'), Offset(0, .1 * screenHeight));
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byKey(containerKey)).height / screenHeight,
        closeTo(1.0, precisionErrorTolerance),
      );

      // Drag down and snap down.
      await tester.drag(find.text('Item 1'), Offset(0, .45 * screenHeight));
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byKey(containerKey)).height / screenHeight,
        closeTo(.5, precisionErrorTolerance),
      );

      // Fling up with negligible velocity and snap down.
      await tester.fling(find.text('Item 1'), Offset(0, .1 * screenHeight), 1);
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byKey(containerKey)).height / screenHeight,
        closeTo(.5, precisionErrorTolerance),
      );
    }, variant: TargetPlatformVariant.all());
  }

  for (final snapSizes in <List<double>?>[null, <double>[]]) {
    testWidgets('Setting snapSizes to $snapSizes resolves to min and max', (
      WidgetTester tester,
    ) async {
      const Key stackKey = ValueKey<String>('stack');
      const Key containerKey = ValueKey<String>('container');
      await tester.pumpWidget(
        boilerplateWidget(
          null,
          snap: true,
          stackKey: stackKey,
          containerKey: containerKey,
          snapSizes: snapSizes,
        ),
      );
      await tester.pumpAndSettle();
      final double screenHeight = tester.getSize(find.byKey(stackKey)).height;

      await tester.drag(find.text('Item 1'), Offset(0, -.4 * screenHeight));
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byKey(containerKey)).height / screenHeight,
        closeTo(1.0, precisionErrorTolerance),
      );

      await tester.drag(find.text('Item 1'), Offset(0, .7 * screenHeight));
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byKey(containerKey)).height / screenHeight,
        closeTo(.25, precisionErrorTolerance),
      );
    }, variant: TargetPlatformVariant.all());
  }

  testWidgets('Min and max are implicitly added to snapSizes', (WidgetTester tester) async {
    const Key stackKey = ValueKey<String>('stack');
    const Key containerKey = ValueKey<String>('container');
    await tester.pumpWidget(
      boilerplateWidget(
        null,
        snap: true,
        stackKey: stackKey,
        containerKey: containerKey,
        snapSizes: <double>[.5],
      ),
    );
    await tester.pumpAndSettle();
    final double screenHeight = tester.getSize(find.byKey(stackKey)).height;

    await tester.drag(find.text('Item 1'), Offset(0, -.4 * screenHeight));
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byKey(containerKey)).height / screenHeight,
      closeTo(1.0, precisionErrorTolerance),
    );

    await tester.drag(find.text('Item 1'), Offset(0, .7 * screenHeight));
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byKey(containerKey)).height / screenHeight,
      closeTo(.25, precisionErrorTolerance),
    );
  }, variant: TargetPlatformVariant.all());

  testWidgets('Changes to widget parameters are propagated', (WidgetTester tester) async {
    const Key stackKey = ValueKey<String>('stack');
    const Key containerKey = ValueKey<String>('container');
    await tester.pumpWidget(
      boilerplateWidget(null, stackKey: stackKey, containerKey: containerKey),
    );
    await tester.pumpAndSettle();
    final double screenHeight = tester.getSize(find.byKey(stackKey)).height;
    expect(
      tester.getSize(find.byKey(containerKey)).height / screenHeight,
      closeTo(.5, precisionErrorTolerance),
    );

    // Pump the same widget but with a new initial child size.
    await tester.pumpWidget(
      boilerplateWidget(null, stackKey: stackKey, containerKey: containerKey, initialChildSize: .6),
    );
    await tester.pumpAndSettle();

    // We jump to the new initial size because the sheet hasn't changed yet.
    expect(
      tester.getSize(find.byKey(containerKey)).height / screenHeight,
      closeTo(.6, precisionErrorTolerance),
    );

    // Pump the same widget but with a new max child size.
    await tester.pumpWidget(
      boilerplateWidget(
        null,
        stackKey: stackKey,
        containerKey: containerKey,
        initialChildSize: .6,
        maxChildSize: .9,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.getSize(find.byKey(containerKey)).height / screenHeight,
      closeTo(.6, precisionErrorTolerance),
    );

    await tester.drag(find.text('Item 1'), Offset(0, -.6 * screenHeight));
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byKey(containerKey)).height / screenHeight,
      closeTo(.9, precisionErrorTolerance),
    );

    // Pump the same widget but with a new max child size and initial size.
    await tester.pumpWidget(
      boilerplateWidget(
        null,
        stackKey: stackKey,
        containerKey: containerKey,
        maxChildSize: .8,
        initialChildSize: .7,
      ),
    );
    await tester.pumpAndSettle();

    // The max child size has been reduced, we should be rebuilt at the new
    // max of .8. We changed the initial size again, but the sheet has already
    // been changed so the new initial is ignored.
    expect(
      tester.getSize(find.byKey(containerKey)).height / screenHeight,
      closeTo(.8, precisionErrorTolerance),
    );

    // The upward drag preserves its remainder by scrolling the list. Return
    // to the start so that the next drag exercises the sheet's size changes.
    final ScrollPosition position = tester.state<ScrollableState>(find.byType(Scrollable)).position;
    expect(position.pixels, greaterThan(0));
    position.jumpTo(0);
    await tester.pumpAndSettle();
    await tester.drag(find.byKey(containerKey), Offset(0, .2 * screenHeight));

    // Pump the same widget but with snapping enabled.
    await tester.pumpWidget(
      boilerplateWidget(
        null,
        snap: true,
        stackKey: stackKey,
        containerKey: containerKey,
        maxChildSize: .8,
        snapSizes: <double>[.5],
      ),
    );
    await tester.pumpAndSettle();

    // Sheet snaps immediately on a change to snap.
    expect(
      tester.getSize(find.byKey(containerKey)).height / screenHeight,
      closeTo(.5, precisionErrorTolerance),
    );

    final snapSizes = <double>[.6];

    // Change the snap sizes.
    await tester.pumpWidget(
      boilerplateWidget(
        null,
        snap: true,
        stackKey: stackKey,
        containerKey: containerKey,
        maxChildSize: .8,
        snapSizes: snapSizes,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.getSize(find.byKey(containerKey)).height / screenHeight,
      closeTo(.6, precisionErrorTolerance),
    );
  }, variant: TargetPlatformVariant.all());

  testWidgets('Fling snaps in direction of momentum', (WidgetTester tester) async {
    const Key stackKey = ValueKey<String>('stack');
    const Key containerKey = ValueKey<String>('container');
    await tester.pumpWidget(
      boilerplateWidget(
        null,
        snap: true,
        stackKey: stackKey,
        containerKey: containerKey,
        snapSizes: <double>[.5, .75],
      ),
    );
    await tester.pumpAndSettle();
    final double screenHeight = tester.getSize(find.byKey(stackKey)).height;

    await tester.fling(find.text('Item 1'), Offset(0, -.1 * screenHeight), 1000);
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byKey(containerKey)).height / screenHeight,
      closeTo(.75, precisionErrorTolerance),
    );

    await tester.fling(find.text('Item 1'), Offset(0, .3 * screenHeight), 1000);
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byKey(containerKey)).height / screenHeight,
      closeTo(.25, precisionErrorTolerance),
    );
  }, variant: TargetPlatformVariant.all());

  testWidgets("Changing parameters with an un-listened controller doesn't throw", (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      boilerplateWidget(
        null,
        snap: true,
        // Will prevent the sheet's child from listening to the controller.
        ignoreController: true,
      ),
    );
    await tester.pumpAndSettle();
    await tester.pumpWidget(boilerplateWidget(null, snap: true));
    await tester.pumpAndSettle();
  }, variant: TargetPlatformVariant.all());

  testWidgets(
    'Transitioning between scrollable children sharing a scroll controller will not throw',
    (WidgetTester tester) async {
      var s = 0;
      await tester.pumpWidget(
        TestWidgetsApp(
          home: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return DraggableScrollableSheet(
                initialChildSize: 0.25,
                snap: true,
                snapSizes: const <double>[0.25, 0.5, 1.0],
                builder: (BuildContext context, ScrollController scrollController) {
                  return PrimaryScrollController(
                    controller: scrollController,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      child: s.isEven
                          ? ListView(
                              children: <Widget>[
                                TestButton(
                                  onPressed: () => setState(() => ++s),
                                  child: const Text('Switch to 2'),
                                ),
                                Container(height: 400, color: const Color(0xFF0000FF)),
                              ],
                            )
                          : SingleChildScrollView(
                              child: Column(
                                children: <Widget>[
                                  TestButton(
                                    onPressed: () => setState(() => ++s),
                                    child: const Text('Switch to 1'),
                                  ),
                                  Container(height: 400, color: const Color(0xFF0000FF)),
                                ],
                              ),
                            ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      );

      // Trigger the AnimatedSwitcher between ListViews
      await tester.tap(find.text('Switch to 2'));
      await tester.pump();
      // Completes without throwing
    },
  );

  testWidgets('ScrollNotification correctly dispatched when flung without covering its container', (
    WidgetTester tester,
  ) async {
    final notificationTypes = <Type>[];
    await tester.pumpWidget(
      boilerplateWidget(
        null,
        onScrollNotification: (ScrollNotification notification) {
          notificationTypes.add(notification.runtimeType);
          return false;
        },
      ),
    );

    await tester.fling(find.text('Item 1'), const Offset(0, -200), 200);
    await tester.pumpAndSettle();

    // TODO(itome): Make sure UserScrollNotification and ScrollUpdateNotification are called correctly.
    final types = <Type>[ScrollStartNotification, ScrollEndNotification];
    expect(notificationTypes, equals(types));
  });

  testWidgets('ScrollNotification correctly dispatched when flung with contents scroll', (
    WidgetTester tester,
  ) async {
    final notificationTypes = <Type>[];
    await tester.pumpWidget(
      boilerplateWidget(
        null,
        onScrollNotification: (ScrollNotification notification) {
          notificationTypes.add(notification.runtimeType);
          return false;
        },
      ),
    );

    await tester.flingFrom(const Offset(0, 325), const Offset(0, -325), 200);
    await tester.pumpAndSettle();

    final types = <Type>[
      ScrollStartNotification,
      UserScrollNotification,
      // The drag reaching maxChildSize also scrolls its remaining distance.
      ...List<Type>.filled(6, ScrollUpdateNotification),
      ScrollEndNotification,
      UserScrollNotification,
    ];
    expect(notificationTypes, types);
  });

  testWidgets(
    'Emits DraggableScrollableNotification with shouldCloseOnMinExtent set to non-default value',
    (WidgetTester tester) async {
      DraggableScrollableNotification? receivedNotification;
      await tester.pumpWidget(
        boilerplateWidget(
          null,
          shouldCloseOnMinExtent: false,
          onDraggableScrollableNotification: (DraggableScrollableNotification notification) {
            receivedNotification = notification;
            return false;
          },
        ),
      );

      await tester.flingFrom(const Offset(0, 325), const Offset(0, -325), 200);
      await tester.pumpAndSettle();
      expect(receivedNotification!.shouldCloseOnMinExtent, isFalse);
    },
  );

  testWidgets('Do not crash when remove the tree during animation.', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/89214
    await tester.pumpWidget(
      boilerplateWidget(
        null,
        onScrollNotification: (ScrollNotification notification) {
          return false;
        },
      ),
    );

    await tester.flingFrom(const Offset(0, 325), const Offset(0, 325), 200);

    // The animation is running.

    await tester.pumpWidget(const SizedBox.shrink());

    expect(tester.takeException(), isNull);
  });

  for (final shouldAnimate in <bool>[true, false]) {
    testWidgets('Can ${shouldAnimate ? 'animate' : 'jump'} to arbitrary positions', (
      WidgetTester tester,
    ) async {
      const Key stackKey = ValueKey<String>('stack');
      const Key containerKey = ValueKey<String>('container');
      final controller = DraggableScrollableController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        boilerplateWidget(
          null,
          controller: controller,
          stackKey: stackKey,
          containerKey: containerKey,
        ),
      );
      await tester.pumpAndSettle();
      final double screenHeight = tester.getSize(find.byKey(stackKey)).height;
      // Use a local helper to animate so we can share code across a jumpTo test
      // and an animateTo test.
      void goTo(double size) => shouldAnimate
          ? controller.animateTo(
              size,
              duration: const Duration(milliseconds: 200),
              curve: Curves.linear,
            )
          : controller.jumpTo(size);
      // If we're animating, pump will call four times, two of which are for the
      // animation duration.
      final expectedPumpCount = shouldAnimate ? 4 : 2;

      goTo(.6);
      expect(await tester.pumpAndSettle(), expectedPumpCount);
      expect(
        tester.getSize(find.byKey(containerKey)).height / screenHeight,
        closeTo(.6, precisionErrorTolerance),
      );
      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 20'), findsOneWidget);
      expect(find.text('Item 70'), findsNothing);

      goTo(.4);
      expect(await tester.pumpAndSettle(), expectedPumpCount);
      expect(
        tester.getSize(find.byKey(containerKey)).height / screenHeight,
        closeTo(.4, precisionErrorTolerance),
      );
      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 20'), findsNothing);
      expect(find.text('Item 70'), findsNothing);

      await tester.fling(find.text('Item 1'), Offset(0, -screenHeight), 100);
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byKey(containerKey)).height / screenHeight,
        closeTo(1, precisionErrorTolerance),
      );
      expect(find.text('Item 1'), findsNothing);
      expect(find.text('Item 20'), findsOneWidget);
      expect(find.text('Item 70'), findsNothing);

      // Programmatic control does not affect the inner scrollable's position.
      goTo(.8);
      expect(await tester.pumpAndSettle(), expectedPumpCount);
      expect(
        tester.getSize(find.byKey(containerKey)).height / screenHeight,
        closeTo(.8, precisionErrorTolerance),
      );
      expect(find.text('Item 1'), findsNothing);
      expect(find.text('Item 20'), findsOneWidget);
      expect(find.text('Item 70'), findsNothing);

      // Attempting to move to a size too big or too small instead moves to the
      // min or max child size.
      goTo(.5);
      await tester.pumpAndSettle();
      goTo(0);
      expect(await tester.pumpAndSettle(), expectedPumpCount);
      expect(
        tester.getSize(find.byKey(containerKey)).height / screenHeight,
        closeTo(.25, precisionErrorTolerance),
      );
    });
  }

  testWidgets('Can animateTo with a nonlinear curve', (WidgetTester tester) async {
    const Key stackKey = ValueKey<String>('stack');
    const Key containerKey = ValueKey<String>('container');
    final controller = DraggableScrollableController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      boilerplateWidget(
        null,
        controller: controller,
        stackKey: stackKey,
        containerKey: containerKey,
      ),
    );
    await tester.pumpAndSettle();
    final double screenHeight = tester.getSize(find.byKey(stackKey)).height;

    controller.animateTo(.6, curve: Curves.linear, duration: const Duration(milliseconds: 100));
    // We need to call one pump first to get the animation to start.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(
      tester.getSize(find.byKey(containerKey)).height / screenHeight,
      closeTo(.55, precisionErrorTolerance),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byKey(containerKey)).height / screenHeight,
      closeTo(.6, precisionErrorTolerance),
    );

    controller.animateTo(
      .7,
      curve: const Interval(.5, 1),
      duration: const Duration(milliseconds: 100),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    // The curve should result in the sheet not moving for the first 50 ms.
    expect(
      tester.getSize(find.byKey(containerKey)).height / screenHeight,
      closeTo(.6, precisionErrorTolerance),
    );
    await tester.pump(const Duration(milliseconds: 25));
    expect(
      tester.getSize(find.byKey(containerKey)).height / screenHeight,
      closeTo(.65, precisionErrorTolerance),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byKey(containerKey)).height / screenHeight,
      closeTo(.7, precisionErrorTolerance),
    );
  });

  testWidgets('Can animateTo with a Curves.easeInOutBack curve begin min-size', (
    WidgetTester tester,
  ) async {
    const Key stackKey = ValueKey<String>('stack');
    const Key containerKey = ValueKey<String>('container');
    final controller = DraggableScrollableController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      boilerplateWidget(
        null,
        initialChildSize: 0.25,
        controller: controller,
        stackKey: stackKey,
        containerKey: containerKey,
      ),
    );
    await tester.pumpAndSettle();
    final double screenHeight = tester.getSize(find.byKey(stackKey)).height;

    controller.animateTo(
      .6,
      curve: Curves.easeInOutBack,
      duration: const Duration(milliseconds: 500),
    );

    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byKey(containerKey)).height / screenHeight,
      closeTo(.6, precisionErrorTolerance),
    );
  });

  testWidgets('Can reuse a controller after the old controller is disposed', (
    WidgetTester tester,
  ) async {
    const Key stackKey = ValueKey<String>('stack');
    const Key containerKey = ValueKey<String>('container');
    final controller = DraggableScrollableController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      boilerplateWidget(
        null,
        controller: controller,
        stackKey: stackKey,
        containerKey: containerKey,
      ),
    );
    await tester.pumpAndSettle();

    // Pump a new sheet with the same controller. This will dispose of the old sheet first.
    await tester.pumpWidget(
      boilerplateWidget(
        null,
        controller: controller,
        stackKey: stackKey,
        containerKey: containerKey,
      ),
    );
    await tester.pumpAndSettle();
    final double screenHeight = tester.getSize(find.byKey(stackKey)).height;

    controller.jumpTo(.6);
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byKey(containerKey)).height / screenHeight,
      closeTo(.6, precisionErrorTolerance),
    );
  });

  testWidgets('animateTo interrupts other animations', (WidgetTester tester) async {
    const Key stackKey = ValueKey<String>('stack');
    const Key containerKey = ValueKey<String>('container');
    final controller = DraggableScrollableController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: boilerplateWidget(
          null,
          controller: controller,
          stackKey: stackKey,
          containerKey: containerKey,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final double screenHeight = tester.getSize(find.byKey(stackKey)).height;

    await tester.flingFrom(Offset(0, .5 * screenHeight), Offset(0, -.5 * screenHeight), 2000);
    // Wait until `flinFrom` finished dragging, but before the scrollable goes ballistic.
    await tester.pump(const Duration(seconds: 1));

    expect(
      tester.getSize(find.byKey(containerKey)).height / screenHeight,
      closeTo(1, precisionErrorTolerance),
    );
    expect(find.text('Item 1'), findsOneWidget);

    controller.animateTo(.9, duration: const Duration(milliseconds: 200), curve: Curves.linear);
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byKey(containerKey)).height / screenHeight,
      closeTo(.9, precisionErrorTolerance),
    );
    // The ballistic animation should have been canceled so item 1 should still be visible.
    expect(find.text('Item 1'), findsOneWidget);
  });

  testWidgets('Other animations interrupt animateTo', (WidgetTester tester) async {
    const Key stackKey = ValueKey<String>('stack');
    const Key containerKey = ValueKey<String>('container');
    final controller = DraggableScrollableController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: boilerplateWidget(
          null,
          controller: controller,
          stackKey: stackKey,
          containerKey: containerKey,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final double screenHeight = tester.getSize(find.byKey(stackKey)).height;

    controller.animateTo(1, duration: const Duration(milliseconds: 200), curve: Curves.linear);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      tester.getSize(find.byKey(containerKey)).height / screenHeight,
      closeTo(.75, precisionErrorTolerance),
    );

    // Interrupt animation and drag downward.
    await tester.drag(find.text('Item 1'), Offset(0, .1 * screenHeight));
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byKey(containerKey)).height / screenHeight,
      closeTo(.65, precisionErrorTolerance),
    );
  });

  testWidgets('animateTo can be interrupted by other animateTo or jumpTo', (
    WidgetTester tester,
  ) async {
    const Key stackKey = ValueKey<String>('stack');
    const Key containerKey = ValueKey<String>('container');
    final controller = DraggableScrollableController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: boilerplateWidget(
          null,
          controller: controller,
          stackKey: stackKey,
          containerKey: containerKey,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final double screenHeight = tester.getSize(find.byKey(stackKey)).height;

    controller.animateTo(1, duration: const Duration(milliseconds: 200), curve: Curves.linear);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      tester.getSize(find.byKey(containerKey)).height / screenHeight,
      closeTo(.75, precisionErrorTolerance),
    );

    // Interrupt animation with a new `animateTo`.
    controller.animateTo(.25, duration: const Duration(milliseconds: 200), curve: Curves.linear);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      tester.getSize(find.byKey(containerKey)).height / screenHeight,
      closeTo(.5, precisionErrorTolerance),
    );

    // Interrupt animation with a jump.
    controller.jumpTo(.6);
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byKey(containerKey)).height / screenHeight,
      closeTo(.6, precisionErrorTolerance),
    );
  });

  testWidgets('Can get size and pixels', (WidgetTester tester) async {
    const Key stackKey = ValueKey<String>('stack');
    const Key containerKey = ValueKey<String>('container');
    final controller = DraggableScrollableController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      boilerplateWidget(
        null,
        controller: controller,
        stackKey: stackKey,
        containerKey: containerKey,
      ),
    );
    await tester.pumpAndSettle();
    final double screenHeight = tester.getSize(find.byKey(stackKey)).height;

    expect(controller.sizeToPixels(.25), .25 * screenHeight);
    expect(controller.pixelsToSize(.25 * screenHeight), .25);

    controller.animateTo(.6, duration: const Duration(milliseconds: 200), curve: Curves.linear);
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byKey(containerKey)).height / screenHeight,
      closeTo(.6, precisionErrorTolerance),
    );
    expect(controller.size, closeTo(.6, precisionErrorTolerance));
    expect(controller.pixels, closeTo(.6 * screenHeight, precisionErrorTolerance));

    await tester.drag(find.text('Item 5'), Offset(0, .2 * screenHeight));
    expect(controller.size, closeTo(.4, precisionErrorTolerance));
    expect(controller.pixels, closeTo(.4 * screenHeight, precisionErrorTolerance));
  });

  testWidgets(
    'Cannot attach a controller to multiple sheets',
    experimentalLeakTesting: LeakTesting.settings
        .withIgnoredAll(), // leaking by design because of exception
    (WidgetTester tester) async {
      final controller = DraggableScrollableController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Stack(
            children: <Widget>[
              boilerplateWidget(null, controller: controller),
              boilerplateWidget(null, controller: controller),
            ],
          ),
        ),
        phase: EnginePhase.build,
      );
      expect(tester.takeException(), isAssertionError);
    },
  );

  testWidgets('Can listen for changes in sheet size', (WidgetTester tester) async {
    const Key stackKey = ValueKey<String>('stack');
    const Key containerKey = ValueKey<String>('container');
    final loggedSizes = <double>[];
    final controller = DraggableScrollableController();
    addTearDown(controller.dispose);
    controller.addListener(() {
      loggedSizes.add(controller.size);
    });
    await tester.pumpWidget(
      boilerplateWidget(
        null,
        controller: controller,
        stackKey: stackKey,
        containerKey: containerKey,
      ),
    );
    await tester.pumpAndSettle();
    final double screenHeight = tester.getSize(find.byKey(stackKey)).height;

    // The initial size shouldn't be logged because no change has occurred yet.
    expect(loggedSizes.isEmpty, true);

    await tester.drag(find.text('Item 1'), Offset(0, .1 * screenHeight), touchSlopY: 0);
    await tester.pumpAndSettle();
    expect(loggedSizes, <double>[.4].map((double v) => closeTo(v, precisionErrorTolerance)));
    loggedSizes.clear();

    await tester.timedDrag(
      find.text('Item 1'),
      Offset(0, -.1 * screenHeight),
      const Duration(seconds: 1),
      frequency: 2,
    );
    await tester.pumpAndSettle();
    expect(loggedSizes, <double>[.45, .5].map((double v) => closeTo(v, precisionErrorTolerance)));
    loggedSizes.clear();

    controller.jumpTo(.6);
    await tester.pumpAndSettle();
    expect(loggedSizes, <double>[.6].map((double v) => closeTo(v, precisionErrorTolerance)));
    loggedSizes.clear();

    controller.animateTo(1, duration: const Duration(milliseconds: 400), curve: Curves.linear);
    await tester.pumpAndSettle();
    expect(
      loggedSizes,
      <double>[.7, .8, .9, 1].map((double v) => closeTo(v, precisionErrorTolerance)),
    );
    loggedSizes.clear();

    DraggableScrollableActuator.reset(tester.element(find.byKey(containerKey)));
    await tester.pumpAndSettle();
    expect(loggedSizes, <double>[.5].map((double v) => closeTo(v, precisionErrorTolerance)));
    loggedSizes.clear();
  });

  testWidgets('Listener does not fire on parameter change and persists after change', (
    WidgetTester tester,
  ) async {
    const Key stackKey = ValueKey<String>('stack');
    const Key containerKey = ValueKey<String>('container');
    final loggedSizes = <double>[];
    final controller = DraggableScrollableController();
    addTearDown(controller.dispose);
    controller.addListener(() {
      loggedSizes.add(controller.size);
    });
    await tester.pumpWidget(
      boilerplateWidget(
        null,
        controller: controller,
        stackKey: stackKey,
        containerKey: containerKey,
      ),
    );
    await tester.pumpAndSettle();
    final double screenHeight = tester.getSize(find.byKey(stackKey)).height;

    expect(loggedSizes.isEmpty, true);

    await tester.drag(find.text('Item 1'), Offset(0, .1 * screenHeight), touchSlopY: 0);
    await tester.pumpAndSettle();
    expect(loggedSizes, <double>[.4].map((double v) => closeTo(v, precisionErrorTolerance)));
    loggedSizes.clear();

    // Update a parameter without forcing a change in the current size.
    await tester.pumpWidget(
      boilerplateWidget(
        null,
        minChildSize: .1,
        controller: controller,
        stackKey: stackKey,
        containerKey: containerKey,
      ),
    );
    expect(loggedSizes.isEmpty, true);

    await tester.drag(find.text('Item 1'), Offset(0, .1 * screenHeight), touchSlopY: 0);
    await tester.pumpAndSettle();
    expect(loggedSizes, <double>[.3].map((double v) => closeTo(v, precisionErrorTolerance)));
    loggedSizes.clear();
  });

  testWidgets('Listener fires if a parameter change forces a change in size', (
    WidgetTester tester,
  ) async {
    const Key stackKey = ValueKey<String>('stack');
    const Key containerKey = ValueKey<String>('container');
    final loggedSizes = <double>[];
    final controller = DraggableScrollableController();
    addTearDown(controller.dispose);
    controller.addListener(() {
      loggedSizes.add(controller.size);
    });
    await tester.pumpWidget(
      boilerplateWidget(
        null,
        controller: controller,
        stackKey: stackKey,
        containerKey: containerKey,
      ),
    );
    await tester.pumpAndSettle();
    final double screenHeight = tester.getSize(find.byKey(stackKey)).height;

    expect(loggedSizes.isEmpty, true);

    // Set a new `initialChildSize` which will trigger a size change because we
    // haven't moved away initial size yet.
    await tester.pumpWidget(
      boilerplateWidget(
        null,
        initialChildSize: .6,
        controller: controller,
        stackKey: stackKey,
        containerKey: containerKey,
      ),
    );
    expect(loggedSizes, <double>[.6].map((double v) => closeTo(v, precisionErrorTolerance)));
    loggedSizes.clear();

    // Move away from initial child size.
    await tester.drag(find.text('Item 1'), Offset(0, .3 * screenHeight), touchSlopY: 0);
    await tester.pumpAndSettle();
    expect(loggedSizes, <double>[.3].map((double v) => closeTo(v, precisionErrorTolerance)));
    loggedSizes.clear();

    // Set a `minChildSize` greater than the current size.
    await tester.pumpWidget(
      boilerplateWidget(
        null,
        minChildSize: .4,
        controller: controller,
        stackKey: stackKey,
        containerKey: containerKey,
      ),
    );
    expect(loggedSizes, <double>[.4].map((double v) => closeTo(v, precisionErrorTolerance)));
    loggedSizes.clear();
  });

  testWidgets('Invalid controller interactions throw assertion errors', (
    WidgetTester tester,
  ) async {
    final controller = DraggableScrollableController();
    addTearDown(controller.dispose);
    // Can't use a controller before attaching it.
    expect(() => controller.jumpTo(.1), throwsAssertionError);

    expect(() => controller.pixels, throwsAssertionError);
    expect(() => controller.size, throwsAssertionError);
    expect(() => controller.pixelsToSize(0), throwsAssertionError);
    expect(() => controller.sizeToPixels(0), throwsAssertionError);

    await tester.pumpWidget(boilerplateWidget(null, controller: controller));

    // Can't jump or animate to invalid sizes.
    expect(() => controller.jumpTo(-1), throwsAssertionError);
    expect(() => controller.jumpTo(1.1), throwsAssertionError);
    expect(
      () =>
          controller.animateTo(-1, duration: const Duration(milliseconds: 1), curve: Curves.linear),
      throwsAssertionError,
    );
    expect(
      () => controller.animateTo(
        1.1,
        duration: const Duration(milliseconds: 1),
        curve: Curves.linear,
      ),
      throwsAssertionError,
    );

    // Can't use animateTo with a zero duration.
    expect(
      () => controller.animateTo(.5, duration: Duration.zero, curve: Curves.linear),
      throwsAssertionError,
    );
  });

  testWidgets('DraggableScrollableController must be attached before using any of its parameters', (
    WidgetTester tester,
  ) async {
    final controller = DraggableScrollableController();
    addTearDown(controller.dispose);
    expect(controller.isAttached, false);
    expect(() => controller.size, throwsAssertionError);
    final Widget boilerplate = boilerplateWidget(null, minChildSize: 0.4, controller: controller);
    await tester.pumpWidget(boilerplate);
    expect(controller.isAttached, true);
    expect(controller.size, isNotNull);
  });

  testWidgets('DraggableScrollableController.animateTo after detach', (WidgetTester tester) async {
    final controller = DraggableScrollableController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(boilerplateWidget(() {}, controller: controller));

    controller.animateTo(0.0, curve: Curves.linear, duration: const Duration(milliseconds: 200));
    await tester.pump();

    // Dispose the DraggableScrollableSheet
    await tester.pumpWidget(const SizedBox.shrink());
    // Controller should be detached and no exception should be thrown
    expect(controller.isAttached, false);
    expect(tester.takeException(), isNull);
  });

  testWidgets('DraggableScrollableSheet should not reset programmatic drag on rebuild', (
    WidgetTester tester,
  ) async {
    // Regression test for https://github.com/flutter/flutter/issues/101114
    const Key stackKey = ValueKey<String>('stack');
    const Key containerKey = ValueKey<String>('container');
    final controller = DraggableScrollableController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      boilerplateWidget(
        null,
        controller: controller,
        stackKey: stackKey,
        containerKey: containerKey,
      ),
    );
    await tester.pumpAndSettle();
    final double screenHeight = tester.getSize(find.byKey(stackKey)).height;

    controller.jumpTo(.6);
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byKey(containerKey)).height / screenHeight,
      closeTo(.6, precisionErrorTolerance),
    );

    // Force an arbitrary rebuild by pushing a new widget.
    await tester.pumpWidget(
      boilerplateWidget(
        null,
        controller: controller,
        stackKey: stackKey,
        containerKey: containerKey,
      ),
    );
    // Sheet remains at .6.
    expect(
      tester.getSize(find.byKey(containerKey)).height / screenHeight,
      closeTo(.6, precisionErrorTolerance),
    );

    controller.reset();
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byKey(containerKey)).height / screenHeight,
      closeTo(.5, precisionErrorTolerance),
    );

    controller.animateTo(.6, curve: Curves.linear, duration: const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byKey(containerKey)).height / screenHeight,
      closeTo(.6, precisionErrorTolerance),
    );

    // Force an arbitrary rebuild by pushing a new widget.
    await tester.pumpWidget(
      boilerplateWidget(
        null,
        controller: controller,
        stackKey: stackKey,
        containerKey: containerKey,
      ),
    );
    // Sheet remains at .6.
    expect(
      tester.getSize(find.byKey(containerKey)).height / screenHeight,
      closeTo(.6, precisionErrorTolerance),
    );
  });

  testWidgets('DraggableScrollableSheet should respect NeverScrollableScrollPhysics', (
    WidgetTester tester,
  ) async {
    // Regression test for https://github.com/flutter/flutter/issues/121021
    final controller = DraggableScrollableController();
    addTearDown(controller.dispose);
    Widget buildFrame(ScrollPhysics? physics) {
      return TestWidgetsApp(
        home: DraggableScrollableSheet(
          controller: controller,
          initialChildSize: 0.25,
          builder: (BuildContext context, ScrollController scrollController) {
            return ListView(
              physics: physics,
              controller: scrollController,
              children: <Widget>[
                const Text('Drag me!'),
                Container(height: 10000.0, color: const Color(0xFF0000FF)),
              ],
            );
          },
        ),
      );
    }

    await tester.pumpWidget(buildFrame(const NeverScrollableScrollPhysics()));

    final double initPixels = controller.pixels;

    await tester.drag(find.text('Drag me!'), const Offset(0, -300));
    await tester.pumpAndSettle();

    //Should not allow user scrolling.
    expect(controller.pixels, initPixels);

    await tester.pumpWidget(buildFrame(null));

    await tester.drag(find.text('Drag me!'), const Offset(0, -300.0));
    await tester.pumpAndSettle();

    //Allow user scrolling.
    expect(controller.pixels, initPixels + 300.0);
  });

  testWidgets('DraggableScrollableSheet should not rebuild every frame while dragging', (
    WidgetTester tester,
  ) async {
    // Regression test for https://github.com/flutter/flutter/issues/67219
    var buildCount = 0;
    await tester.pumpWidget(
      TestWidgetsApp(
        home: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.25,
              snap: true,
              snapSizes: const <double>[0.25, 0.5, 1.0],
              builder: (BuildContext context, ScrollController scrollController) {
                buildCount++;
                return ListView(
                  controller: scrollController,
                  children: <Widget>[
                    const Text('Drag me!'),
                    TestButton(onPressed: () => setState(() {}), child: const Text('Rebuild')),
                    Container(height: 10000, color: const Color(0xFF0000FF)),
                  ],
                );
              },
            );
          },
        ),
      ),
    );

    expect(buildCount, 1);

    await tester.fling(find.text('Drag me!'), const Offset(0, -300), 300);
    await tester.pumpAndSettle();

    // No need to rebuild the scrollable sheet, as only position has changed.
    expect(buildCount, 1);

    await tester.tap(find.text('Rebuild'));
    await tester.pump();

    // DraggableScrollableSheet has rebuilt, so expect the builder to be called.
    expect(buildCount, 2);
  });

  testWidgets('DraggableScrollableSheet controller can be changed', (WidgetTester tester) async {
    final controller1 = DraggableScrollableController();
    addTearDown(controller1.dispose);
    final controller2 = DraggableScrollableController();
    addTearDown(controller2.dispose);
    final loggedSizes = <double>[];

    var controller = controller1;
    await tester.pumpWidget(
      TestWidgetsApp(
        home: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.25,
              snap: true,
              snapSizes: const <double>[0.25, 0.5, 1.0],
              controller: controller,
              builder: (BuildContext context, ScrollController scrollController) {
                return ListView(
                  controller: scrollController,
                  children: <Widget>[
                    TestButton(
                      onPressed: () => setState(() {
                        controller = controller2;
                      }),
                      child: const Text('Switch controller'),
                    ),
                    Container(height: 10000, color: const Color(0xFF0000FF)),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
    expect(controller1.isAttached, true);
    expect(controller2.isAttached, false);

    controller1.addListener(() {
      loggedSizes.add(controller1.size);
    });
    controller1.jumpTo(0.5);
    expect(loggedSizes, <double>[0.5].map((double v) => closeTo(v, precisionErrorTolerance)));
    loggedSizes.clear();

    await tester.tap(find.text('Switch controller'));
    await tester.pump();

    expect(controller1.isAttached, false);
    expect(controller2.isAttached, true);

    controller2.addListener(() {
      loggedSizes.add(controller2.size);
    });
    controller2.jumpTo(1.0);
    expect(loggedSizes, <double>[1.0].map((double v) => closeTo(v, precisionErrorTolerance)));
  });

  testWidgets('DraggableScrollableSheet controller can be changed while animating', (
    WidgetTester tester,
  ) async {
    final controller1 = DraggableScrollableController();
    addTearDown(controller1.dispose);
    final controller2 = DraggableScrollableController();
    addTearDown(controller2.dispose);

    var controller = controller1;
    await tester.pumpWidget(
      TestWidgetsApp(
        home: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.25,
              snap: true,
              snapSizes: const <double>[0.25, 0.5, 1.0],
              controller: controller,
              builder: (BuildContext context, ScrollController scrollController) {
                return ListView(
                  controller: scrollController,
                  children: <Widget>[
                    TestButton(
                      onPressed: () => setState(() {
                        controller = controller2;
                      }),
                      child: const Text('Switch controller'),
                    ),
                    Container(height: 10000, color: const Color(0xFF0000FF)),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
    expect(controller1.isAttached, true);
    expect(controller2.isAttached, false);

    controller1.animateTo(0.5, curve: Curves.linear, duration: const Duration(milliseconds: 200));
    await tester.pump();

    await tester.tap(find.text('Switch controller'));
    await tester.pump();

    expect(controller1.isAttached, false);
    expect(controller2.isAttached, true);

    controller2.animateTo(1.0, curve: Curves.linear, duration: const Duration(milliseconds: 200));
    await tester.pump();

    await tester.pumpWidget(const SizedBox.shrink());
    expect(controller1.isAttached, false);
    expect(controller2.isAttached, false);
  });

  testWidgets('$DraggableScrollableController dispatches creation in constructor.', (
    WidgetTester widgetTester,
  ) async {
    await expectLater(
      await memoryEvents(
        () async => DraggableScrollableController().dispose(),
        DraggableScrollableController,
      ),
      areCreateAndDispose,
    );
  });

  testWidgets('DraggableScrollableSheet respects shouldCloseOnMinExtent', (
    WidgetTester tester,
  ) async {
    final controller = DraggableScrollableController();
    DraggableScrollableNotification? receivedNotification;

    Future<void> pumpWidgetAndFling() async {
      await tester.pumpWidget(
        boilerplateWidget(
          null,
          controller: controller,
          shouldCloseOnMinExtent: false,
          onDraggableScrollableNotification: (DraggableScrollableNotification notification) {
            receivedNotification = notification;
            return false;
          },
        ),
      );

      await tester.flingFrom(const Offset(0, 325), const Offset(0, -325), 200);
      await tester.pumpAndSettle();
    }

    await pumpWidgetAndFling();
    expect(receivedNotification!.shouldCloseOnMinExtent, isFalse);

    receivedNotification = null;
    controller.jumpTo(0.5);

    // Construct the widget a second time, to ensure didUpdateWidget is called.
    await pumpWidgetAndFling();
    expect(receivedNotification!.shouldCloseOnMinExtent, isFalse);
    controller.dispose();
  });

  // Regression test for https://github.com/flutter/flutter/issues/140701
  testWidgets('DraggableScrollableSheet snaps exactly to minChildSize', (
    WidgetTester tester,
  ) async {
    double? lastExtent;

    await tester.pumpWidget(
      boilerplateWidget(
        null,
        snap: true,
        onDraggableScrollableNotification: (DraggableScrollableNotification notification) {
          lastExtent = notification.extent;
          return false;
        },
      ),
    );

    // One of the conditions for reproducing the round-off error.
    await tester.fling(find.text('Item 1'), const Offset(0, 100), 2000);
    await tester.pumpFrames(
      tester.widget(find.byType(Directionality)),
      const Duration(milliseconds: 500),
    );
    expect(lastExtent, .25);
  });

  testWidgets(
    'DraggableScrollableSheet with BouncingScrollPhysics snaps when bouncing over max extent',
    (WidgetTester tester) async {
      double? lastExtent;

      final controller = DraggableScrollableController();
      addTearDown(controller.dispose);

      final children = List<Widget>.generate(12, (int index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(color: const Color(0xFF00FF00), height: 100, child: Text('Item $index')),
        );
      });
      children.insert(0, Container(color: const Color(0xFF00FF00), height: 100));

      await tester.pumpWidget(
        TestWidgetsApp(
          home: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return DraggableScrollableSheet(
                initialChildSize: 0.25,
                snap: true,
                snapSizes: const <double>[0.25, 0.5, 1.0],
                controller: controller,
                builder: (BuildContext context, ScrollController scrollController) {
                  return NotificationListener<DraggableScrollableNotification>(
                    onNotification: (DraggableScrollableNotification notification) {
                      lastExtent = notification.extent;
                      return false;
                    },
                    child: ColoredBox(
                      color: const Color(0xFFABCDEF),
                      child: CustomScrollView(
                        physics: const BouncingScrollPhysics(),
                        controller: scrollController,
                        slivers: <Widget>[
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (_, int index) => children[index],
                              childCount: children.length,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();
      final double itemHeight = tester.getSize(find.text('Item 0')).height;

      controller.jumpTo(1.0);
      await tester.pumpAndSettle();

      await tester.fling(find.text('Item 0'), Offset(0, -itemHeight), 100);
      await tester.pumpFrames(
        tester.widget(find.byType(TestWidgetsApp)),
        const Duration(milliseconds: 500),
      );

      await tester.fling(find.text('Item 2'), Offset(0, itemHeight), 500);
      await tester.pumpFrames(
        tester.widget(find.byType(TestWidgetsApp)),
        const Duration(milliseconds: 500),
      );

      expect(lastExtent, 1.0);
    },
  );

  testWidgets('The sheet can expand after the keyboard reveals a text field', (
    WidgetTester tester,
  ) async {
    // Regression test for https://github.com/flutter/flutter/issues/94942.
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 600);
    addTearDown(tester.view.reset);
    final controller = DraggableScrollableController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(buildKeyboardSheet(controller: controller));
    final ScrollController scrollController = tester
        .widget<ListView>(find.byType(ListView))
        .controller!;
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<int>(4)));
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 200);
    await tester.pumpAndSettle();

    // Focusing the field retains the normal fractional sheet size and scrolls
    // the field into view. That offset must not prevent the next upward drag.
    expect(controller.size, 0.5);
    final double revealedOffset = scrollController.offset;
    expect(revealedOffset, greaterThan(0));
    await tester.drag(find.byType(ListView), const Offset(0, -60));
    await tester.pumpAndSettle();
    expect(controller.size, greaterThan(0.5));
    expect(scrollController.offset, closeTo(revealedOffset, precisionErrorTolerance));
  }, variant: TargetPlatformVariant.all());

  for (final keepFocus in <bool>[true, false]) {
    testWidgets('Hiding the keyboard keeps the sheet responsive with keepFocus=$keepFocus', (
      WidgetTester tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(400, 600);
      addTearDown(tester.view.reset);
      final controller = DraggableScrollableController();
      final focusNode = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(focusNode.dispose);
      await tester.pumpWidget(buildKeyboardSheet(controller: controller, focusNode: focusNode));
      final ScrollController scrollController = tester
          .widget<ListView>(find.byType(ListView))
          .controller!;
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<int>(4)));
      tester.view.viewInsets = const FakeViewPadding(bottom: 200);
      await tester.pumpAndSettle();
      expect(focusNode.hasFocus, isTrue);
      expect(scrollController.offset, greaterThan(0));

      await tester.drag(find.byType(ListView), const Offset(0, -60));
      await tester.pumpAndSettle();
      final double expandedSize = controller.size;
      final double revealedOffset = scrollController.offset;
      final double heightWithKeyboard = tester.getSize(find.byType(ListView)).height;
      expect(expandedSize, greaterThan(0.5));

      tester.testTextInput.hide();
      if (!keepFocus) {
        focusNode.unfocus();
      }
      // Keyboard metrics arrive over several frames on mobile platforms.
      // The fractional sheet size must stay fixed while its pixel height grows.
      for (final inset in <double>[160, 120, 80, 40, 0]) {
        tester.view.viewInsets = FakeViewPadding(bottom: inset);
        await tester.pump(const Duration(milliseconds: 16));
        await tester.pump();
        expect(controller.size, closeTo(expandedSize, precisionErrorTolerance));
        expect(
          tester.getSize(find.byType(ListView)).height,
          closeTo(expandedSize * (600 - inset), precisionErrorTolerance),
        );
        expect(scrollController.offset, closeTo(revealedOffset, precisionErrorTolerance));
      }
      await tester.pumpAndSettle();
      expect(focusNode.hasFocus, keepFocus);
      expect(tester.testTextInput.isVisible, isFalse);
      expect(tester.getSize(find.byType(ListView)).height, greaterThan(heightWithKeyboard));

      // A downward drag must first move the list back toward its beginning,
      // rather than immediately shrinking the partially expanded sheet.
      final position = scrollController.position as ScrollPositionWithSingleContext;
      final Drag drag = position.drag(DragStartDetails(), () {});
      drag.update(
        DragUpdateDetails(
          delta: Offset(0, revealedOffset / 2),
          primaryDelta: revealedOffset / 2,
          globalPosition: Offset.zero,
        ),
      );
      drag.end(DragEndDetails(primaryVelocity: 0));
      await tester.pumpAndSettle();
      expect(controller.size, closeTo(expandedSize, precisionErrorTolerance));
      expect(scrollController.offset, closeTo(revealedOffset / 2, precisionErrorTolerance));

      // Once the list reaches its beginning, both resizing directions still work.
      scrollController.jumpTo(0);
      await tester.pump();
      await tester.drag(find.byType(ListView), const Offset(0, 60));
      await tester.pumpAndSettle();
      expect(controller.size, lessThan(expandedSize));
      expect(scrollController.offset, 0);
      final double shrunkenSize = controller.size;
      await tester.drag(find.byType(ListView), const Offset(0, -60));
      await tester.pumpAndSettle();
      expect(controller.size, greaterThan(shrunkenSize));
      expect(scrollController.offset, 0);
    }, variant: TargetPlatformVariant.all());
  }

  testWidgets('Hiding the keyboard at the list end corrects its offset without getting stuck', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 600);
    addTearDown(tester.view.reset);
    final controller = DraggableScrollableController();
    final focusNode = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);
    await tester.pumpWidget(
      buildKeyboardSheet(controller: controller, focusNode: focusNode, focusIndex: 19),
    );
    final ScrollController scrollController = tester
        .widget<ListView>(find.byType(ListView))
        .controller!;
    await tester.pumpAndSettle();
    scrollController.jumpTo(scrollController.position.maxScrollExtent);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey<int>(19)));
    tester.view.viewInsets = const FakeViewPadding(bottom: 200);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -60));
    await tester.pumpAndSettle();
    final double expandedSize = controller.size;
    expect(expandedSize, greaterThan(0.5));

    tester.testTextInput.hide();
    for (final inset in <double>[160, 120, 80, 40, 0]) {
      tester.view.viewInsets = FakeViewPadding(bottom: inset);
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump();
      expect(controller.size, closeTo(expandedSize, precisionErrorTolerance));
    }
    await tester.pumpAndSettle();
    expect(focusNode.hasFocus, isTrue);
    expect(
      scrollController.offset,
      closeTo(scrollController.position.maxScrollExtent, precisionErrorTolerance),
    );
    final Rect viewport = tester.getRect(find.byType(ListView));
    final Rect lastField = tester.getRect(find.byKey(const ValueKey<int>(19)));
    expect(lastField.bottom, closeTo(viewport.bottom, precisionErrorTolerance));

    await tester.drag(find.byType(ListView), const Offset(0, 60));
    await tester.pumpAndSettle();
    expect(controller.size, closeTo(expandedSize, precisionErrorTolerance));
    expect(scrollController.offset, lessThan(scrollController.position.maxScrollExtent));
    await tester.drag(find.byType(ListView), const Offset(0, -60));
    await tester.pumpAndSettle();
    expect(controller.size, greaterThan(expandedSize));
    expect(scrollController.offset, lessThanOrEqualTo(scrollController.position.maxScrollExtent));
  }, variant: TargetPlatformVariant.all());

  testWidgets('The sheet can expand after ensureVisible scrolls its contents', (
    WidgetTester tester,
  ) async {
    final controller = DraggableScrollableController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      boilerplateWidget(
        null,
        itemExtent: 50,
        itemCount: 40,
        cacheExtent: 1000,
        controller: controller,
      ),
    );
    final ScrollController scrollController = tester
        .widget<ListView>(find.byType(ListView))
        .controller!;
    await Scrollable.ensureVisible(tester.element(find.text('Item 8', skipOffstage: false)));
    await tester.pumpAndSettle();
    expect(controller.size, 0.5);
    expect(scrollController.offset, 400);
    await tester.drag(find.byType(ListView), const Offset(0, -80));
    await tester.pumpAndSettle();
    expect(controller.size, greaterThan(0.5));
    expect(scrollController.offset, 400);
  });

  for (final animate in <bool>[false, true]) {
    testWidgets('An upward drag expands the sheet after a list ${animate ? 'animation' : 'jump'}', (
      WidgetTester tester,
    ) async {
      final controller = DraggableScrollableController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        boilerplateWidget(null, itemExtent: 50, itemCount: 40, controller: controller),
      );
      final ScrollController scrollController = tester
          .widget<ListView>(find.byType(ListView))
          .controller!;
      if (animate) {
        final Future<void> scrolling = scrollController.animateTo(
          110,
          duration: const Duration(milliseconds: 300),
          curve: Curves.linear,
        );
        await tester.pumpAndSettle();
        await scrolling;
      } else {
        scrollController.jumpTo(110);
        await tester.pumpAndSettle();
      }
      expect(controller.size, 0.5);
      expect(scrollController.offset, 110);
      await tester.drag(find.byType(ListView), const Offset(0, -80));
      await tester.pumpAndSettle();
      expect(controller.size, greaterThan(0.5));
      expect(scrollController.offset, 110);
    });
  }

  testWidgets('Downward drags return the list before shrinking the sheet', (
    WidgetTester tester,
  ) async {
    final controller = DraggableScrollableController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      boilerplateWidget(null, itemExtent: 50, itemCount: 40, controller: controller),
    );
    final ScrollController scrollController = tester
        .widget<ListView>(find.byType(ListView))
        .controller!;
    scrollController.jumpTo(110);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, 60));
    await tester.pumpAndSettle();
    expect(scrollController.offset, inExclusiveRange(0, 110));
    expect(controller.size, 0.5);
  });

  testWidgets('A fully expanded sheet scrolls the list on upward drags', (
    WidgetTester tester,
  ) async {
    final controller = DraggableScrollableController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      boilerplateWidget(
        null,
        itemExtent: 50,
        itemCount: 40,
        controller: controller,
        initialChildSize: 1,
      ),
    );
    final ScrollController scrollController = tester
        .widget<ListView>(find.byType(ListView))
        .controller!;
    scrollController.jumpTo(110);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -80));
    await tester.pumpAndSettle();
    expect(controller.size, 1);
    expect(scrollController.offset, greaterThan(110));
  });

  testWidgets('Reaching maxChildSize allows subsequent drags to scroll the list', (
    WidgetTester tester,
  ) async {
    final controller = DraggableScrollableController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      boilerplateWidget(
        null,
        itemExtent: 50,
        itemCount: 40,
        controller: controller,
        initialChildSize: 0.7,
        maxChildSize: 0.8,
      ),
    );
    final ScrollController scrollController = tester
        .widget<ListView>(find.byType(ListView))
        .controller!;
    scrollController.jumpTo(110);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -120));
    await tester.pumpAndSettle();
    expect(controller.size, 0.8);
    final double offset = scrollController.offset;
    await tester.drag(find.byType(ListView), const Offset(0, -60));
    await tester.pumpAndSettle();
    expect(controller.size, 0.8);
    expect(scrollController.offset, greaterThan(offset));
  });

  testWidgets('A sheet at its minimum can expand with an already scrolled list', (
    WidgetTester tester,
  ) async {
    final controller = DraggableScrollableController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      boilerplateWidget(
        null,
        itemExtent: 50,
        itemCount: 40,
        controller: controller,
        initialChildSize: 0.25,
      ),
    );
    final ScrollController scrollController = tester
        .widget<ListView>(find.byType(ListView))
        .controller!;
    scrollController.jumpTo(110);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -60));
    await tester.pumpAndSettle();
    expect(controller.size, greaterThan(0.25));
    expect(scrollController.offset, 110);
  });

  testWidgets('Upward drags still snap the sheet with an already scrolled list', (
    WidgetTester tester,
  ) async {
    final controller = DraggableScrollableController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      boilerplateWidget(null, itemExtent: 50, itemCount: 40, controller: controller, snap: true),
    );
    final ScrollController scrollController = tester
        .widget<ListView>(find.byType(ListView))
        .controller!;
    scrollController.jumpTo(110);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(controller.size, 1);
    expect(scrollController.offset, greaterThanOrEqualTo(110));
  });

  for (final scenario in <({String name, ScrollPhysics physics})>[
    (name: 'clamping', physics: const ClampingScrollPhysics()),
    (name: 'bouncing', physics: const BouncingScrollPhysics()),
    (
      name: 'bouncing fast',
      physics: const BouncingScrollPhysics(decelerationRate: ScrollDecelerationRate.fast),
    ),
  ]) {
    for (final snap in <bool>[false, true]) {
      testWidgets(
        'A downward list fling continues into the sheet with ${scenario.name} and snap=$snap',
        (WidgetTester tester) async {
          final controller = DraggableScrollableController();
          addTearDown(controller.dispose);
          var overscrolledWhileResizable = false;
          await tester.pumpWidget(
            boilerplateWidget(
              null,
              controller: controller,
              initialChildSize: 0.6,
              itemExtent: 50,
              physics: scenario.physics,
              snap: snap,
              snapSizes: const <double>[0.5, 0.75],
              onScrollNotification: (ScrollNotification notification) {
                if (controller.size > 0.25 &&
                    notification.metrics.pixels < notification.metrics.minScrollExtent) {
                  overscrolledWhileResizable = true;
                }
                return false;
              },
            ),
          );
          final ScrollController scrollController = tester
              .widget<ListView>(find.byType(ListView))
              .controller!;
          scrollController.jumpTo(80);
          final position = scrollController.position as ScrollPositionWithSingleContext;
          final Drag drag = position.drag(DragStartDetails(), () {});
          drag.update(
            DragUpdateDetails(
              delta: const Offset(0, -30),
              primaryDelta: -30,
              globalPosition: Offset.zero,
            ),
          );
          await tester.pump();
          drag.update(
            DragUpdateDetails(
              delta: const Offset(0, 10),
              primaryDelta: 10,
              globalPosition: Offset.zero,
            ),
          );
          final double sizeBeforeFling = controller.size;
          expect(sizeBeforeFling, inExclusiveRange(0.6, 0.75));
          expect(scrollController.offset, greaterThan(position.minScrollExtent));
          drag.end(
            DragEndDetails(
              primaryVelocity: 1500,
              velocity: const Velocity(pixelsPerSecond: Offset(0, 1500)),
            ),
          );
          await tester.pumpAndSettle();

          expect(controller.size, snap ? 0.5 : lessThan(sizeBeforeFling));
          expect(
            scrollController.offset,
            closeTo(position.minScrollExtent, precisionErrorTolerance),
          );
          expect(overscrolledWhileResizable, isFalse);
        },
      );
    }
  }

  for (final velocity in <double>[1, 1500]) {
    testWidgets('A stopped downward list fling still snaps with velocity $velocity', (
      WidgetTester tester,
    ) async {
      final controller = DraggableScrollableController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        boilerplateWidget(
          null,
          controller: controller,
          initialChildSize: 0.6,
          itemExtent: 50,
          physics: const ClampingScrollPhysics(),
          snap: true,
          snapSizes: const <double>[0.5, 0.75],
        ),
      );
      final ScrollController scrollController = tester
          .widget<ListView>(find.byType(ListView))
          .controller!;
      scrollController.jumpTo(80);
      final position = scrollController.position as ScrollPositionWithSingleContext;
      final Drag drag = position.drag(DragStartDetails(), () {});
      drag.update(
        DragUpdateDetails(
          delta: const Offset(0, -30),
          primaryDelta: -30,
          globalPosition: Offset.zero,
        ),
      );
      await tester.pump();
      drag.update(
        DragUpdateDetails(
          delta: const Offset(0, 10),
          primaryDelta: 10,
          globalPosition: Offset.zero,
        ),
      );
      drag.end(
        DragEndDetails(
          primaryVelocity: velocity,
          velocity: Velocity(pixelsPerSecond: Offset(0, velocity)),
        ),
      );
      await tester.pump();
      // The low velocity creates no list simulation. The other simulation has
      // completed by this frame, so its remaining velocity is also zero.
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      expect(controller.size, 0.75);
      expect(scrollController.offset, closeTo(velocity == 1 ? 70 : 0, precisionErrorTolerance));
    });
  }

  testWidgets('A downward fling returns to a negative minScrollExtent before shrinking', (
    WidgetTester tester,
  ) async {
    final controller = DraggableScrollableController();
    addTearDown(controller.dispose);
    const Key centerKey = ValueKey<String>('center');
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: DraggableScrollableSheet(
          controller: controller,
          builder: (BuildContext context, ScrollController scroll) => CustomScrollView(
            controller: scroll,
            physics: const ClampingScrollPhysics(),
            center: centerKey,
            slivers: const <Widget>[
              SliverToBoxAdapter(child: SizedBox(height: 200)),
              SliverToBoxAdapter(key: centerKey, child: SizedBox(height: 2000)),
            ],
          ),
        ),
      ),
    );
    final ScrollController scrollController = tester
        .widget<CustomScrollView>(find.byType(CustomScrollView))
        .controller!;
    final position = scrollController.position as ScrollPositionWithSingleContext;
    expect(position.minScrollExtent, -200);
    final Drag drag = position.drag(DragStartDetails(), () {});
    drag.update(
      DragUpdateDetails(
        delta: const Offset(0, -30),
        primaryDelta: -30,
        globalPosition: Offset.zero,
      ),
    );
    await tester.pump();
    drag.update(
      DragUpdateDetails(delta: const Offset(0, 10), primaryDelta: 10, globalPosition: Offset.zero),
    );
    final double sizeBeforeFling = controller.size;
    expect(position.pixels, -10);
    drag.end(
      DragEndDetails(
        primaryVelocity: 2000,
        velocity: const Velocity(pixelsPerSecond: Offset(0, 2000)),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    expect(controller.size, sizeBeforeFling);
    expect(position.pixels, inExclusiveRange(position.minScrollExtent, -10));
    await tester.pumpAndSettle();
    expect(controller.size, lessThan(sizeBeforeFling));
    expect(position.pixels, position.minScrollExtent);
  });

  testWidgets('A scroll notification can cancel the downward ballistic handoff', (
    WidgetTester tester,
  ) async {
    final controller = DraggableScrollableController();
    addTearDown(controller.dispose);
    var cancelAtStart = false;
    await tester.pumpWidget(
      boilerplateWidget(
        null,
        controller: controller,
        initialChildSize: 0.6,
        itemExtent: 50,
        physics: const ClampingScrollPhysics(),
        onScrollNotification: (ScrollNotification notification) {
          if (cancelAtStart &&
              notification is ScrollUpdateNotification &&
              notification.metrics.pixels == notification.metrics.minScrollExtent) {
            cancelAtStart = false;
            controller.jumpTo(0.7);
          }
          return false;
        },
      ),
    );
    final ScrollController scrollController = tester
        .widget<ListView>(find.byType(ListView))
        .controller!;
    scrollController.jumpTo(40);
    final position = scrollController.position as ScrollPositionWithSingleContext;
    final Drag drag = position.drag(DragStartDetails(), () {});
    drag.update(
      DragUpdateDetails(
        delta: const Offset(0, -30),
        primaryDelta: -30,
        globalPosition: Offset.zero,
      ),
    );
    await tester.pump();
    cancelAtStart = true;
    drag.end(
      DragEndDetails(
        primaryVelocity: 1500,
        velocity: const Velocity(pixelsPerSecond: Offset(0, 1500)),
      ),
    );
    await tester.pumpAndSettle();
    expect(cancelAtStart, isFalse);
    expect(controller.size, 0.7);
    expect(scrollController.offset, position.minScrollExtent);
  });

  testWidgets('NeverScrollableScrollPhysics prevents dragging an already scrolled sheet', (
    WidgetTester tester,
  ) async {
    final controller = DraggableScrollableController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      boilerplateWidget(
        null,
        itemExtent: 50,
        itemCount: 40,
        controller: controller,
        physics: const NeverScrollableScrollPhysics(),
      ),
    );
    final ScrollController scrollController = tester
        .widget<ListView>(find.byType(ListView))
        .controller!;
    scrollController.jumpTo(110);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -80));
    await tester.pumpAndSettle();
    expect(controller.size, 0.5);
    expect(scrollController.offset, 110);
  });

  testWidgets('A fixed-size sheet can still scroll an already moved list', (
    WidgetTester tester,
  ) async {
    final controller = DraggableScrollableController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      boilerplateWidget(
        null,
        itemExtent: 50,
        itemCount: 40,
        controller: controller,
        minChildSize: 0.5,
        maxChildSize: 0.5,
      ),
    );
    final ScrollController scrollController = tester
        .widget<ListView>(find.byType(ListView))
        .controller!;
    scrollController.jumpTo(110);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -80));
    await tester.pumpAndSettle();
    expect(controller.size, 0.5);
    expect(scrollController.offset, greaterThan(110));
  });

  for (final scenario in <({double firstDelta, double lastDelta, double size})>[
    (firstDelta: -58, lastDelta: 500, size: 0.1),
    (firstDelta: -38, lastDelta: -500, size: 0.6),
  ]) {
    testWidgets('User drags reach exact extent ${scenario.size}', (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(800, 600);
      addTearDown(tester.view.reset);
      final controller = DraggableScrollableController();
      addTearDown(controller.dispose);
      final notifications = <DraggableScrollableNotification>[];
      await tester.pumpWidget(
        boilerplateWidget(
          null,
          itemExtent: 50,
          itemCount: 40,
          controller: controller,
          minChildSize: 0.1,
          maxChildSize: 0.6,
          physics: const ClampingScrollPhysics(),
          onDraggableScrollableNotification: (DraggableScrollableNotification notification) {
            notifications.add(notification);
            return false;
          },
        ),
      );
      final ScrollController scrollController = tester
          .widget<ListView>(find.byType(ListView))
          .controller!;
      expect(controller.size, 0.5);
      final position = scrollController.position as ScrollPositionWithSingleContext;
      final Drag drag = position.drag(DragStartDetails(), () {});
      drag.update(
        DragUpdateDetails(
          delta: Offset(0, scenario.firstDelta),
          primaryDelta: scenario.firstDelta,
          globalPosition: Offset.zero,
        ),
      );
      await tester.pump();
      notifications.clear();
      drag.update(
        DragUpdateDetails(
          delta: Offset(0, scenario.lastDelta),
          primaryDelta: scenario.lastDelta,
          globalPosition: Offset.zero,
        ),
      );
      await tester.pump();

      expect(controller.size, scenario.size);
      expect(notifications, hasLength(1));
      final DraggableScrollableNotification notification = notifications.single;
      expect(notification.extent, scenario.size);
      expect(
        notification.extent,
        scenario.lastDelta > 0 ? notification.minExtent : notification.maxExtent,
      );
      drag.end(DragEndDetails(primaryVelocity: 0));
      await tester.pumpAndSettle();
    });
  }

  for (final scenario in <({String name, ScrollPhysics physics})>[
    (
      name: 'clamping',
      physics: const ClampingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
    ),
    (
      name: 'bouncing',
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
    ),
    (
      name: 'bouncing fast',
      physics: const BouncingScrollPhysics(
        decelerationRate: ScrollDecelerationRate.fast,
        parent: AlwaysScrollableScrollPhysics(),
      ),
    ),
  ]) {
    testWidgets('A short list can expand and shrink with ${scenario.name}', (
      WidgetTester tester,
    ) async {
      final controller = DraggableScrollableController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        boilerplateWidget(
          null,
          itemExtent: 50,
          controller: controller,
          itemCount: 1,
          physics: scenario.physics,
        ),
      );
      final ScrollController scrollController = tester
          .widget<ListView>(find.byType(ListView))
          .controller!;
      expect(scrollController.position.maxScrollExtent, 0);
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();
      expect(controller.size, 1);
      expect(scrollController.offset, closeTo(0, precisionErrorTolerance));

      await tester.drag(find.byType(ListView), const Offset(0, 500));
      await tester.pumpAndSettle();
      expect(controller.size, 0.25);
      expect(scrollController.offset, closeTo(0, precisionErrorTolerance));
    });
  }

  for (final ScrollDecelerationRate rate in ScrollDecelerationRate.values) {
    for (final atStart in <bool>[true, false]) {
      testWidgets('A drag can resume from ${atStart ? 'start' : 'end'} overscroll with $rate', (
        WidgetTester tester,
      ) async {
        final controller = DraggableScrollableController();
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          boilerplateWidget(
            null,
            itemExtent: 50,
            controller: controller,
            itemCount: 8,
            physics: BouncingScrollPhysics(decelerationRate: rate),
          ),
        );
        final ScrollController scrollController = tester
            .widget<ListView>(find.byType(ListView))
            .controller!;
        final position = scrollController.position as ScrollPositionWithSingleContext;
        final double boundary = atStart ? position.minScrollExtent : position.maxScrollExtent;
        scrollController.jumpTo(boundary + (atStart ? -40 : 40));
        final Drag drag = position.drag(DragStartDetails(), () {});
        expect(position.outOfRange, isTrue);
        final double delta = atStart ? -20 : 20;
        drag.update(
          DragUpdateDetails(
            delta: Offset(0, delta),
            primaryDelta: delta,
            globalPosition: Offset.zero,
          ),
        );
        await tester.pump();
        expect(controller.pixels, closeTo(atStart ? 320 : 300, precisionErrorTolerance));
        drag.end(DragEndDetails(primaryVelocity: 0));
        await tester.pumpAndSettle();
        expect(position.outOfRange, isFalse);
        expect(position.pixels, closeTo(atStart ? 0 : 100, precisionErrorTolerance));

        final Drag nextDrag = position.drag(DragStartDetails(), () {});
        final double nextDelta = atStart ? 40 : 200;
        nextDrag.update(
          DragUpdateDetails(
            delta: Offset(0, nextDelta),
            primaryDelta: nextDelta,
            globalPosition: Offset.zero,
          ),
        );
        await tester.pump();
        expect(controller.pixels, closeTo(atStart ? 280 : 300, precisionErrorTolerance));
        expect(position.pixels, closeTo(atStart ? 0 : -100, precisionErrorTolerance));
        nextDrag.end(DragEndDetails(primaryVelocity: 0));
        await tester.pumpAndSettle();
        expect(position.pixels, closeTo(0, precisionErrorTolerance));
      });
    }
  }

  for (final scenario in <({String name, ScrollPhysics physics, double? expectedOffset})>[
    (name: 'bouncing', physics: const BouncingScrollPhysics(), expectedOffset: null),
    (
      name: 'bouncing fast',
      physics: const BouncingScrollPhysics(decelerationRate: ScrollDecelerationRate.fast),
      expectedOffset: -60,
    ),
    (
      name: 'piecewise resistance',
      physics: const _OverscrollResistancePhysics(parent: BouncingScrollPhysics()),
      expectedOffset: -20,
    ),
  ]) {
    testWidgets(
      'A drag from end overscroll waits for another update to shrink with ${scenario.name}',
      (WidgetTester tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(800, 600);
        addTearDown(tester.view.reset);
        final controller = DraggableScrollableController();
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          boilerplateWidget(
            null,
            itemExtent: 50,
            controller: controller,
            itemCount: 8,
            physics: scenario.physics,
          ),
        );
        final ScrollController scrollController = tester
            .widget<ListView>(find.byType(ListView))
            .controller!;
        final position = scrollController.position as ScrollPositionWithSingleContext;
        scrollController.jumpTo(position.maxScrollExtent + 40);
        final Drag drag = position.drag(DragStartDetails(), () {});
        expect(position.outOfRange, isTrue);
        final double oldHeight = controller.pixels;
        expect(position.pixels, 140);
        expect(oldHeight, 300);
        const double delta = 200;
        drag.update(
          DragUpdateDetails(
            delta: const Offset(0, delta),
            primaryDelta: delta,
            globalPosition: Offset.zero,
          ),
        );
        await tester.pump();
        expect(position.pixels, lessThan(position.minScrollExtent));
        expect(controller.pixels, oldHeight);
        if (scenario.expectedOffset case final double expectedOffset) {
          expect(position.pixels, closeTo(expectedOffset, precisionErrorTolerance));
        }
        final double overscroll = position.pixels;
        drag.update(
          DragUpdateDetails(
            delta: const Offset(0, 20),
            primaryDelta: 20,
            globalPosition: Offset.zero,
          ),
        );
        await tester.pump();
        expect(controller.pixels, closeTo(oldHeight - 20, precisionErrorTolerance));
        expect(position.pixels, overscroll);
        drag.end(DragEndDetails(primaryVelocity: 0));
        await tester.pumpAndSettle();
        expect(position.pixels, closeTo(0, precisionErrorTolerance));
      },
    );
  }

  for (final physics in <ScrollPhysics>[
    const ClampingScrollPhysics(),
    const BouncingScrollPhysics(),
  ]) {
    for (final initialOffset in <double>[0, 110]) {
      testWidgets('Upward drag preserves its remainder from $initialOffset with $physics', (
        WidgetTester tester,
      ) async {
        final controller = DraggableScrollableController();
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          boilerplateWidget(
            null,
            itemExtent: 50,
            itemCount: 40,
            controller: controller,
            initialChildSize: 0.7,
            maxChildSize: 0.8,
            physics: physics,
          ),
        );
        final ScrollController scrollController = tester
            .widget<ListView>(find.byType(ListView))
            .controller!;
        scrollController.jumpTo(initialOffset);
        await tester.pumpAndSettle();
        final position = scrollController.position as ScrollPositionWithSingleContext;
        final Drag drag = position.drag(DragStartDetails(), () {});
        drag.update(
          DragUpdateDetails(
            delta: const Offset(0, -100),
            primaryDelta: -100,
            globalPosition: Offset.zero,
          ),
        );
        await tester.pump();
        expect(controller.size, 0.8);
        expect(scrollController.offset, closeTo(initialOffset + 40, precisionErrorTolerance));
        drag.end(DragEndDetails(primaryVelocity: 0));
        await tester.pumpAndSettle();
      });
    }

    for (final initialOffset in <double>[40, 100]) {
      testWidgets(
        'Downward list drags wait for another update to shrink from $initialOffset with $physics',
        (WidgetTester tester) async {
          final controller = DraggableScrollableController();
          addTearDown(controller.dispose);
          await tester.pumpWidget(
            boilerplateWidget(
              null,
              itemExtent: 50,
              itemCount: 40,
              controller: controller,
              physics: physics,
            ),
          );
          final ScrollController scrollController = tester
              .widget<ListView>(find.byType(ListView))
              .controller!;
          scrollController.jumpTo(initialOffset);
          await tester.pumpAndSettle();
          final double initialHeight = controller.pixels;
          final position = scrollController.position as ScrollPositionWithSingleContext;
          final Drag drag = position.drag(DragStartDetails(), () {});
          drag.update(
            DragUpdateDetails(
              delta: const Offset(0, 100),
              primaryDelta: 100,
              globalPosition: Offset.zero,
            ),
          );
          await tester.pump();
          final double expectedOffset = physics is BouncingScrollPhysics ? initialOffset - 100 : 0;
          expect(scrollController.offset, closeTo(expectedOffset, precisionErrorTolerance));
          expect(controller.pixels, initialHeight);
          drag.update(
            DragUpdateDetails(
              delta: const Offset(0, 20),
              primaryDelta: 20,
              globalPosition: Offset.zero,
            ),
          );
          await tester.pump();
          expect(controller.pixels, closeTo(initialHeight - 20, precisionErrorTolerance));
          expect(scrollController.offset, closeTo(expectedOffset, precisionErrorTolerance));
          drag.end(DragEndDetails(primaryVelocity: 0));
          await tester.pumpAndSettle();
          expect(scrollController.offset, closeTo(0, precisionErrorTolerance));
        },
      );
    }
  }

  for (final scenario in <({double factor, double initialOffset, double offset})>[
    (factor: 0, initialOffset: 40, offset: 40),
    (factor: 0.5, initialOffset: 110, offset: 60),
    (factor: 0.5, initialOffset: 50, offset: 0),
    (factor: 0.5, initialOffset: 40, offset: 0),
    (factor: 2, initialOffset: 110, offset: 0),
  ]) {
    testWidgets(
      'Downward drags respect ${scenario.factor}x physics from ${scenario.initialOffset}',
      (WidgetTester tester) async {
        final controller = DraggableScrollableController();
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          boilerplateWidget(
            null,
            itemExtent: 50,
            itemCount: 40,
            controller: controller,
            physics: _ScaledScrollPhysics(scenario.factor, parent: const ClampingScrollPhysics()),
          ),
        );
        final ScrollController scrollController = tester
            .widget<ListView>(find.byType(ListView))
            .controller!;
        scrollController.jumpTo(scenario.initialOffset);
        await tester.pumpAndSettle();
        final position = scrollController.position as ScrollPositionWithSingleContext;
        final Drag drag = position.drag(DragStartDetails(), () {});
        drag.update(
          DragUpdateDetails(
            delta: const Offset(0, 100),
            primaryDelta: 100,
            globalPosition: Offset.zero,
          ),
        );
        await tester.pump();
        expect(scrollController.offset, closeTo(scenario.offset, precisionErrorTolerance));
        expect(controller.pixels, closeTo(300, precisionErrorTolerance));
        drag.end(DragEndDetails(primaryVelocity: 0));
        await tester.pumpAndSettle();
      },
    );
  }

  for (final factor in <double>[0.5, 2]) {
    testWidgets('A large downward list update applies ${factor}x physics without resizing', (
      WidgetTester tester,
    ) async {
      final controller = DraggableScrollableController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        boilerplateWidget(
          null,
          itemExtent: 50,
          itemCount: 40,
          controller: controller,
          physics: _ScaledScrollPhysics(factor, parent: const BouncingScrollPhysics()),
        ),
      );
      final ScrollController scrollController = tester
          .widget<ListView>(find.byType(ListView))
          .controller!;
      scrollController.jumpTo(40);
      await tester.pumpAndSettle();
      final position = scrollController.position as ScrollPositionWithSingleContext;
      final Drag drag = position.drag(DragStartDetails(), () {});
      drag.update(
        DragUpdateDetails(
          delta: const Offset(0, 400),
          primaryDelta: 400,
          globalPosition: Offset.zero,
        ),
      );
      await tester.pump();

      // The entire update belongs to the list, even when it passes its start.
      expect(controller.size, 0.5);
      expect(scrollController.offset, closeTo(40 - 400 * factor, precisionErrorTolerance));
      drag.end(DragEndDetails(primaryVelocity: 0));
      await tester.pumpAndSettle();
      expect(controller.size, 0.5);
      expect(scrollController.offset, closeTo(0, precisionErrorTolerance));
    });
  }

  testWidgets('A resize notification can cancel the remaining upward drag', (
    WidgetTester tester,
  ) async {
    final controller = DraggableScrollableController();
    addTearDown(controller.dispose);
    var cancelDrag = true;
    await tester.pumpWidget(
      boilerplateWidget(
        null,
        itemExtent: 50,
        itemCount: 40,
        controller: controller,
        initialChildSize: 0.7,
        maxChildSize: 0.8,
        onDraggableScrollableNotification: (DraggableScrollableNotification notification) {
          if (cancelDrag && notification.extent == 0.8) {
            cancelDrag = false;
            controller.jumpTo(0.6);
          }
          return false;
        },
      ),
    );
    final ScrollController scrollController = tester
        .widget<ListView>(find.byType(ListView))
        .controller!;
    scrollController.jumpTo(110);
    await tester.pumpAndSettle();
    final position = scrollController.position as ScrollPositionWithSingleContext;
    final Drag drag = position.drag(DragStartDetails(), () {});
    drag.update(
      DragUpdateDetails(
        delta: const Offset(0, -100),
        primaryDelta: -100,
        globalPosition: Offset.zero,
      ),
    );
    await tester.pumpAndSettle();
    expect(cancelDrag, isFalse);
    expect(controller.size, 0.6);
    expect(scrollController.offset, 110);
  });

  for (final notificationType in <Type>[UserScrollNotification, ScrollUpdateNotification]) {
    testWidgets('A $notificationType can interrupt a downward list drag', (
      WidgetTester tester,
    ) async {
      final controller = DraggableScrollableController();
      addTearDown(controller.dispose);
      late final ScrollController scrollController;
      var cancelDrag = false;
      await tester.pumpWidget(
        boilerplateWidget(
          null,
          itemExtent: 50,
          itemCount: 40,
          controller: controller,
          physics: const ClampingScrollPhysics(),
          onScrollNotification: (ScrollNotification notification) {
            if (cancelDrag && notification.runtimeType == notificationType) {
              cancelDrag = false;
              scrollController.jumpTo(25);
            }
            return false;
          },
        ),
      );
      scrollController = tester.widget<ListView>(find.byType(ListView)).controller!;
      scrollController.jumpTo(110);
      await tester.pumpAndSettle();
      cancelDrag = true;
      final position = scrollController.position as ScrollPositionWithSingleContext;
      final Drag drag = position.drag(DragStartDetails(), () {});
      drag.update(
        DragUpdateDetails(
          delta: const Offset(0, 100),
          primaryDelta: 100,
          globalPosition: Offset.zero,
        ),
      );
      await tester.pumpAndSettle();
      expect(cancelDrag, isFalse);
      expect(controller.size, 0.5);
      expect(scrollController.offset, 25);
    });
  }

  testWidgets('Mouse wheel scrolling retains its normal list offsets', (WidgetTester tester) async {
    final controller = DraggableScrollableController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      boilerplateWidget(null, itemExtent: 50, itemCount: 40, controller: controller),
    );
    final ScrollController scrollController = tester
        .widget<ListView>(find.byType(ListView))
        .controller!;
    scrollController.jumpTo(110);
    await tester.pumpAndSettle();
    await tester.sendEventToBinding(
      PointerScrollEvent(
        position: tester.getCenter(find.byType(ListView)),
        scrollDelta: const Offset(0, 40),
      ),
    );
    await tester.pumpAndSettle();
    expect(controller.size, 0.5);
    expect(scrollController.offset, 150);
  });

  testWidgets('A list offset survives programmatic sheet resizing', (WidgetTester tester) async {
    final controller = DraggableScrollableController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      boilerplateWidget(
        null,
        itemExtent: 50,
        itemCount: 40,
        controller: controller,
        initialChildSize: 1,
      ),
    );
    final ScrollController scrollController = tester
        .widget<ListView>(find.byType(ListView))
        .controller!;
    scrollController.jumpTo(110);
    controller.jumpTo(0.5);
    await tester.pumpAndSettle();
    expect(controller.size, 0.5);
    expect(scrollController.offset, 110);
    final Future<void> resizing = controller.animateTo(
      0.7,
      duration: const Duration(milliseconds: 200),
      curve: Curves.linear,
    );
    await tester.pumpAndSettle();
    await resizing;
    expect(controller.size, 0.7);
    expect(scrollController.offset, 110);
  });

  testWidgets('A trackpad gesture can expand an already scrolled sheet', (
    WidgetTester tester,
  ) async {
    final controller = DraggableScrollableController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      boilerplateWidget(null, itemExtent: 50, itemCount: 40, controller: controller),
    );
    final ScrollController scrollController = tester
        .widget<ListView>(find.byType(ListView))
        .controller!;
    scrollController.jumpTo(110);
    await tester.pumpAndSettle();
    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.trackpad);
    final Offset center = tester.getCenter(find.byType(ListView));
    await gesture.panZoomStart(center);
    await tester.pump();
    await gesture.panZoomUpdate(center, pan: const Offset(0, -80));
    await tester.pump();
    await gesture.panZoomEnd();
    await tester.pumpAndSettle();
    expect(controller.size, greaterThan(0.5));
    expect(scrollController.offset, 110);
  });
}

class _ScaledScrollPhysics extends ScrollPhysics {
  const _ScaledScrollPhysics(this.factor, {super.parent});

  final double factor;

  @override
  _ScaledScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return _ScaledScrollPhysics(factor, parent: buildParent(ancestor));
  }

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    return super.applyPhysicsToUserOffset(position, offset) * factor;
  }
}

class _OverscrollResistancePhysics extends ScrollPhysics {
  const _OverscrollResistancePhysics({super.parent});

  @override
  _OverscrollResistancePhysics applyTo(ScrollPhysics? ancestor) {
    return _OverscrollResistancePhysics(parent: buildParent(ancestor));
  }

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    if (position.pixels > position.maxScrollExtent && offset > 0) {
      final double overscroll = position.pixels - position.maxScrollExtent;
      final double offsetToBoundary = overscroll * 2;
      if (offset <= offsetToBoundary) {
        return offset / 2;
      }
      return overscroll + offset - offsetToBoundary;
    }
    return super.applyPhysicsToUserOffset(position, offset);
  }
}
