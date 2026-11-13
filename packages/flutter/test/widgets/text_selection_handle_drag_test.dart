// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class _HandleControls extends TextSelectionControls with TextSelectionHandleControls {
  @override
  Size getHandleSize(double textLineHeight) => const Size(30.0, 30.0);
  @override
  Offset getHandleAnchor(TextSelectionHandleType type, double textLineHeight) {
    // The handle hangs below its selection endpoint.
    return const Offset(15.0, 0.0);
  }

  @override
  Widget buildHandle(
    BuildContext context,
    TextSelectionHandleType type,
    double textLineHeight, [
    VoidCallback? onTap,
  ]) {
    return const SizedBox(width: 30.0, height: 30.0, child: ColoredBox(color: Color(0xFF0000FF)));
  }
}

class _SelectableField extends StatefulWidget {
  const _SelectableField({required this.controller, required this.focusNode});
  final TextEditingController controller;
  final FocusNode focusNode;
  @override
  State<_SelectableField> createState() => _SelectableFieldState();
}

class _SelectableFieldState extends State<_SelectableField>
    implements TextSelectionGestureDetectorBuilderDelegate {
  @override
  final GlobalKey<EditableTextState> editableTextKey = GlobalKey<EditableTextState>();
  @override
  bool get forcePressEnabled => false;
  @override
  bool get selectionEnabled => true;
  late final TextSelectionGestureDetectorBuilder _gestureDetectorBuilder =
      TextSelectionGestureDetectorBuilder(delegate: this);
  @override
  Widget build(BuildContext context) {
    return _gestureDetectorBuilder.buildGestureDetector(
      behavior: HitTestBehavior.translucent,
      child: EditableText(
        key: editableTextKey,
        controller: widget.controller,
        focusNode: widget.focusNode,
        rendererIgnoresPointer: true,
        showSelectionHandles: true,
        selectionControls: _HandleControls(),
        style: const TextStyle(fontSize: 16.0),
        cursorColor: const Color(0xFF000000),
        backgroundCursorColor: const Color(0xFF888888),
      ),
    );
  }
}

void main() {
  testWidgets(
    'Dragging a selection handle after the text gets shorter keeps the selection within the text',
    (WidgetTester tester) async {
      const longText = 'aaa bbb ccc ddd eee fff ggg hhh';
      const shortText = 'aaa bbb ccc ddd eee fff ggg';
      final controller = TextEditingController(text: longText);
      final focusNode = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(focusNode.dispose);
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Overlay.wrap(
            child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 800.0,
                child: _SelectableField(controller: controller, focusNode: focusNode),
              ),
            ),
          ),
        ),
      );
      final RenderEditable renderEditable = tester
          .state<EditableTextState>(find.byType(EditableText))
          .renderEditable;
      Offset positionOf(int offset) {
        final List<TextSelectionPoint> endpoints = renderEditable.getEndpointsForSelection(
          TextSelection.collapsed(offset: offset),
        );
        return renderEditable.localToGlobal(endpoints.first.point);
      }

      // Double tap "hhh" to select it and show the selection handles.
      final Offset wordPosition = positionOf(29) + const Offset(0.0, -2.0);
      await tester.tapAt(wordPosition);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tapAt(wordPosition);
      await tester.pumpAndSettle();
      expect(controller.selection.baseOffset, 28);
      expect(controller.selection.extentOffset, 31);
      // Drag the start handle (it hangs below the start of the selection) onto
      // "ggg". On iOS, the dragged handle becomes the extent.
      final double grabY = positionOf(28).dy + 10.0;
      final TestGesture gesture = await tester.startGesture(Offset(positionOf(28).dx, grabY));
      await tester.pump();
      await gesture.moveTo(Offset(positionOf(25).dx, grabY));
      await tester.pump();
      expect(controller.selection.baseOffset, 31);
      expect(controller.selection.extentOffset, 25);
      // The text gets shorter while the handle is held.
      controller.value = const TextEditingValue(
        text: shortText,
        selection: TextSelection.collapsed(offset: shortText.length),
      );
      await tester.pump();
      // The whole selection the drag started from ([28, 31)) was deleted, so
      // the drag continues from a caret instead of from an anchor past the end
      // of the text.
      await gesture.moveTo(Offset(positionOf(26).dx, grabY));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(controller.selection.baseOffset, 26);
      expect(controller.selection.extentOffset, 26);
      await gesture.moveTo(Offset(positionOf(21).dx, grabY));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(controller.selection.baseOffset, 21);
      expect(controller.selection.extentOffset, 21);
      await gesture.up();
      await tester.pumpAndSettle();
      // Changing the keyboard inset lays out the selection overlay again.
      tester.view.viewInsets = const FakeViewPadding(bottom: 300.0);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(controller.selection.end, lessThanOrEqualTo(controller.text.length));
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );
}
