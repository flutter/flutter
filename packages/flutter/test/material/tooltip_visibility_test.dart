// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
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
        const MaterialApp(
          home: TooltipVisibility(
            visible: false,
            child: Tooltip(message: tooltipText, child: SizedBox(width: 100.0, height: 100.0)),
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
      const MaterialApp(
        home: Center(
          child: TooltipVisibility(
            visible: false,
            child: Tooltip(
              message: tooltipText,
              waitDuration: waitDuration,
              child: SizedBox(width: 100.0, height: 100.0),
            ),
          ),
        ),
      ),
    );

    final Finder tooltip = find.byType(Tooltip);
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
      const MaterialApp(
        home: Center(
          child: TooltipVisibility(
            visible: true,
            child: Tooltip(
              message: tooltipText,
              waitDuration: waitDuration,
              child: SizedBox(width: 100.0, height: 100.0),
            ),
          ),
        ),
      ),
    );

    final Finder tooltip = find.byType(Tooltip);
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

      final Finder tooltip = find.byType(Tooltip);
      expect(find.text(tooltipText), findsNothing);

      await testGestureTap(tester, tooltip);
      expect(find.text(tooltipText), findsOneWidget);
    },
  );

  testWidgets('Tooltip does not trigger manually when in TooltipVisibility with visible = false', (
    WidgetTester tester,
  ) async {
    final tooltipKey = GlobalKey<TooltipState>();
    await tester.pumpWidget(
      MaterialApp(
        home: TooltipVisibility(
          visible: false,
          child: Tooltip(
            key: tooltipKey,
            message: tooltipText,
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
    final tooltipKey = GlobalKey<TooltipState>();
    await tester.pumpWidget(
      MaterialApp(
        home: TooltipVisibility(
          visible: true,
          child: Tooltip(
            key: tooltipKey,
            message: tooltipText,
            child: const SizedBox(width: 100.0, height: 100.0),
          ),
        ),
      ),
    );

    tooltipKey.currentState?.ensureTooltipVisible();
    await tester.pump();
    expect(find.text(tooltipText), findsOneWidget);
  });

  testWidgets(
    'Tooltip still contributes a semantics tooltip label when in TooltipVisibility with visible = false',
    (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        const MaterialApp(
          home: TooltipVisibility(
            visible: false,
            child: Tooltip(message: tooltipText, child: Text('Bar')),
          ),
        ),
      );

      expect(_semanticsNodeWithLabel(tester, 'Bar')?.tooltip, tooltipText);
      handle.dispose();
    },
  );

  testWidgets(
    'Tooltip does not contribute a semantics tooltip label when excludeFromSemantics is true '
    'and in TooltipVisibility with visible = false',
    (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        const MaterialApp(
          home: TooltipVisibility(
            visible: false,
            child: Tooltip(message: tooltipText, excludeFromSemantics: true, child: Text('Bar')),
          ),
        ),
      );

      expect(_semanticsNodeWithLabel(tester, 'Bar')?.tooltip, isEmpty);
      handle.dispose();
    },
  );
}

Future<void> setWidgetForTooltipMode(
  WidgetTester tester,
  TooltipTriggerMode triggerMode,
  bool visibility,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: TooltipVisibility(
        visible: visibility,
        child: Tooltip(
          message: tooltipText,
          triggerMode: triggerMode,
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

// Searches the whole semantics tree for a node with the given [label],
// regardless of how deeply its own SemanticsNode has been merged into an
// ancestor. Used instead of `tester.getSemantics(finder)` because that method
// walks *up* from the finder's render object looking for the nearest
// non-merged node, which can land on an unrelated ancestor (e.g. the root
// route-scoping node) when nothing between the labelled node and the root
// introduces its own semantics boundary.
SemanticsNode? _semanticsNodeWithLabel(WidgetTester tester, String label) {
  SemanticsNode? found;
  bool visit(SemanticsNode node) {
    if (node.label == label) {
      found = node;
      return false;
    }
    node.visitChildren(visit);
    return found == null;
  }

  final SemanticsNode? root = tester.binding.pipelineOwner.semanticsOwner?.rootSemanticsNode;
  if (root != null) {
    visit(root);
  }
  return found;
}
