// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

RenderEditable _findRenderEditable(WidgetTester tester) {
  return tester.state<EditableTextState>(find.byType(EditableText)).renderEditable;
}

Offset _textOffsetToPosition(WidgetTester tester, int offset) {
  final RenderEditable renderEditable = _findRenderEditable(tester);
  final List<TextSelectionPoint> endpoints = renderEditable.getEndpointsForSelection(
    TextSelection.collapsed(offset: offset),
  );
  return renderEditable.localToGlobal(endpoints.first.point) + const Offset(0, -2);
}

void main() {
  testWidgets(
    'Dragging a selection handle after the text gets shorter keeps the selection within the text',
    (WidgetTester tester) async {
      const longText = 'aaa bbb ccc ddd eee fff ggg hhh';
      const shortText = 'aaa bbb ccc ddd eee fff ggg';
      final controller = TextEditingController();
      final scrollController = ScrollController();
      addTearDown(controller.dispose);
      addTearDown(scrollController.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 160,
                height: 48,
                child: TextField(
                  controller: controller,
                  scrollController: scrollController,
                  maxLines: null,
                  decoration: null,
                  style: const TextStyle(fontSize: 16, height: 1.5),
                  dragStartBehavior: DragStartBehavior.down,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), longText);
      await tester.pumpAndSettle();

      // Double tap "hhh" to select it.
      final Offset wordPosition = _textOffsetToPosition(tester, 29);
      await tester.tapAt(wordPosition);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tapAt(wordPosition);
      await tester.pumpAndSettle();
      expect(controller.selection, const TextSelection(baseOffset: 28, extentOffset: 31));

      // Drag the start handle onto "ggg". On iOS the dragged handle becomes the extent.
      final RenderEditable renderEditable = _findRenderEditable(tester);
      final Offset startHandle =
          renderEditable.localToGlobal(
            renderEditable.getEndpointsForSelection(controller.selection).first.point,
          ) +
          const Offset(-1, -1);
      final TestGesture gesture = await tester.startGesture(startHandle);
      await tester.pump();
      await gesture.moveTo(_textOffsetToPosition(tester, 25));
      await tester.pump();
      expect(controller.selection, const TextSelection(baseOffset: 31, extentOffset: 25));

      // The text gets shorter while the handle is held.
      controller.value = const TextEditingValue(
        text: shortText,
        selection: TextSelection.collapsed(offset: shortText.length),
      );
      await tester.pump();

      // The whole selection the drag started from ([28, 31)) was deleted, so the
      // drag continues from a caret at the end of the text instead of from an
      // anchor past the end of the text.
      await gesture.moveTo(_textOffsetToPosition(tester, shortText.length));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(controller.selection.baseOffset, shortText.length);
      expect(controller.selection.extentOffset, shortText.length);

      await gesture.moveTo(_textOffsetToPosition(tester, 21));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(controller.selection.baseOffset, 21);
      expect(controller.selection.extentOffset, 21);
      await gesture.up();
      await tester.pumpAndSettle();

      // Scrolling and changing the keyboard inset lay out the selection overlay again.
      scrollController.jumpTo(scrollController.offset - 10);
      await tester.pumpAndSettle();
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(controller.selection.baseOffset, 21);
      expect(controller.selection.extentOffset, 21);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );
}
