// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import '../widgets/feedback_tester.dart';
import '../widgets/semantics_tester.dart';

const String tooltipText = 'TIP';

Finder _findTooltipContainer(String tooltipText) {
  return find.ancestor(of: find.text(tooltipText), matching: find.byType(Placeholder));
}

void main() {
  testWidgets('Does tooltip end up in the right place - center', (WidgetTester tester) async {
    final tooltipKey = GlobalKey<RawTooltipState>();
    late final OverlayEntry entry;
    addTearDown(
      () => entry
        ..remove()
        ..dispose(),
    );

    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0x00000000),
        builder: (BuildContext context, Widget? navigator) => Overlay(
          initialEntries: <OverlayEntry>[
            entry = OverlayEntry(
              builder: (BuildContext context) {
                return Stack(
                  children: <Widget>[
                    Positioned(
                      left: 300.0,
                      top: 0.0,
                      child: RawTooltip(
                        key: tooltipKey,
                        semanticsTooltip: tooltipText,
                        tooltipBuilder: (BuildContext context, Animation<double> animation) =>
                            const Placeholder(child: Text(tooltipText)),
                        child: const SizedBox.shrink(),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
    tooltipKey.currentState?.ensureTooltipVisible();
    await tester.pump(const Duration(seconds: 2)); // faded in, show timer started (and at 0.0)

    /********************* 800x600 screen
     *      o            * y=0
     *   +----+          * \- (5.0 padding in height)
     *   |    |          * |- 20 height
     *   +----+          * /- (5.0 padding in height)
     *                   *
     *********************/

    final RenderBox tip = tester.renderObject(_findTooltipContainer(tooltipText));
    final Offset tipInGlobal = tip.localToGlobal(tip.size.topCenter(Offset.zero));
    // The exact position of the left side depends on the font the test framework
    // happens to pick, so we don't test that.
    expect(tipInGlobal.dx, 300.0);
    expect(tipInGlobal.dy, 0.0);
  });

  testWidgets('Does tooltip end up in the right place - top left', (WidgetTester tester) async {
    final tooltipKey = GlobalKey<RawTooltipState>();
    late final OverlayEntry entry;
    addTearDown(
      () => entry
        ..remove()
        ..dispose(),
    );

    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0x00000000),
        builder: (BuildContext context, Widget? navigator) => Overlay(
          initialEntries: <OverlayEntry>[
            entry = OverlayEntry(
              builder: (BuildContext context) {
                return Stack(
                  children: <Widget>[
                    Positioned(
                      left: 0.0,
                      top: 0.0,
                      child: RawTooltip(
                        key: tooltipKey,
                        semanticsTooltip: tooltipText,
                        tooltipBuilder: (BuildContext context, Animation<double> animation) =>
                            const Placeholder(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 5.0),
                                child: SizedBox(height: 20, child: Text(tooltipText)),
                              ),
                            ),
                        child: const SizedBox.shrink(),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
    tooltipKey.currentState?.ensureTooltipVisible();
    await tester.pump(const Duration(seconds: 2)); // faded in, show timer started (and at 0.0)

    /********************* 800x600 screen
     *o                  * y=0
     *+----+             * \- (5.0 padding in height)
     *|    |             * |- 20 height
     *+----+             * /- (5.0 padding in height)
     *                   *
     *********************/

    final RenderBox tip = tester.renderObject(_findTooltipContainer(tooltipText));
    expect(tip.size.height, equals(30.0)); // 20.0 height + 5.0 padding * 2 (top, bottom)
    expect(tip.localToGlobal(tip.size.topLeft(Offset.zero)), equals(const Offset(10.0, 0.0)));
  });

  testWidgets('Does tooltip end up in the right place - center prefer above fits', (
    WidgetTester tester,
  ) async {
    final tooltipKey = GlobalKey<RawTooltipState>();
    late final OverlayEntry entry;
    addTearDown(
      () => entry
        ..remove()
        ..dispose(),
    );

    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0x00000000),
        builder: (BuildContext context, Widget? navigator) => Overlay(
          initialEntries: <OverlayEntry>[
            entry = OverlayEntry(
              builder: (BuildContext context) {
                return Stack(
                  children: <Widget>[
                    Positioned(
                      left: 400.0,
                      top: 300.0,
                      child: RawTooltip(
                        key: tooltipKey,
                        semanticsTooltip: tooltipText,
                        tooltipBuilder: (BuildContext context, Animation<double> animation) =>
                            const Placeholder(
                              child: SizedBox(height: 100, child: Text(tooltipText)),
                            ),
                        positionDelegate: (TooltipPositionContext context) => positionDependentBox(
                          size: context.overlaySize,
                          childSize: context.tooltipSize,
                          target: context.target,
                          preferBelow: false,
                        ),
                        child: const SizedBox.shrink(),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
    tooltipKey.currentState?.ensureTooltipVisible();
    await tester.pump(const Duration(seconds: 2)); // faded in, show timer started (and at 0.0)

    /********************* 800x600 screen
     *        ___        * }- 10.0 margin
     *       |___|       * }-100.0 height
     *         o         * y=300.0
     *                   *
     *                   *
     *                   *
     *********************/

    final RenderBox tip = tester.renderObject(_findTooltipContainer(tooltipText));
    expect(tip.size.height, equals(100.0));
    expect(tip.localToGlobal(tip.size.topLeft(Offset.zero)).dy, equals(200.0));
    expect(tip.localToGlobal(tip.size.bottomRight(Offset.zero)).dy, equals(300.0));
  });

  testWidgets('Does tooltip end up in the right place - center prefer above does not fit', (
    WidgetTester tester,
  ) async {
    final tooltipKey = GlobalKey<RawTooltipState>();
    late final OverlayEntry entry;
    addTearDown(
      () => entry
        ..remove()
        ..dispose(),
    );

    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0x00000000),
        builder: (BuildContext context, Widget? navigator) => Overlay(
          initialEntries: <OverlayEntry>[
            entry = OverlayEntry(
              builder: (BuildContext context) {
                return Stack(
                  children: <Widget>[
                    Positioned(
                      left: 400.0,
                      top: 299.0,
                      child: RawTooltip(
                        key: tooltipKey,
                        semanticsTooltip: tooltipText,
                        tooltipBuilder: (BuildContext context, Animation<double> animation) =>
                            const Placeholder(
                              child: SizedBox(height: 190, child: Text(tooltipText)),
                            ),
                        positionDelegate: (TooltipPositionContext context) => positionDependentBox(
                          size: context.overlaySize,
                          childSize: context.tooltipSize,
                          target: context.target,
                          preferBelow: false,
                        ),
                        child: const SizedBox.shrink(),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
    tooltipKey.currentState?.ensureTooltipVisible();
    await tester.pump(const Duration(seconds: 2)); // faded in, show timer started (and at 0.0)

    // we try to put it here but it doesn't fit:
    /********************* 800x600 screen
     *        ___        * }- 10.0 margin
     *       |___|       * }-190.0 height (starts at y=9.0)
     *         o         * y=299.0
     *                   *
     *                   *
     *                   *
     *********************/

    // so we put it here:
    /********************* 800x600 screen
     *                   *
     *                   *
     *         o         * y=299.0
     *       |___|       * }-190.0 height
     *                   * }- 10.0 margin
     *********************/

    final RenderBox tip = tester.renderObject(_findTooltipContainer(tooltipText));
    expect(tip.size.height, equals(190.0));
    expect(tip.localToGlobal(tip.size.topLeft(Offset.zero)).dy, equals(109.0));
    expect(tip.localToGlobal(tip.size.bottomRight(Offset.zero)).dy, equals(299.0));
  });

  testWidgets('Does tooltip end up in the right place - center prefer below fits', (
    WidgetTester tester,
  ) async {
    final tooltipKey = GlobalKey<RawTooltipState>();
    late final OverlayEntry entry;
    addTearDown(
      () => entry
        ..remove()
        ..dispose(),
    );

    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0x00000000),
        builder: (BuildContext context, Widget? navigator) => Overlay(
          initialEntries: <OverlayEntry>[
            entry = OverlayEntry(
              builder: (BuildContext context) {
                return Stack(
                  children: <Widget>[
                    Positioned(
                      left: 400.0,
                      top: 300.0,
                      child: RawTooltip(
                        key: tooltipKey,
                        semanticsTooltip: tooltipText,
                        tooltipBuilder: (BuildContext context, Animation<double> animation) =>
                            const Placeholder(
                              child: SizedBox(height: 190, child: Text(tooltipText)),
                            ),
                        child: const SizedBox.shrink(),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
    tooltipKey.currentState?.ensureTooltipVisible();
    await tester.pump(const Duration(seconds: 2)); // faded in, show timer started (and at 0.0)

    /********************* 800x600 screen
     *                   *
     *                   *
     *         o         * y=300.0
     *       |___|       * }-190.0 height
     *                   * }- 10.0 margin
     *********************/

    final RenderBox tip = tester.renderObject(_findTooltipContainer(tooltipText));
    expect(tip.size.height, equals(190.0));
    expect(tip.localToGlobal(tip.size.topLeft(Offset.zero)).dy, equals(300.0));
    expect(tip.localToGlobal(tip.size.bottomRight(Offset.zero)).dy, equals(490.0));
  });

  testWidgets('Does tooltip end up in the right place - way off to the right', (
    WidgetTester tester,
  ) async {
    final tooltipKey = GlobalKey<RawTooltipState>();
    late final OverlayEntry entry;
    addTearDown(
      () => entry
        ..remove()
        ..dispose(),
    );

    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0x00000000),
        builder: (BuildContext context, Widget? navigator) => Overlay(
          initialEntries: <OverlayEntry>[
            entry = OverlayEntry(
              builder: (BuildContext context) {
                return Stack(
                  children: <Widget>[
                    Positioned(
                      left: 1600.0,
                      top: 300.0,
                      child: RawTooltip(
                        key: tooltipKey,
                        semanticsTooltip: tooltipText,
                        tooltipBuilder: (BuildContext context, Animation<double> animation) =>
                            const Placeholder(
                              child: Padding(
                                padding: EdgeInsets.only(bottom: 10.0),
                                child: SizedBox(height: 10, child: Text(tooltipText)),
                              ),
                            ),
                        child: const SizedBox.shrink(),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
    tooltipKey.currentState?.ensureTooltipVisible();
    await tester.pump(const Duration(seconds: 2)); // faded in, show timer started (and at 0.0)

    /********************* 800x600 screen
     *                   *
     *                   *
     *                   * y=300.0;   target -->   o
     *             |___| * }-10.0 height
     *                   *
     *                   * }-10.0 margin
     *********************/

    final RenderBox tip = tester.renderObject(_findTooltipContainer(tooltipText));
    expect(tip.size.height, equals(20.0));
    expect(tip.localToGlobal(tip.size.topLeft(Offset.zero)).dy, equals(300.0));
    expect(tip.localToGlobal(tip.size.bottomRight(Offset.zero)).dx, equals(790.0));
    expect(tip.localToGlobal(tip.size.bottomRight(Offset.zero)).dy, equals(320.0));
  });

  testWidgets('Does tooltip end up in the right place - near the edge', (
    WidgetTester tester,
  ) async {
    final tooltipKey = GlobalKey<RawTooltipState>();
    late final OverlayEntry entry;
    addTearDown(
      () => entry
        ..remove()
        ..dispose(),
    );

    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0x00000000),
        builder: (BuildContext context, Widget? navigator) => Overlay(
          initialEntries: <OverlayEntry>[
            entry = OverlayEntry(
              builder: (BuildContext context) {
                return Stack(
                  children: <Widget>[
                    Positioned(
                      left: 780.0,
                      top: 300.0,
                      child: RawTooltip(
                        key: tooltipKey,
                        semanticsTooltip: tooltipText,
                        tooltipBuilder: (BuildContext context, Animation<double> animation) =>
                            const Placeholder(
                              child: Padding(
                                padding: EdgeInsets.only(bottom: 10.0),
                                child: SizedBox(height: 10, child: Text(tooltipText)),
                              ),
                            ),
                        child: const SizedBox.shrink(),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
    tooltipKey.currentState?.ensureTooltipVisible();
    await tester.pump(const Duration(seconds: 2)); // faded in, show timer started (and at 0.0)

    /********************* 800x600 screen
     *                   *
     *                   *
     *                o  * y=300.0
     *             |___| * }-10.0 height
     *                   *
     *                   * }-10.0 margin
     *********************/

    final RenderBox tip = tester.renderObject(_findTooltipContainer(tooltipText));
    expect(tip.size.height, equals(20.0));
    expect(tip.localToGlobal(tip.size.topLeft(Offset.zero)).dy, equals(300.0));
    expect(tip.localToGlobal(tip.size.bottomRight(Offset.zero)).dx, equals(790.0));
    expect(tip.localToGlobal(tip.size.bottomRight(Offset.zero)).dy, equals(320.0));
  });

  testWidgets('RawTooltip overlay respects ambient Directionality', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/40702.

    Widget buildApp(String text, TextDirection textDirection) {
      return WidgetsApp(
        color: const Color(0x00000000),
        pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) {
          return PageRouteBuilder<T>(
            pageBuilder:
                (
                  BuildContext context,
                  Animation<double> animation,
                  Animation<double> secondaryAnimation,
                ) => builder(context),
          );
        },
        home: Directionality(
          textDirection: textDirection,
          child: Center(
            child: RawTooltip(
              semanticsTooltip: text,
              tooltipBuilder: (BuildContext context, Animation<double> animation) =>
                  const Text(tooltipText),
              child: Container(width: 100.0, height: 100.0, color: const Color(0xff00ff00)),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildApp(tooltipText, TextDirection.rtl));
    await tester.longPress(find.byType(RawTooltip));
    expect(find.text(tooltipText), findsOneWidget);
    RenderParagraph tooltipRenderParagraph = tester.renderObject<RenderParagraph>(
      find.text(tooltipText),
    );
    expect(tooltipRenderParagraph.textDirection, TextDirection.rtl);

    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();
    await tester.pump();

    await tester.pumpWidget(buildApp(tooltipText, TextDirection.ltr));
    await tester.longPress(find.byType(RawTooltip));
    expect(find.text(tooltipText), findsOneWidget);
    tooltipRenderParagraph = tester.renderObject<RenderParagraph>(find.text(tooltipText));
    expect(tooltipRenderParagraph.textDirection, TextDirection.ltr);
  });

  testWidgets('RawTooltip stays after long press', (WidgetTester tester) async {
    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0x00000000),
        pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) {
          return PageRouteBuilder<T>(
            pageBuilder:
                (
                  BuildContext context,
                  Animation<double> animation,
                  Animation<double> secondaryAnimation,
                ) => builder(context),
          );
        },
        home: Center(
          child: RawTooltip(
            semanticsTooltip: tooltipText,
            tooltipBuilder: (BuildContext context, Animation<double> animation) =>
                const Text(tooltipText),
            positionDelegate: (TooltipPositionContext context) => positionDependentBox(
              size: context.overlaySize,
              childSize: context.tooltipSize,
              target: context.target,
              preferBelow: context.preferBelow,
              verticalOffset: 24.0,
            ),
            child: const SizedBox(height: 100, width: 100),
          ),
        ),
      ),
    );

    final Finder tooltip = find.byType(RawTooltip);
    TestGesture gesture = await tester.startGesture(tester.getCenter(tooltip));

    // long press reveals tooltip
    await tester.pump(kLongPressTimeout);
    await tester.pump(const Duration(milliseconds: 10));
    expect(find.text(tooltipText), findsOneWidget);
    await gesture.up();

    // tap (down, up) gesture hides tooltip, since its not
    // a long press
    await tester.tap(tooltip);
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text(tooltipText), findsNothing);

    // long press once more
    gesture = await tester.startGesture(tester.getCenter(tooltip));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(tooltipText), findsNothing);

    await tester.pump(kLongPressTimeout);
    await tester.pump(const Duration(milliseconds: 10));
    expect(find.text(tooltipText), findsOneWidget);

    // keep holding the long press, should still show tooltip
    await tester.pump(kLongPressTimeout);
    expect(find.text(tooltipText), findsOneWidget);
    await gesture.up();
  });

  testWidgets('RawTooltip dismiss countdown begins on long press release', (
    WidgetTester tester,
  ) async {
    // Specs: https://github.com/flutter/flutter/issues/4182
    const touchDelay = Duration(seconds: 1);
    const eternity = Duration(days: 9999);
    await setWidgetForTooltipMode(tester, TooltipTriggerMode.longPress, touchDelay: touchDelay);

    final Finder tooltip = find.byType(RawTooltip);
    final TestGesture gesture = await tester.startGesture(tester.getCenter(tooltip));

    await tester.pump(kLongPressTimeout);
    expect(find.text(tooltipText), findsOneWidget);
    // Keep holding to prevent the tooltip from dismissing.
    await tester.pump(eternity);
    expect(find.text(tooltipText), findsOneWidget);
    await tester.pump();
    expect(find.text(tooltipText), findsOneWidget);

    await gesture.up();
    await tester.pump();
    expect(find.text(tooltipText), findsOneWidget);

    await tester.pump(touchDelay);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text(tooltipText), findsNothing);
  });

  testWidgets('RawTooltip is dismissed after a long press and touchDelay expired', (
    WidgetTester tester,
  ) async {
    const touchDelay = Duration(seconds: 3);
    await setWidgetForTooltipMode(tester, TooltipTriggerMode.longPress, touchDelay: touchDelay);

    final Finder tooltip = find.byType(RawTooltip);
    final TestGesture gesture = await tester.startGesture(tester.getCenter(tooltip));

    // Long press reveals tooltip
    await tester.pump(kLongPressTimeout);
    await tester.pump(const Duration(milliseconds: 10));
    expect(find.text(tooltipText), findsOneWidget);
    await gesture.up();

    // Tooltip is dismissed after touchDelay expired
    await tester.pump(touchDelay);
    await tester.pump(const Duration(milliseconds: 10));
    expect(find.text(tooltipText), findsNothing);
  });

  testWidgets('RawTooltip is dismissed after a tap and touchDelay expired', (
    WidgetTester tester,
  ) async {
    const touchDelay = Duration(seconds: 3);
    await setWidgetForTooltipMode(tester, TooltipTriggerMode.tap, touchDelay: touchDelay);

    final Finder tooltip = find.byType(RawTooltip);
    expect(find.text(tooltipText), findsNothing);

    await _testGestureTap(tester, tooltip);
    expect(find.text(tooltipText), findsOneWidget);

    // Tooltip is dismissed after touchDelay expired
    await tester.pump(touchDelay);
    await tester.pump(const Duration(milliseconds: 10));
    expect(find.text(tooltipText), findsNothing);
  });

  testWidgets('RawTooltip is dismissed after tap to dismiss immediately', (
    WidgetTester tester,
  ) async {
    // This test relies on not ignoring pointer events.
    await setWidgetForTooltipMode(tester, TooltipTriggerMode.tap, ignorePointer: false);

    final Finder tooltip = find.byType(RawTooltip);
    expect(find.text(tooltipText), findsNothing);

    // Tap to trigger the tooltip.
    await _testGestureTap(tester, tooltip);
    expect(find.text(tooltipText), findsOneWidget);

    // Tap to dismiss the tooltip. Tooltip is dismissed immediately.
    await _testGestureTap(tester, find.text(tooltipText));
    await tester.pump(const Duration(milliseconds: 10));
    expect(find.text(tooltipText), findsNothing);
  });

  testWidgets('Tooltip is not dismissed after tap if enableTapToDismiss is false', (
    WidgetTester tester,
  ) async {
    // This test relies on not ignoring pointer events.
    await setWidgetForTooltipMode(
      tester,
      TooltipTriggerMode.tap,
      enableTapToDismiss: false,
      ignorePointer: false,
    );

    final Finder tooltip = find.byType(RawTooltip);
    expect(find.text(tooltipText), findsNothing);

    // Tap to trigger the tooltip.
    await _testGestureTap(tester, tooltip);
    expect(find.text(tooltipText), findsOneWidget);

    // Tap the tooltip. The tooltip is not dismissed.
    await _testGestureTap(tester, find.text(tooltipText));
    await tester.pump(const Duration(milliseconds: 10));
    expect(find.text(tooltipText), findsOneWidget);
  });

  testWidgets(
    'Tooltip is dismissed after a tap and touchDelay expired when competing with a GestureDetector',
    (WidgetTester tester) async {
      // Regression test for https://github.com/flutter/flutter/issues/98854
      const touchDelay = Duration(seconds: 3);
      await tester.pumpWidget(
        WidgetsApp(
          color: const Color(0x00000000),
          pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) {
            return PageRouteBuilder<T>(
              pageBuilder:
                  (
                    BuildContext context,
                    Animation<double> animation,
                    Animation<double> secondaryAnimation,
                  ) => builder(context),
            );
          },
          home: GestureDetector(
            onVerticalDragStart: (_) {
              /* Do nothing */
            },
            child: RawTooltip(
              semanticsTooltip: tooltipText,
              triggerMode: TooltipTriggerMode.tap,
              tooltipBuilder: (BuildContext context, Animation<double> animation) =>
                  const Text(tooltipText),
              touchDelay: touchDelay,
              child: const SizedBox(width: 100.0, height: 100.0),
            ),
          ),
        ),
      );
      final Finder tooltip = find.byType(RawTooltip);
      expect(find.text(tooltipText), findsNothing);

      await tester.tap(tooltip);
      // Wait for GestureArena disambiguation, delay is kPressTimeout to disambiguate
      // between onTap and onVerticalDragStart
      await tester.pump(kPressTimeout);
      expect(find.text(tooltipText), findsOneWidget);

      // Tooltip is dismissed after touchDelay expired
      await tester.pump(touchDelay);
      await tester.pump(const Duration(milliseconds: 10));
      expect(find.text(tooltipText), findsNothing);
    },
  );

  testWidgets('Dispatch the mouse events before tip overlay detached', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/96890
    const Duration hoverDelay = Duration.zero;
    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(() async {
      return gesture.removePointer();
    });
    await gesture.addPointer();
    await gesture.moveTo(const Offset(1.0, 1.0));
    await tester.pump();
    await gesture.moveTo(Offset.zero);

    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0x00000000),
        pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) {
          return PageRouteBuilder<T>(
            pageBuilder:
                (
                  BuildContext context,
                  Animation<double> animation,
                  Animation<double> secondaryAnimation,
                ) => builder(context),
          );
        },
        home: Center(
          child: RawTooltip(
            semanticsTooltip: tooltipText,
            tooltipBuilder: (BuildContext context, Animation<double> animation) =>
                const Text(tooltipText),
            child: const SizedBox(width: 100.0, height: 100.0),
          ),
        ),
      ),
    );

    // Trigger the tip overlay.
    final Finder tooltip = find.byType(RawTooltip);
    await gesture.moveTo(tester.getCenter(tooltip));
    await tester.pump();
    // Wait for it to appear.
    await tester.pump(hoverDelay);

    // Remove the `Tooltip` widget.
    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0x00000000),
        builder: (BuildContext context, Widget? navigator) =>
            const Center(child: SizedBox.shrink()),
      ),
    );

    // The tooltip should be removed, including the overlay child.
    expect(find.text(tooltipText), findsNothing);
    expect(find.byTooltip(tooltipText), findsNothing);
  });

  testWidgets('Calling ensureTooltipVisible on an unmounted RawTooltipState returns false', (
    WidgetTester tester,
  ) async {
    // Regression test for https://github.com/flutter/flutter/issues/95851
    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0x00000000),
        pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) {
          return PageRouteBuilder<T>(
            pageBuilder:
                (
                  BuildContext context,
                  Animation<double> animation,
                  Animation<double> secondaryAnimation,
                ) => builder(context),
          );
        },
        home: Center(
          child: RawTooltip(
            semanticsTooltip: tooltipText,
            tooltipBuilder: (BuildContext context, Animation<double> animation) =>
                const Text(tooltipText),
            child: const SizedBox(width: 100.0, height: 100.0),
          ),
        ),
      ),
    );

    final RawTooltipState tooltipState = tester.state(find.byType(RawTooltip));
    expect(tooltipState.ensureTooltipVisible(), true);

    // Remove the tooltip.
    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0x00000000),
        builder: (BuildContext context, Widget? navigator) =>
            const Center(child: SizedBox.shrink()),
      ),
    );

    expect(tooltipState.ensureTooltipVisible(), false);
  });

  testWidgets('Tooltip shows/hides when hovered', (WidgetTester tester) async {
    const Duration hoverDelay = Duration.zero;
    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(() async {
      return gesture.removePointer();
    });
    await gesture.addPointer();
    await gesture.moveTo(const Offset(1.0, 1.0));
    await tester.pump();
    await gesture.moveTo(Offset.zero);

    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0x00000000),
        pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) {
          return PageRouteBuilder<T>(
            pageBuilder:
                (
                  BuildContext context,
                  Animation<double> animation,
                  Animation<double> secondaryAnimation,
                ) => builder(context),
          );
        },
        home: Center(
          child: RawTooltip(
            semanticsTooltip: tooltipText,
            tooltipBuilder: (BuildContext context, Animation<double> animation) =>
                const Text(tooltipText),
            child: const SizedBox(width: 100.0, height: 100.0),
          ),
        ),
      ),
    );

    final Finder tooltip = find.byType(RawTooltip);
    await gesture.moveTo(Offset.zero);
    await tester.pump();
    await gesture.moveTo(tester.getCenter(tooltip));
    await tester.pump();
    // Wait for it to appear.
    await tester.pump(hoverDelay);
    expect(find.text(tooltipText), findsOneWidget);

    // Wait a looong time to make sure that it doesn't go away if the mouse is
    // still over the widget.
    await tester.pump(const Duration(days: 1));
    await tester.pumpAndSettle();
    expect(find.text(tooltipText), findsOneWidget);

    await gesture.moveTo(Offset.zero);
    await tester.pump();

    // Wait for it to disappear.
    await tester.pumpAndSettle();
    await gesture.removePointer();
    expect(find.text(tooltipText), findsNothing);
  });

  // Regression test for https://github.com/flutter/flutter/issues/141644.
  // This allows the user to quickly explore the UI via tooltips.
  testWidgets('Tooltip shows without delay when the mouse moves from another tooltip', (
    WidgetTester tester,
  ) async {
    const hoverDelay = Duration(milliseconds: 700);
    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(() async {
      return gesture.removePointer();
    });
    await gesture.addPointer();
    await gesture.moveTo(const Offset(1.0, 1.0));
    await tester.pump();
    await gesture.moveTo(Offset.zero);

    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0x00000000),
        pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) {
          return PageRouteBuilder<T>(
            pageBuilder:
                (
                  BuildContext context,
                  Animation<double> animation,
                  Animation<double> secondaryAnimation,
                ) => builder(context),
          );
        },
        home: Column(
          children: <Widget>[
            RawTooltip(
              semanticsTooltip: 'first tooltip',
              tooltipBuilder: (BuildContext context, Animation<double> animation) =>
                  const Text('first tooltip'),
              hoverDelay: hoverDelay,
              child: const SizedBox(width: 100.0, height: 100.0),
            ),
            RawTooltip(
              semanticsTooltip: 'last tooltip',
              tooltipBuilder: (BuildContext context, Animation<double> animation) =>
                  const Text('last tooltip'),
              hoverDelay: hoverDelay,
              child: const SizedBox(width: 100.0, height: 100.0),
            ),
          ],
        ),
      ),
    );

    await gesture.moveTo(Offset.zero);
    await tester.pump();
    await gesture.moveTo(tester.getCenter(find.byType(RawTooltip).first));
    await tester.pump();
    // Wait for the first tooltip to appear.
    await tester.pump(hoverDelay);
    expect(find.text('first tooltip'), findsOneWidget);
    expect(find.text('last tooltip'), findsNothing);

    // Move to the second tooltip and expect it to show up immediately.
    await gesture.moveTo(tester.getCenter(find.byType(RawTooltip).last));
    await tester.pump();
    expect(find.text('first tooltip'), findsNothing);
    expect(find.text('last tooltip'), findsOneWidget);
  });

  // Regression test for https://github.com/flutter/flutter/issues/142045.
  testWidgets(
    'Tooltip shows/hides when the mouse hovers, and then exits and re-enters in quick succession',
    (WidgetTester tester) async {
      const hoverDelay = Duration(milliseconds: 700);
      final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(() async {
        return gesture.removePointer();
      });
      await gesture.addPointer();
      await gesture.moveTo(const Offset(1.0, 1.0));

      await tester.pumpWidget(
        WidgetsApp(
          color: const Color(0x00000000),
          pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) {
            return PageRouteBuilder<T>(
              pageBuilder:
                  (
                    BuildContext context,
                    Animation<double> animation,
                    Animation<double> secondaryAnimation,
                  ) => builder(context),
            );
          },
          home: Center(
            child: RawTooltip(
              semanticsTooltip: tooltipText,
              tooltipBuilder: (BuildContext context, Animation<double> animation) =>
                  const Text(tooltipText),
              hoverDelay: hoverDelay,
              dismissDelay: hoverDelay,
              child: const SizedBox(width: 100.0, height: 100.0),
            ),
          ),
        ),
      );

      Future<void> mouseEnterAndWaitUntilVisible() async {
        await gesture.moveTo(tester.getCenter(find.byType(RawTooltip)));
        await tester.pump();
        await tester.pump(hoverDelay);
        await tester.pumpAndSettle();
        expect(find.text(tooltipText), findsOne);
      }

      Future<void> mouseExit() async {
        await gesture.moveTo(Offset.zero);
        await tester.pump();
      }

      Future<void> performSequence(Iterable<Future<void> Function()> actions) async {
        for (final action in actions) {
          await action();
        }
      }

      await performSequence(<Future<void> Function()>[mouseEnterAndWaitUntilVisible]);
      expect(find.text(tooltipText), findsOne);

      // Wait for reset.
      await mouseExit();
      await tester.pump(const Duration(hours: 1));
      await tester.pumpAndSettle();
      expect(find.text(tooltipText), findsNothing);

      await performSequence(<Future<void> Function()>[
        mouseEnterAndWaitUntilVisible,
        mouseExit,
        mouseEnterAndWaitUntilVisible,
      ]);
      expect(find.text(tooltipText), findsOne);

      // Wait for reset.
      await mouseExit();
      await tester.pump(const Duration(hours: 1));
      await tester.pumpAndSettle();
      expect(find.text(tooltipText), findsNothing);

      await performSequence(<Future<void> Function()>[
        mouseEnterAndWaitUntilVisible,
        mouseExit,
        mouseEnterAndWaitUntilVisible,
        mouseExit,
        mouseEnterAndWaitUntilVisible,
      ]);
      expect(find.text(tooltipText), findsOne);

      // Wait for reset.
      await mouseExit();
      await tester.pump(const Duration(hours: 1));
      await tester.pumpAndSettle();
      expect(find.text(tooltipText), findsNothing);
    },
  );

  testWidgets('Tooltip text is also hoverable', (WidgetTester tester) async {
    const Duration hoverDelay = Duration.zero;
    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(() async {
      return gesture.removePointer();
    });
    await gesture.addPointer();
    await gesture.moveTo(const Offset(1.0, 1.0));
    await tester.pump();
    await gesture.moveTo(Offset.zero);

    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0x00000000),
        pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) {
          return PageRouteBuilder<T>(
            pageBuilder:
                (
                  BuildContext context,
                  Animation<double> animation,
                  Animation<double> secondaryAnimation,
                ) => builder(context),
          );
        },
        home: Center(
          child: RawTooltip(
            tooltipBuilder: (BuildContext context, Animation<double> animation) =>
                const Text(tooltipText),
            semanticsTooltip: tooltipText,
            child: const Text('I am tool tip'),
          ),
        ),
      ),
    );

    final Finder tooltip = find.byType(RawTooltip);
    await gesture.moveTo(Offset.zero);
    await tester.pump();
    await gesture.moveTo(tester.getCenter(tooltip));
    await tester.pump();
    // Wait for it to appear.
    await tester.pump(hoverDelay);
    expect(find.text(tooltipText), findsOneWidget);

    // Wait a looong time to make sure that it doesn't go away if the mouse is
    // still over the widget.
    await tester.pump(const Duration(days: 1));
    await tester.pumpAndSettle();
    expect(find.text(tooltipText), findsOneWidget);

    // Hover to the tooltip text and verify the tooltip doesn't go away.
    await gesture.moveTo(tester.getTopLeft(find.text(tooltipText)));
    await tester.pump(const Duration(days: 1));
    await tester.pumpAndSettle();
    expect(find.text(tooltipText), findsOneWidget);

    await gesture.moveTo(Offset.zero);
    await tester.pump();

    // Wait for it to disappear.
    await tester.pumpAndSettle();
    await gesture.removePointer();
    expect(find.text(tooltipText), findsNothing);
  });

  testWidgets('Tooltip should not show more than one tooltip when hovered', (
    WidgetTester tester,
  ) async {
    const hoverDelay = Duration(milliseconds: 500);
    final innerKey = UniqueKey();
    final outerKey = UniqueKey();
    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0x00000000),
        pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) {
          return PageRouteBuilder<T>(
            pageBuilder:
                (
                  BuildContext context,
                  Animation<double> animation,
                  Animation<double> secondaryAnimation,
                ) => builder(context),
          );
        },
        home: Center(
          child: RawTooltip(
            semanticsTooltip: 'Outer',
            tooltipBuilder: (BuildContext context, Animation<double> animation) =>
                const Text('Outer'),
            child: Container(
              key: outerKey,
              width: 100,
              height: 100,
              alignment: Alignment.centerRight,
              child: RawTooltip(
                semanticsTooltip: 'Inner',
                tooltipBuilder: (BuildContext context, Animation<double> animation) =>
                    const Text('Inner'),
                child: SizedBox(key: innerKey, width: 25, height: 100),
              ),
            ),
          ),
        ),
      ),
    );

    TestGesture? gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(() async {
      gesture?.removePointer();
    });

    // Both the inner and outer containers have tooltips associated with them, but only
    // the currently hovered one should appear, even though the pointer is inside both.
    final Finder outer = find.byKey(outerKey);
    final Finder inner = find.byKey(innerKey);
    await gesture.moveTo(Offset.zero);
    await tester.pump();
    await gesture.moveTo(tester.getCenter(outer));
    await tester.pump();
    await gesture.moveTo(tester.getCenter(inner));
    await tester.pump();

    // Wait for it to appear.
    await tester.pump(hoverDelay);

    expect(find.text('Outer'), findsNothing);
    expect(find.text('Inner'), findsOneWidget);
    await gesture.moveTo(tester.getCenter(outer));
    await tester.pump();
    // Wait for it to switch.
    await tester.pumpAndSettle();
    expect(find.text('Outer'), findsOneWidget);
    expect(find.text('Inner'), findsNothing);

    await gesture.moveTo(Offset.zero);

    // Wait for all tooltips to disappear.
    await tester.pumpAndSettle();
    await gesture.removePointer();
    gesture = null;
    expect(find.text('Outer'), findsNothing);
    expect(find.text('Inner'), findsNothing);
  });

  testWidgets('Tooltip can be dismissed by escape key', (WidgetTester tester) async {
    const Duration hoverDelay = Duration.zero;
    TestGesture? gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(() async {
      if (gesture != null) {
        return gesture.removePointer();
      }
    });
    await gesture.addPointer();
    await gesture.moveTo(const Offset(1.0, 1.0));
    await tester.pump();
    await gesture.moveTo(Offset.zero);

    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0x00000000),
        pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) {
          return PageRouteBuilder<T>(
            pageBuilder:
                (
                  BuildContext context,
                  Animation<double> animation,
                  Animation<double> secondaryAnimation,
                ) => builder(context),
          );
        },
        home: Center(
          child: RawTooltip(
            semanticsTooltip: tooltipText,
            tooltipBuilder: (context, animation) => const ColoredBox(color: Color(0xff0000ff)),
            child: const Text('I am tool tip'),
          ),
        ),
      ),
    );

    final Finder tooltip = find.byType(RawTooltip);
    await gesture.moveTo(Offset.zero);
    await tester.pump();
    await gesture.moveTo(tester.getCenter(tooltip));
    await tester.pump();
    // Wait for it to appear.
    await tester.pump(hoverDelay);
    expect(find.byType(ColoredBox), findsOneWidget);

    // Try to dismiss the tooltip with the shortcut key.
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(ColoredBox), findsNothing);

    await gesture.moveTo(Offset.zero);
    await tester.pumpAndSettle();
    await gesture.removePointer();
    gesture = null;
  });

  testWidgets('Multiple Tooltips are dismissed by escape key', (WidgetTester tester) async {
    const Duration hoverDelay = Duration.zero;
    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0x00000000),
        pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) {
          return PageRouteBuilder<T>(
            pageBuilder:
                (
                  BuildContext context,
                  Animation<double> animation,
                  Animation<double> secondaryAnimation,
                ) => builder(context),
          );
        },
        home: Center(
          child: Column(
            children: <Widget>[
              RawTooltip(
                semanticsTooltip: 'tooltip1',
                touchDelay: const Duration(days: 1),
                tooltipBuilder: (context, animation) => const Text('message1'),
                child: const Text('tooltip1'),
              ),
              const Spacer(flex: 2),
              RawTooltip(
                semanticsTooltip: 'tooltip2',
                touchDelay: const Duration(days: 1),
                tooltipBuilder: (context, animation) => const Text('message2'),
                child: const Text('tooltip2'),
              ),
            ],
          ),
        ),
      ),
    );

    tester.state<RawTooltipState>(find.byTooltip('tooltip1')).ensureTooltipVisible();
    tester.state<RawTooltipState>(find.byTooltip('tooltip2')).ensureTooltipVisible();
    await tester.pump();
    await tester.pump(hoverDelay);
    // Make sure both messages are on the screen.
    expect(find.text('message1'), findsOneWidget);
    expect(find.text('message2'), findsOneWidget);

    // Try to dismiss the tooltip with the shortcut key
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('message1'), findsNothing);
    expect(find.text('message2'), findsNothing);
  });

  testWidgets('Tooltip does not attempt to show after unmount', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/54096.
    const hoverDelay = Duration(seconds: 1);
    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(() async {
      return gesture.removePointer();
    });
    await gesture.addPointer();
    await gesture.moveTo(const Offset(1.0, 1.0));
    await tester.pump();
    await gesture.moveTo(Offset.zero);

    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0x00000000),
        pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) {
          return PageRouteBuilder<T>(
            pageBuilder:
                (
                  BuildContext context,
                  Animation<double> animation,
                  Animation<double> secondaryAnimation,
                ) => builder(context),
          );
        },
        home: Center(
          child: RawTooltip(
            semanticsTooltip: tooltipText,
            tooltipBuilder: (BuildContext context, Animation<double> animation) =>
                const Text(tooltipText),
            hoverDelay: hoverDelay,
            child: const SizedBox(width: 100.0, height: 100.0),
          ),
        ),
      ),
    );

    final Finder tooltip = find.byType(RawTooltip);
    await gesture.moveTo(Offset.zero);
    await tester.pump();
    await gesture.moveTo(tester.getCenter(tooltip));
    await tester.pump();

    // Pump another random widget to unmount the Tooltip widget.
    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0x00000000),
        pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) {
          return PageRouteBuilder<T>(
            pageBuilder:
                (
                  BuildContext context,
                  Animation<double> animation,
                  Animation<double> secondaryAnimation,
                ) => builder(context),
          );
        },
        home: const Center(child: SizedBox()),
      ),
    );

    // If the issue regresses, an exception will be thrown while we are waiting.
    await tester.pump(hoverDelay);
  });

  testWidgets('Does tooltip contribute semantics', (WidgetTester tester) async {
    final semantics = SemanticsTester(tester);
    final tooltipKey = GlobalKey<RawTooltipState>();
    late final OverlayEntry entry;
    addTearDown(
      () => entry
        ..remove()
        ..dispose(),
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Overlay(
          initialEntries: <OverlayEntry>[
            entry = OverlayEntry(
              builder: (BuildContext context) {
                return Stack(
                  children: <Widget>[
                    Positioned(
                      left: 780.0,
                      top: 300.0,
                      child: RawTooltip(
                        key: tooltipKey,
                        semanticsTooltip: tooltipText,
                        tooltipBuilder: (BuildContext context, Animation<double> animation) =>
                            FadeTransition(opacity: animation, child: const Text(tooltipText)),
                        child: const SizedBox(width: 10.0, height: 10.0),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );

    final expected = TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics.rootChild(id: 1, tooltip: 'TIP', textDirection: TextDirection.ltr),
      ],
    );

    expect(semantics, hasSemantics(expected, ignoreTransform: true, ignoreRect: true));

    // This triggers a rebuild of the semantics because the tree changes.
    tooltipKey.currentState?.ensureTooltipVisible();

    await tester.pump(const Duration(seconds: 2)); // faded in, show timer started (and at 0.0)

    final expected1 = TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics.rootChild(
          id: 1,
          tooltip: 'TIP',
          textDirection: TextDirection.ltr,
          children: <TestSemantics>[TestSemantics(id: 2)],
        ),
      ],
    );
    expect(semantics, hasSemantics(expected1, ignoreTransform: true, ignoreRect: true));

    semantics.dispose();
  }, skip: kIsWeb); // [intended] the web traversal order by using ARIA-OWNS.

  testWidgets('Tooltip semantics does not merge into child', (WidgetTester tester) async {
    final semantics = SemanticsTester(tester);
    final tooltipKey = GlobalKey<RawTooltipState>();
    late final OverlayEntry entry;
    addTearDown(
      () => entry
        ..remove()
        ..dispose(),
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Overlay(
          initialEntries: <OverlayEntry>[
            entry = OverlayEntry(
              builder: (BuildContext context) {
                return ListView(
                  children: <Widget>[
                    const Text('before'),
                    RawTooltip(
                      key: tooltipKey,
                      tooltipBuilder: (BuildContext context, Animation<double> animation) =>
                          FadeTransition(opacity: animation, child: const Text('B')),
                      touchDelay: const Duration(seconds: 50),
                      semanticsTooltip: 'B',
                      child: const Text('child'),
                    ),
                    const Text('after'),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );

    tooltipKey.currentState?.ensureTooltipVisible();

    // Starts the animation.
    await tester.pump();
    // Make sure the fade in animation has started and the tooltip isn't transparent.
    await tester.pump(const Duration(seconds: 2));

    expect(
      semantics,
      hasSemantics(
        TestSemantics.root(
          children: <TestSemantics>[
            TestSemantics(
              id: 1,
              children: <TestSemantics>[
                TestSemantics(
                  id: 5,
                  flags: <SemanticsFlag>[SemanticsFlag.hasImplicitScrolling],
                  children: <TestSemantics>[
                    TestSemantics(id: 2, label: 'before'),
                    TestSemantics(
                      id: 3,
                      label: 'child',
                      tooltip: 'B',
                      children: <TestSemantics>[
                        TestSemantics(
                          id: 6,
                          children: <TestSemantics>[TestSemantics(id: 7, label: 'B')],
                        ),
                      ],
                    ),
                    TestSemantics(id: 4, label: 'after'),
                  ],
                ),
              ],
            ),
          ],
        ),
        ignoreId: true,
        ignoreRect: true,
        ignoreTransform: true,
      ),
    );

    semantics.dispose();
  }, skip: kIsWeb); // [intended] the web traversal order by using ARIA-OWNS.

  testWidgets('Haptic feedback', (WidgetTester tester) async {
    final feedback = FeedbackTester();
    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0x00000000),
        pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) {
          return PageRouteBuilder<T>(
            pageBuilder:
                (
                  BuildContext context,
                  Animation<double> animation,
                  Animation<double> secondaryAnimation,
                ) => builder(context),
          );
        },
        home: Center(
          child: RawTooltip(
            semanticsTooltip: 'Foo',
            tooltipBuilder: (BuildContext context, Animation<double> animation) =>
                const Text('Foo'),
            child: const SizedBox(width: 100.0, height: 100.0),
          ),
        ),
      ),
    );

    await tester.longPress(find.byType(RawTooltip));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(feedback.hapticCount, 1);

    feedback.dispose();
  });

  testWidgets('Semantics included', (WidgetTester tester) async {
    final semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0x00000000),
        pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) {
          return PageRouteBuilder<T>(
            pageBuilder:
                (
                  BuildContext context,
                  Animation<double> animation,
                  Animation<double> secondaryAnimation,
                ) => builder(context),
          );
        },
        home: Center(
          child: RawTooltip(
            semanticsTooltip: 'Foo',
            tooltipBuilder: (BuildContext context, Animation<double> animation) =>
                const Text('Foo'),
            child: const Text('Bar'),
          ),
        ),
      ),
    );

    expect(
      semantics,
      hasSemantics(
        TestSemantics.root(
          children: <TestSemantics>[
            TestSemantics.rootChild(
              id: 0,
              children: <TestSemantics>[
                TestSemantics(
                  id: 1,
                  children: <TestSemantics>[
                    TestSemantics(
                      id: 2,
                      tooltip: 'Foo',
                      label: 'Bar',
                      textDirection: TextDirection.ltr,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        ignoreRect: true,
        ignoreId: true,
        ignoreTransform: true,
      ),
    );

    semantics.dispose();
  });

  testWidgets('Semantics excluded', (WidgetTester tester) async {
    final semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0x00000000),
        pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) {
          return PageRouteBuilder<T>(
            pageBuilder:
                (
                  BuildContext context,
                  Animation<double> animation,
                  Animation<double> secondaryAnimation,
                ) => builder(context),
          );
        },
        home: Center(
          child: RawTooltip(
            semanticsTooltip: null,
            tooltipBuilder: (BuildContext context, Animation<double> animation) =>
                const Text('Foo'),
            child: const Text('Bar'),
          ),
        ),
      ),
    );

    expect(
      semantics,
      hasSemantics(
        TestSemantics.root(
          children: <TestSemantics>[
            TestSemantics.rootChild(
              children: <TestSemantics>[
                TestSemantics(
                  children: <TestSemantics>[
                    TestSemantics(label: 'Bar', textDirection: TextDirection.ltr),
                  ],
                ),
              ],
            ),
          ],
        ),
        ignoreRect: true,
        ignoreId: true,
        ignoreTransform: true,
      ),
    );

    semantics.dispose();
  });

  testWidgets('has semantic events', (WidgetTester tester) async {
    final semanticEvents = <dynamic>[];
    tester.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<dynamic>(
      SystemChannels.accessibility,
      (dynamic message) async {
        semanticEvents.add(message);
      },
    );
    final semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0x00000000),
        pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) {
          return PageRouteBuilder<T>(
            pageBuilder:
                (
                  BuildContext context,
                  Animation<double> animation,
                  Animation<double> secondaryAnimation,
                ) => builder(context),
          );
        },
        home: Center(
          child: RawTooltip(
            semanticsTooltip: 'Foo',
            tooltipBuilder: (BuildContext context, Animation<double> animation) =>
                const Text('Foo'),
            child: const SizedBox(width: 100.0, height: 100.0),
          ),
        ),
      ),
    );

    await tester.longPress(find.byType(RawTooltip));
    final RenderObject object = tester.firstRenderObject(find.byType(RawTooltip));

    expect(
      semanticEvents,
      unorderedEquals(<dynamic>[
        <String, dynamic>{
          'type': 'longPress',
          'nodeId': _findDebugSemantics(object).id,
          'data': <String, dynamic>{},
        },
        <String, dynamic>{
          'type': 'tooltip',
          'data': <String, dynamic>{'message': 'Foo'},
        },
      ]),
    );
    semantics.dispose();
    tester.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<dynamic>(
      SystemChannels.accessibility,
      null,
    );
  });
  testWidgets('default RawTooltip debugFillProperties', (WidgetTester tester) async {
    final builder = DiagnosticPropertiesBuilder();

    RawTooltip(
      semanticsTooltip: 'message',
      tooltipBuilder: (BuildContext context, Animation<double> animation) => const Text('message'),
      child: const SizedBox.shrink(),
    ).debugFillProperties(builder);

    final List<String> description = builder.properties
        .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
        .map((DiagnosticsNode node) => node.toString())
        .toList();

    expect(description, <String>[
      '"message"',
      'hover delay: 0:00:00.000000',
      'touch delay: 0:00:01.500000',
      'dismiss delay: 0:00:00.100000',
      'triggerMode: TooltipTriggerMode.longPress',
      'enableFeedback: true',
    ]);
  });

  testWidgets('RawTooltip implements debugFillProperties', (WidgetTester tester) async {
    final builder = DiagnosticPropertiesBuilder();

    // Not checking controller, inputFormatters, focusNode
    RawTooltip(
      key: const ValueKey<String>('foo'),
      tooltipBuilder: (BuildContext context, Animation<double> animation) => const Text('message'),
      semanticsTooltip: 'message',
      hoverDelay: const Duration(seconds: 1),
      touchDelay: const Duration(seconds: 2),
      triggerMode: TooltipTriggerMode.manual,
      child: const SizedBox.shrink(),
    ).debugFillProperties(builder);

    final List<String> description = builder.properties
        .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
        .map((DiagnosticsNode node) => node.toString())
        .toList();

    expect(description, <String>[
      '"message"',
      'hover delay: 0:00:01.000000',
      'touch delay: 0:00:02.000000',
      'dismiss delay: 0:00:00.100000',
      'triggerMode: TooltipTriggerMode.manual',
      'enableFeedback: true',
    ]);
  });

  testWidgets('Tooltip triggers on tap when trigger mode is tap', (WidgetTester tester) async {
    await setWidgetForTooltipMode(tester, TooltipTriggerMode.tap);

    final Finder tooltip = find.byType(RawTooltip);
    expect(find.text(tooltipText), findsNothing);

    await _testGestureTap(tester, tooltip);
    expect(find.text(tooltipText), findsOneWidget);
  });

  testWidgets('Tooltip triggers on long press when mode is long press', (
    WidgetTester tester,
  ) async {
    await setWidgetForTooltipMode(tester, TooltipTriggerMode.longPress);

    final Finder tooltip = find.byType(RawTooltip);
    expect(find.text(tooltipText), findsNothing);

    await _testGestureTap(tester, tooltip);
    expect(find.text(tooltipText), findsNothing);

    await _testGestureLongPress(tester, tooltip);
    expect(find.text(tooltipText), findsOneWidget);
  });

  testWidgets('Tooltip does not trigger on tap when trigger mode is longPress', (
    WidgetTester tester,
  ) async {
    await setWidgetForTooltipMode(tester, TooltipTriggerMode.longPress);

    final Finder tooltip = find.byType(RawTooltip);
    expect(find.text(tooltipText), findsNothing);

    await _testGestureTap(tester, tooltip);
    expect(find.text(tooltipText), findsNothing);
  });

  testWidgets('Tooltip does not trigger when trigger mode is manual', (WidgetTester tester) async {
    await setWidgetForTooltipMode(tester, TooltipTriggerMode.manual);

    final Finder tooltip = find.byType(RawTooltip);
    expect(find.text(tooltipText), findsNothing);

    await _testGestureTap(tester, tooltip);
    expect(find.text(tooltipText), findsNothing);

    await _testGestureLongPress(tester, tooltip);
    expect(find.text(tooltipText), findsNothing);
  });

  testWidgets('Tooltip onTriggered is called when Tooltip triggers', (WidgetTester tester) async {
    var onTriggeredCalled = false;
    void onTriggered() => onTriggeredCalled = true;

    await setWidgetForTooltipMode(tester, TooltipTriggerMode.longPress, onTriggered: onTriggered);
    Finder tooltip = find.byType(RawTooltip);
    await _testGestureLongPress(tester, tooltip);
    expect(onTriggeredCalled, true);

    onTriggeredCalled = false;
    await setWidgetForTooltipMode(tester, TooltipTriggerMode.tap, onTriggered: onTriggered);
    tooltip = find.byType(RawTooltip);
    await _testGestureTap(tester, tooltip);
    expect(onTriggeredCalled, true);
  });

  testWidgets('Tooltip onTriggered is not called when Tooltip is hovered', (
    WidgetTester tester,
  ) async {
    var onTriggeredCalled = false;
    void onTriggered() => onTriggeredCalled = true;

    const Duration hoverDelay = Duration.zero;
    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer();
    await gesture.moveTo(Offset.zero);

    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0x00000000),
        pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) {
          return PageRouteBuilder<T>(
            pageBuilder:
                (
                  BuildContext context,
                  Animation<double> animation,
                  Animation<double> secondaryAnimation,
                ) => builder(context),
          );
        },
        home: Center(
          child: RawTooltip(
            semanticsTooltip: tooltipText,
            tooltipBuilder: (BuildContext context, Animation<double> animation) =>
                const Text(tooltipText),
            onTriggered: onTriggered,
            child: const SizedBox(width: 100.0, height: 100.0),
          ),
        ),
      ),
    );

    final Finder tooltip = find.byType(RawTooltip);
    await gesture.moveTo(tester.getCenter(tooltip));
    await tester.pump();
    // Wait for it to appear.
    await tester.pump(hoverDelay);
    expect(onTriggeredCalled, false);
  });

  testWidgets('dismissAllToolTips dismisses hovered tooltips', (WidgetTester tester) async {
    const Duration hoverDelay = Duration.zero;
    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer();
    await gesture.moveTo(Offset.zero);

    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0x00000000),
        pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) {
          return PageRouteBuilder<T>(
            pageBuilder:
                (
                  BuildContext context,
                  Animation<double> animation,
                  Animation<double> secondaryAnimation,
                ) => builder(context),
          );
        },
        home: Center(
          child: RawTooltip(
            semanticsTooltip: tooltipText,
            tooltipBuilder: (BuildContext context, Animation<double> animation) =>
                const Text(tooltipText),
            positionDelegate: (TooltipPositionContext context) => positionDependentBox(
              size: context.overlaySize,
              childSize: context.tooltipSize,
              target: context.target,
              preferBelow: context.preferBelow,
              verticalOffset: 24.0,
            ),
            child: const SizedBox(width: 100.0, height: 100.0),
          ),
        ),
      ),
    );

    final Finder tooltip = find.byType(RawTooltip);
    await gesture.moveTo(tester.getCenter(tooltip));
    await tester.pump();
    // Wait for it to appear.
    await tester.pump(hoverDelay);
    expect(find.text(tooltipText), findsOneWidget);
    await tester.pump(const Duration(days: 1));
    await tester.pumpAndSettle();
    expect(find.text(tooltipText), findsOneWidget);

    expect(RawTooltip.dismissAllToolTips(), isTrue);
    await tester.pumpAndSettle();
    expect(find.text(tooltipText), findsNothing);
  });

  testWidgets('Hovered tooltips do not dismiss after touchDelay', (WidgetTester tester) async {
    const Duration hoverDelay = Duration.zero;
    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer();
    await gesture.moveTo(Offset.zero);

    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0x00000000),
        pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) {
          return PageRouteBuilder<T>(
            pageBuilder:
                (
                  BuildContext context,
                  Animation<double> animation,
                  Animation<double> secondaryAnimation,
                ) => builder(context),
          );
        },
        home: Center(
          child: RawTooltip(
            semanticsTooltip: tooltipText,
            tooltipBuilder: (BuildContext context, Animation<double> animation) =>
                const Text(tooltipText),
            child: const SizedBox(width: 100.0, height: 100.0),
          ),
        ),
      ),
    );

    final Finder tooltip = find.byType(RawTooltip);
    await gesture.moveTo(tester.getCenter(tooltip));
    await tester.pump();
    // Wait for it to appear.
    await tester.pump(hoverDelay);
    expect(find.text(tooltipText), findsOneWidget);
    await tester.pump(const Duration(days: 1));
    await tester.pumpAndSettle();
    expect(find.text(tooltipText), findsOneWidget);

    await tester.longPressAt(tester.getCenter(tooltip));
    await tester.pump(const Duration(days: 1));
    await tester.pumpAndSettle();
    // Still visible.
    expect(find.text(tooltipText), findsOneWidget);

    // Still visible.
    await tester.pump(const Duration(days: 1));
    await tester.pumpAndSettle();

    // The tooltip is no longer hovered and becomes invisible.
    await gesture.moveTo(Offset.zero);
    await tester.pump(const Duration(days: 1));
    await tester.pumpAndSettle();
    expect(find.text(tooltipText), findsNothing);
  });

  testWidgets('Hovered tooltips with touchDelay set do dismiss when hovering elsewhere', (
    WidgetTester tester,
  ) async {
    const touchDelay = Duration(seconds: 1);

    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0x00000000),
        pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) {
          return PageRouteBuilder<T>(
            pageBuilder:
                (
                  BuildContext context,
                  Animation<double> animation,
                  Animation<double> secondaryAnimation,
                ) => builder(context),
          );
        },
        home: Center(
          child: RawTooltip(
            semanticsTooltip: tooltipText,
            tooltipBuilder: (BuildContext context, Animation<double> animation) =>
                const Text(tooltipText),
            touchDelay: touchDelay,
            child: const SizedBox(width: 100.0, height: 100.0),
          ),
        ),
      ),
    );

    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(gesture.removePointer);
    await gesture.moveTo(tester.getCenter(find.byTooltip(tooltipText)));
    await tester.pump(const Duration(seconds: 1));
    expect(
      find.text(tooltipText),
      findsOneWidget,
      reason: 'Tooltip should be visible when hovered.',
    );

    await gesture.moveTo(Offset.zero);
    // Set a duration equal to the default exit
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
    expect(
      find.text(tooltipText),
      findsNothing,
      reason: 'Tooltip should not wait for touchDelay before it hides itself.',
    );
  });

  testWidgets('Hovered tooltips hide after stopping the hover', (WidgetTester tester) async {
    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0x00000000),
        pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) {
          return PageRouteBuilder<T>(
            pageBuilder:
                (
                  BuildContext context,
                  Animation<double> animation,
                  Animation<double> secondaryAnimation,
                ) => builder(context),
          );
        },
        home: Center(
          child: SizedBox.square(
            dimension: 10.0,
            child: RawTooltip(
              semanticsTooltip: tooltipText,
              tooltipBuilder: (BuildContext context, Animation<double> animation) =>
                  const Text(tooltipText),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );

    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(gesture.removePointer);
    await gesture.moveTo(tester.getCenter(find.byTooltip(tooltipText)));
    await tester.pump(const Duration(seconds: 1));
    expect(
      find.text(tooltipText),
      findsOneWidget,
      reason: 'Tooltip should be visible when hovered.',
    );

    await gesture.moveTo(Offset.zero);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
    expect(
      find.text(tooltipText),
      findsNothing,
      reason: 'Tooltip should be hidden when no longer hovered.',
    );
  });

  testWidgets('Hovered tooltips hide after stopping the hover and dismissDelay expires', (
    WidgetTester tester,
  ) async {
    const dismissDelay = Duration(seconds: 1);
    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0x00000000),
        pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) {
          return PageRouteBuilder<T>(
            pageBuilder:
                (
                  BuildContext context,
                  Animation<double> animation,
                  Animation<double> secondaryAnimation,
                ) => builder(context),
          );
        },
        home: Center(
          child: SizedBox.square(
            dimension: 10.0,
            child: RawTooltip(
              semanticsTooltip: tooltipText,
              tooltipBuilder: (BuildContext context, Animation<double> animation) =>
                  const Text(tooltipText),
              dismissDelay: dismissDelay,
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );

    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(gesture.removePointer);
    await gesture.moveTo(tester.getCenter(find.byTooltip(tooltipText)));
    await tester.pump(const Duration(seconds: 1));
    expect(
      find.text(tooltipText),
      findsOneWidget,
      reason: 'Tooltip should be visible when hovered.',
    );

    await gesture.moveTo(Offset.zero);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
    expect(
      find.text(tooltipText),
      findsOneWidget,
      reason: 'Tooltip should wait until dismissDelay expires before being hidden',
    );

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(
      find.text(tooltipText),
      findsNothing,
      reason: 'Tooltip should be hidden when no longer hovered.',
    );
  });

  testWidgets('Tooltip should not be shown with empty message (with child)', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0x00000000),
        pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) {
          return PageRouteBuilder<T>(
            pageBuilder:
                (
                  BuildContext context,
                  Animation<double> animation,
                  Animation<double> secondaryAnimation,
                ) => builder(context),
          );
        },
        home: RawTooltip(
          semanticsTooltip: tooltipText,
          tooltipBuilder: (BuildContext context, Animation<double> animation) =>
              const Text(tooltipText),
          child: const Text(tooltipText),
        ),
      ),
    );
    expect(find.text(tooltipText), findsOneWidget);
  });

  testWidgets('Tooltip should not be shown with empty message (without child)', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0x00000000),
        pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) {
          return PageRouteBuilder<T>(
            pageBuilder:
                (
                  BuildContext context,
                  Animation<double> animation,
                  Animation<double> secondaryAnimation,
                ) => builder(context),
          );
        },
        home: RawTooltip(
          semanticsTooltip: tooltipText,
          tooltipBuilder: (BuildContext context, Animation<double> animation) =>
              const Text(tooltipText),
          child: const SizedBox.shrink(),
        ),
      ),
    );
    expect(find.text(tooltipText), findsNothing);
    if (tooltipText.isEmpty) {
      expect(find.byType(SizedBox), findsOneWidget);
    }
  });

  testWidgets('Tooltip trigger mode ignores mouse events', (WidgetTester tester) async {
    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0x00000000),
        pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) {
          return PageRouteBuilder<T>(
            pageBuilder:
                (
                  BuildContext context,
                  Animation<double> animation,
                  Animation<double> secondaryAnimation,
                ) => builder(context),
          );
        },
        home: RawTooltip(
          semanticsTooltip: tooltipText,
          tooltipBuilder: (BuildContext context, Animation<double> animation) =>
              const Text(tooltipText),
          child: const SizedBox.expand(),
        ),
      ),
    );

    final TestGesture mouseGesture = await tester.startGesture(
      tester.getCenter(find.byTooltip(tooltipText)),
      kind: PointerDeviceKind.mouse,
    );
    await tester.pump(kLongPressTimeout + kPressTimeout);
    await mouseGesture.up();

    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text(tooltipText), findsNothing);

    final TestGesture touchGesture = await tester.startGesture(
      tester.getCenter(find.byTooltip(tooltipText)),
    );
    await tester.pump(kLongPressTimeout + kPressTimeout);
    await touchGesture.up();

    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text(tooltipText), findsOneWidget);
  });

  testWidgets('Tooltip does not block other mouse regions', (WidgetTester tester) async {
    var entered = false;

    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0x00000000),
        pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) {
          return PageRouteBuilder<T>(
            pageBuilder:
                (
                  BuildContext context,
                  Animation<double> animation,
                  Animation<double> secondaryAnimation,
                ) => builder(context),
          );
        },
        home: MouseRegion(
          onEnter: (PointerEnterEvent event) {
            entered = true;
          },
          child: RawTooltip(
            semanticsTooltip: tooltipText,
            tooltipBuilder: (BuildContext context, Animation<double> animation) =>
                const Text(tooltipText),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );

    expect(entered, isFalse);

    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer();
    await gesture.moveTo(tester.getCenter(find.byType(RawTooltip)));
    await gesture.removePointer();

    expect(entered, isTrue);
  });

  testWidgets('Does not rebuild on mouse connect/disconnect', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/117627
    var buildCount = 0;
    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0x00000000),
        pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) {
          return PageRouteBuilder<T>(
            pageBuilder:
                (
                  BuildContext context,
                  Animation<double> animation,
                  Animation<double> secondaryAnimation,
                ) => builder(context),
          );
        },
        home: RawTooltip(
          semanticsTooltip: tooltipText,
          tooltipBuilder: (BuildContext context, Animation<double> animation) =>
              const Text(tooltipText),
          child: Builder(
            builder: (BuildContext context) {
              buildCount += 1;
              return const SizedBox.expand();
            },
          ),
        ),
      ),
    );
    expect(buildCount, 1);

    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer();
    await tester.pump();
    await gesture.removePointer();
    await tester.pump();

    expect(buildCount, 1);
  });

  testWidgets('Hold mouse button down and hover over the Tooltip widget', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0x00000000),
        pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) {
          return PageRouteBuilder<T>(
            pageBuilder:
                (
                  BuildContext context,
                  Animation<double> animation,
                  Animation<double> secondaryAnimation,
                ) => builder(context),
          );
        },
        home: Center(
          child: SizedBox.square(
            dimension: 10.0,
            child: RawTooltip(
              semanticsTooltip: tooltipText,
              tooltipBuilder: (BuildContext context, Animation<double> animation) =>
                  const Text(tooltipText),
              hoverDelay: const Duration(seconds: 1),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );

    final TestGesture mouseGesture = await tester.startGesture(
      Offset.zero,
      kind: PointerDeviceKind.mouse,
    );
    addTearDown(mouseGesture.removePointer);
    await mouseGesture.moveTo(tester.getCenter(find.byTooltip(tooltipText)));
    await tester.pump(const Duration(seconds: 1));
    expect(
      find.text(tooltipText),
      findsOneWidget,
      reason: 'Tooltip should be visible when hovered.',
    );

    await mouseGesture.up();
    await tester.pump(const Duration(days: 10));
    await tester.pumpAndSettle();
    expect(
      find.text(tooltipText),
      findsOneWidget,
      reason: 'Tooltip should be visible even when there is a PointerUp when hovered.',
    );

    await mouseGesture.moveTo(Offset.zero);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(
      find.text(tooltipText),
      findsNothing,
      reason: 'Tooltip should be dismissed with no hovering mouse cursor.',
    );
  });

  testWidgets('Hovered text should dismiss when clicked outside', (WidgetTester tester) async {
    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0x00000000),
        pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) {
          return PageRouteBuilder<T>(
            pageBuilder:
                (
                  BuildContext context,
                  Animation<double> animation,
                  Animation<double> secondaryAnimation,
                ) => builder(context),
          );
        },
        home: Center(
          child: SizedBox.square(
            dimension: 10.0,
            child: RawTooltip(
              semanticsTooltip: tooltipText,
              tooltipBuilder: (BuildContext context, Animation<double> animation) =>
                  const Text(tooltipText),
              hoverDelay: const Duration(seconds: 1),
              positionDelegate: (TooltipPositionContext context) => positionDependentBox(
                size: context.overlaySize,
                childSize: context.tooltipSize,
                target: context.target,
                preferBelow: context.preferBelow,
                verticalOffset: 24.0,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );

    // Avoid using startGesture here to avoid the PointDown event from also being
    // interpreted as a PointHover event by the Tooltip.
    final TestGesture mouseGesture1 = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouseGesture1.removePointer);
    await mouseGesture1.moveTo(tester.getCenter(find.byTooltip(tooltipText)));
    await tester.pump(const Duration(seconds: 1));
    expect(
      find.text(tooltipText),
      findsOneWidget,
      reason: 'Tooltip should be visible when hovered.',
    );

    // Tapping on the Tooltip widget should dismiss the tooltip, since the
    // trigger mode is longPress.
    await tester.tap(find.byTooltip(tooltipText));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text(tooltipText), findsNothing);
    await mouseGesture1.removePointer();

    final TestGesture mouseGesture2 = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouseGesture2.removePointer);
    await mouseGesture2.moveTo(tester.getCenter(find.byTooltip(tooltipText)));
    await tester.pump(const Duration(seconds: 1));
    expect(
      find.text(tooltipText),
      findsOneWidget,
      reason: 'Tooltip should be visible when hovered.',
    );

    await tester.tapAt(Offset.zero);
    await tester.pump();
    await tester.pumpAndSettle();
    expect(
      find.text(tooltipText),
      findsNothing,
      reason: 'Tapping outside of the Tooltip widget should dismiss the tooltip.',
    );
  });

  testWidgets('Mouse tap and hover over the Tooltip widget', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/127575 .
    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0x00000000),
        pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) {
          return PageRouteBuilder<T>(
            pageBuilder:
                (
                  BuildContext context,
                  Animation<double> animation,
                  Animation<double> secondaryAnimation,
                ) => builder(context),
          );
        },
        home: Center(
          child: SizedBox.square(
            dimension: 10.0,
            child: RawTooltip(
              semanticsTooltip: tooltipText,
              tooltipBuilder: (BuildContext context, Animation<double> animation) =>
                  const Text(tooltipText),
              hoverDelay: const Duration(seconds: 1),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );

    // The PointDown event is also interpreted as a PointHover event by the
    // Tooltip. This should be pretty rare but since it's more of a tap event
    // than a hover event, the tooltip shouldn't show unless the triggerMode
    // is set to tap.
    final TestGesture mouseGesture1 = await tester.startGesture(
      tester.getCenter(find.byTooltip(tooltipText)),
      kind: PointerDeviceKind.mouse,
    );
    addTearDown(mouseGesture1.removePointer);
    await tester.pump(const Duration(seconds: 1));
    expect(
      find.text(tooltipText),
      findsNothing,
      reason: 'Tooltip should NOT be visible when hovered and tapped, when trigger mode is not tap',
    );
    await mouseGesture1.up();
    await mouseGesture1.removePointer();
    await tester.pump(const Duration(days: 10));
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0x00000000),
        pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) {
          return PageRouteBuilder<T>(
            pageBuilder:
                (
                  BuildContext context,
                  Animation<double> animation,
                  Animation<double> secondaryAnimation,
                ) => builder(context),
          );
        },
        home: Center(
          child: SizedBox.square(
            dimension: 10.0,
            child: RawTooltip(
              semanticsTooltip: tooltipText,
              tooltipBuilder: (BuildContext context, Animation<double> animation) =>
                  const Text(tooltipText),
              hoverDelay: const Duration(seconds: 1),
              triggerMode: TooltipTriggerMode.tap,
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );

    final TestGesture mouseGesture2 = await tester.startGesture(
      tester.getCenter(find.byTooltip(tooltipText)),
      kind: PointerDeviceKind.mouse,
    );
    addTearDown(mouseGesture2.removePointer);
    // The tap should be ignored, since Tooltip does not track "trigger gestures"
    // for mouse devices.
    await tester.pump(const Duration(milliseconds: 100));
    await mouseGesture2.up();
    await tester.pump(const Duration(seconds: 1));
    expect(
      find.text(tooltipText),
      findsNothing,
      reason: 'Tooltip should NOT be visible when hovered and tapped, when trigger mode is tap',
    );
  });

  testWidgets('Tooltip does not rebuild for show/hide animation', (WidgetTester tester) async {
    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0x00000000),
        pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) {
          return PageRouteBuilder<T>(
            pageBuilder:
                (
                  BuildContext context,
                  Animation<double> animation,
                  Animation<double> secondaryAnimation,
                ) => builder(context),
          );
        },
        home: Center(
          child: SizedBox.square(
            dimension: 10.0,
            child: RawTooltip(
              semanticsTooltip: tooltipText,
              tooltipBuilder: (BuildContext context, Animation<double> animation) =>
                  FadeTransition(opacity: animation, child: const Text(tooltipText)),
              hoverDelay: const Duration(seconds: 1),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
    final RawTooltipState tooltipState = tester.state(find.byType(RawTooltip));
    final element = tooltipState.context as Element;
    // The Tooltip widget itself is almost stateless thus doesn't need
    // rebuilding.
    expect(element.dirty, isFalse);

    expect(tooltipState.ensureTooltipVisible(), isTrue);
    expect(element.dirty, isFalse);
    await tester.pump(const Duration(seconds: 1));
    expect(element.dirty, isFalse);

    expect(RawTooltip.dismissAllToolTips(), isTrue);
    expect(element.dirty, isFalse);
    await tester.pump(const Duration(seconds: 1));
    expect(element.dirty, isFalse);
  });

  testWidgets('Tooltip does not initialize animation controller in dispose process', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0x00000000),
        pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) {
          return PageRouteBuilder<T>(
            pageBuilder:
                (
                  BuildContext context,
                  Animation<double> animation,
                  Animation<double> secondaryAnimation,
                ) => builder(context),
          );
        },
        home: Center(
          child: RawTooltip(
            semanticsTooltip: tooltipText,
            tooltipBuilder: (BuildContext context, Animation<double> animation) =>
                const Text(tooltipText),
            hoverDelay: const Duration(seconds: 1),
            child: const SizedBox.square(dimension: 50),
          ),
        ),
      ),
    );

    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(find.byType(RawTooltip)),
    );
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);

    // Finish gesture to release resources.
    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets(
    'Tooltip does not crash when showing the tooltip but the OverlayPortal is unmounted, during dispose',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        WidgetsApp(
          color: const Color(0x00000000),
          pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) {
            return PageRouteBuilder<T>(
              pageBuilder:
                  (
                    BuildContext context,
                    Animation<double> animation,
                    Animation<double> secondaryAnimation,
                  ) => builder(context),
            );
          },
          home: Center(
            child: RawTooltip(
              semanticsTooltip: tooltipText,
              tooltipBuilder: (BuildContext context, Animation<double> animation) =>
                  const Text(tooltipText),
              hoverDelay: const Duration(seconds: 1),
              child: const SizedBox.square(dimension: 50),
            ),
          ),
        ),
      );

      final RawTooltipState tooltipState = tester.state(find.byType(RawTooltip));
      final TestGesture gesture = await tester.startGesture(
        tester.getCenter(find.byType(RawTooltip)),
      );
      tooltipState.ensureTooltipVisible();
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);

      // Finish gesture to release resources.
      await gesture.up();
      await tester.pumpAndSettle();
    },
  );

  testWidgets('Custom tooltip positioning - positionDelegate parameter', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0x00000000),
        pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) {
          return PageRouteBuilder<T>(
            pageBuilder:
                (
                  BuildContext context,
                  Animation<double> animation,
                  Animation<double> secondaryAnimation,
                ) => builder(context),
          );
        },
        home: Center(
          child: RawTooltip(
            semanticsTooltip: tooltipText,
            tooltipBuilder: (BuildContext context, Animation<double> animation) =>
                const Placeholder(child: Text(tooltipText)),
            positionDelegate: (TooltipPositionContext context) {
              // Align on top right of box with bottom left of tooltip.
              return Offset(
                context.target.dx + (context.targetSize.width / 2),
                context.target.dy - (context.targetSize.height / 2) - context.tooltipSize.height,
              );
            },
            child: const SizedBox(width: 50, height: 50),
          ),
        ),
      ),
    );

    await tester.longPress(find.byType(RawTooltip));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text(tooltipText), findsOneWidget);

    final Offset targetCenter = tester.getCenter(find.byType(RawTooltip));
    final Offset tooltipPosition = tester.getTopLeft(_findTooltipContainer(tooltipText));

    // The tooltip should be positioned at target + (25, -25-14).
    expect(tooltipPosition.dx, closeTo(targetCenter.dx + 25, 5.0));
    expect(tooltipPosition.dy, closeTo(targetCenter.dy - 25 - 14, 5.0));
  });
}

