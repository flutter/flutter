// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const String tooltipText = 'TIP';

void main() {
  testWidgets(
    'Tooltip does not build MouseRegion when mouse is detected and in TooltipVisibility with visibility = false',
    (WidgetTester tester) async {
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
          home: TooltipVisibility(
            visible: false,
            child: RawTooltip(
              semanticsTooltip: tooltipText,
              tooltipBuilder: (BuildContext context, Animation<double> animation) =>
                  const Text(tooltipText),
              child: const SizedBox(width: 100.0, height: 100.0),
            ),
          ),
        ),
      );

      expect(
        find.descendant(of: find.byType(RawTooltip), matching: find.byType(MouseRegion)),
        findsNothing,
      );
    },
  );

  testWidgets('Tooltip does not show when hovered when in TooltipVisibility with visible = false', (
    WidgetTester tester,
  ) async {
    const Duration waitDuration = Duration.zero;
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
          child: TooltipVisibility(
            visible: false,
            child: RawTooltip(
              semanticsTooltip: tooltipText,
              tooltipBuilder: (BuildContext context, Animation<double> animation) =>
                  const Text(tooltipText),
              child: const SizedBox(width: 100.0, height: 100.0),
            ),
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
    await tester.pump(waitDuration);
    expect(find.text(tooltipText), findsNothing);
  });

  testWidgets('Tooltip shows when hovered when in TooltipVisibility with visible = true', (
    WidgetTester tester,
  ) async {
    const Duration waitDuration = Duration.zero;
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
          child: TooltipVisibility(
            visible: true,
            child: RawTooltip(
              semanticsTooltip: tooltipText,
              tooltipBuilder: (BuildContext context, Animation<double> animation) =>
                  const Text(tooltipText),
              child: const SizedBox(width: 100.0, height: 100.0),
            ),
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
    await tester.pump(waitDuration);
    expect(find.text(tooltipText), findsOneWidget);

    // Wait for it to disappear.
    await gesture.moveTo(Offset.zero);
    await tester.pumpAndSettle();
    await gesture.removePointer();
    gesture = null;
    expect(find.text(tooltipText), findsNothing);
  });

  testWidgets(
    'Tooltip does not build GestureDetector when in TooltipVisibility with visibility = false',
    (WidgetTester tester) async {
      await setWidgetForTooltipMode(tester, TooltipTriggerMode.tap, false);

      expect(find.byType(GestureDetector), findsNothing);
    },
  );

  testWidgets(
    'Tooltip triggers on tap when trigger mode is tap and in TooltipVisibility with visible = true',
    (WidgetTester tester) async {
      await setWidgetForTooltipMode(tester, TooltipTriggerMode.tap, true);

      final Finder tooltip = find.byType(RawTooltip);
      expect(find.text(tooltipText), findsNothing);

      await testGestureTap(tester, tooltip);
      expect(find.text(tooltipText), findsOneWidget);
    },
  );

  testWidgets('Tooltip does not trigger manually when in TooltipVisibility with visible = false', (
    WidgetTester tester,
  ) async {
    final tooltipKey = GlobalKey<RawTooltipState>();
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
        home: TooltipVisibility(
          visible: false,
          child: RawTooltip(
            key: tooltipKey,
            semanticsTooltip: tooltipText,
            tooltipBuilder: (BuildContext context, Animation<double> animation) =>
                const Text(tooltipText),
            child: const SizedBox(width: 100.0, height: 100.0),
          ),
        ),
      ),
    );

    tooltipKey.currentState?.ensureTooltipVisible();
    await tester.pump();
    expect(find.text(tooltipText), findsNothing);
  });

  testWidgets('Tooltip triggers manually when in TooltipVisibility with visible = true', (
    WidgetTester tester,
  ) async {
    final tooltipKey = GlobalKey<RawTooltipState>();
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
        home: TooltipVisibility(
          visible: true,
          child: RawTooltip(
            key: tooltipKey,
            semanticsTooltip: tooltipText,
            tooltipBuilder: (BuildContext context, Animation<double> animation) =>
                const Text(tooltipText),
            child: const SizedBox(width: 100.0, height: 100.0),
          ),
        ),
      ),
    );

    tooltipKey.currentState?.ensureTooltipVisible();
    await tester.pump();
    expect(find.text(tooltipText), findsOneWidget);
  });
}

Future<void> setWidgetForTooltipMode(
  WidgetTester tester,
  TooltipTriggerMode triggerMode,
  bool visibility,
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
      home: TooltipVisibility(
        visible: visibility,
        child: RawTooltip(
          semanticsTooltip: tooltipText,
          triggerMode: triggerMode,
          tooltipBuilder: (BuildContext context, Animation<double> animation) =>
              const Text(tooltipText),
          child: const SizedBox(width: 100.0, height: 100.0),
        ),
      ),
    ),
  );
}

Future<void> testGestureTap(WidgetTester tester, Finder tooltip) async {
  await tester.tap(tooltip);
  await tester.pump(const Duration(milliseconds: 10));
}
