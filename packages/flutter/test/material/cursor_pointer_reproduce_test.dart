// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../widgets/editable_text_utils.dart' show findRenderEditable;

void main() {
  testWidgets('Android collapsed selection handle is centered relative to the caret', (WidgetTester tester) async {
    const double cursorWidth = 20.0;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: const Scaffold(
          body: Center(
            child: TextField(
              showCursor: true,
              autofocus: true,
              cursorWidth: cursorWidth,
            ),
          ),
        ),
      ),
    );

    // Focus the TextField and show the selection handles.
    await tester.pumpAndSettle();

    final RenderEditable renderEditable = findRenderEditable(tester);
    final List<TextSelectionPoint> endpoints = renderEditable.getEndpointsForSelection(
      const TextSelection.collapsed(offset: 0),
    );
    expect(endpoints.length, 1);

    // Tap the caret to show the handle (cursor pointer).
    final Offset caretOffset = renderEditable.localToGlobal(
      renderEditable.getLocalRectForCaret(const TextPosition(offset: 0)).center,
    );
    await tester.tapAt(caretOffset);
    await tester.pumpAndSettle();

    // Find the collapsed selection handle CustomPaint.
    final Finder handleFinder = find.descendant(
      of: find.byWidgetPredicate((Widget widget) => widget.runtimeType.toString() == '_SelectionHandleOverlay'),
      matching: find.byType(CustomPaint),
    );
    expect(handleFinder, findsOneWidget);

    final RenderBox handleBox = tester.renderObject(handleFinder);
    final Offset handleGlobalCenter = handleBox.localToGlobal(
      Offset(handleBox.size.width / 2, handleBox.size.height / 2),
    );

    final Rect caretRect = renderEditable.getLocalRectForCaret(const TextPosition(offset: 0));
    final Offset caretGlobalCenter = renderEditable.localToGlobal(caretRect.center);

    // Verify that the horizontal center of the handle is aligned with the center of the caret.
    expect(handleGlobalCenter.dx, closeTo(caretGlobalCenter.dx, 0.001));
  });
}