Future<void> setWidgetForTooltipMode(
  WidgetTester tester,
  TooltipTriggerMode triggerMode, {
  Duration? touchDelay,
  bool? enableTapToDismiss,
  TooltipTriggeredCallback? onTriggered,
  bool? ignorePointer,
}) async {
  await tester.pumpWidget(
    WidgetsApp(
      color: const Color(0x00000000),
      pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) {
        return PageRouteBuilder<T>(
          pageBuilder:
              (
                BuildContext context,
                Animation<double> animation,
                Animation<double> secondaryAnimation,
              ) => builder(context),
        );
      },
      home: Center(
        child: RawTooltip(
          tooltipBuilder: (BuildContext context, Animation<double> animation) =>
              const Text(tooltipText),
          semanticsTooltip: tooltipText,
          triggerMode: triggerMode,
          onTriggered: onTriggered,
          touchDelay: touchDelay ?? const Duration(milliseconds: 1500),
          enableTapToDismiss: enableTapToDismiss ?? true,
          positionDelegate: (TooltipPositionContext context) => positionDependentBox(
            size: context.overlaySize,
            childSize: context.tooltipSize,
            target: context.target,
            preferBelow: context.preferBelow,
            verticalOffset: 24.0,
          ),
          child: const SizedBox(width: 100.0, height: 100.0),
        ),
      ),
    ),
  );
}

Future<void> _testGestureLongPress(WidgetTester tester, Finder tooltip) async {
  final TestGesture gestureLongPress = await tester.startGesture(tester.getCenter(tooltip));
  await tester.pump();
  await tester.pump(kLongPressTimeout);
  await gestureLongPress.up();
  await tester.pump();
}

Future<void> _testGestureTap(WidgetTester tester, Finder tooltip) async {
  await tester.tap(tooltip);
  await tester.pump(const Duration(milliseconds: 10));
}

SemanticsNode _findDebugSemantics(RenderObject object) {
  return object.debugSemantics ?? _findDebugSemantics(object.parent!);
}
