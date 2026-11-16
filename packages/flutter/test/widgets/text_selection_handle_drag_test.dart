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

Future<Offset Function(int)> _pumpField(
  WidgetTester tester,
  TextEditingController controller,
  FocusNode focusNode,
) async {
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
  // Returns the global position of the caret at `offset`, on the bottom of the
  // line.
  return (int offset) {
    final List<TextSelectionPoint> endpoints = renderEditable.getEndpointsForSelection(
      TextSelection.collapsed(offset: offset),
    );
    return renderEditable.localToGlobal(endpoints.first.point);
  };
}

Future<void> _doubleTapAt(WidgetTester tester, Offset position) async {
  await tester.tapAt(position);
  await tester.pump(const Duration(milliseconds: 50));
  await tester.tapAt(position);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'Changing the text and the selection while a selection handle is dragged ends the drag',
    (WidgetTester tester) async {
      const text = 'aaa bbb ccc ddd eee';
      final controller = TextEditingController(text: text);
      final focusNode = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(focusNode.dispose);
      final Offset Function(int) positionOf = await _pumpField(tester, controller, focusNode);

      // Double tap "ccc" to select it and show the selection handles.
      await _doubleTapAt(tester, positionOf(9) + const Offset(0.0, -2.0));
      expect(controller.selection.start, 8);
      expect(controller.selection.end, 11);

      // Drag the start handle (it hangs below the start of the selection) onto
      // "bbb".
      final double grabY = positionOf(8).dy + 10.0;
      final TestGesture gesture = await tester.startGesture(Offset(positionOf(8).dx, grabY));
      await tester.pump();
      await gesture.moveTo(Offset(positionOf(5).dx, grabY));
      await tester.pump();
      expect(controller.selection.start, 5);
      expect(controller.selection.end, 11);

      // Typing "x" while the handle is held replaces the selection.
      const typedText = 'aaa bx ddd eee';
      controller.value = const TextEditingValue(
        text: typedText,
        selection: TextSelection.collapsed(offset: 6),
      );
      await tester.pump();

      // The drag has ended, so the rest of the gesture is ignored.
      await gesture.moveTo(Offset(positionOf(2).dx, grabY));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(controller.text, typedText);
      expect(controller.selection, const TextSelection.collapsed(offset: 6));
      await gesture.moveTo(Offset(positionOf(12).dx, grabY));
      await tester.pump();
      expect(controller.selection, const TextSelection.collapsed(offset: 6));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(controller.selection, const TextSelection.collapsed(offset: 6));

      // A new drag works as usual. Double tap "ddd" and drag its end handle
      // onto "eee".
      await _doubleTapAt(tester, positionOf(8) + const Offset(0.0, -2.0));
      expect(controller.selection.start, 7);
      expect(controller.selection.end, 10);
      final double endGrabY = positionOf(10).dy + 10.0;
      final TestGesture newGesture = await tester.startGesture(Offset(positionOf(10).dx, endGrabY));
      await tester.pump();
      await newGesture.moveTo(Offset(positionOf(13).dx, endGrabY));
      await tester.pump();
      expect(controller.selection.start, 7);
      expect(controller.selection.end, 13);
      await newGesture.up();
      await tester.pumpAndSettle();
    },
    variant: TargetPlatformVariant.mobile(),
  );

  testWidgets(
    'Deleting the selection a handle drag started from while it is dragged does not create an out-of-range selection',
    (WidgetTester tester) async {
      const longText = 'aaa bbb ccc ddd eee fff ggg hhh';
      const shortText = 'aaa bbb ccc ddd eee fff ggg';
      final controller = TextEditingController(text: longText);
      final focusNode = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(focusNode.dispose);
      final Offset Function(int) positionOf = await _pumpField(tester, controller, focusNode);

      // Double tap "hhh" to select it and show the selection handles.
      await _doubleTapAt(tester, positionOf(29) + const Offset(0.0, -2.0));
      expect(controller.selection.start, 28);
      expect(controller.selection.end, 31);

      // Drag the start handle onto "ggg".
      final double grabY = positionOf(28).dy + 10.0;
      final TestGesture gesture = await tester.startGesture(Offset(positionOf(28).dx, grabY));
      await tester.pump();
      await gesture.moveTo(Offset(positionOf(25).dx, grabY));
      await tester.pump();
      expect(controller.selection.start, 25);
      expect(controller.selection.end, 31);

      // The text gets shorter while the handle is held.
      controller.value = const TextEditingValue(
        text: shortText,
        selection: TextSelection.collapsed(offset: shortText.length),
      );
      await tester.pump();

      await gesture.moveTo(Offset(positionOf(21).dx, grabY));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(controller.selection, const TextSelection.collapsed(offset: shortText.length));
      await gesture.up();
      await tester.pumpAndSettle();

      // Changing the keyboard inset lays out the selection overlay again.
      tester.view.viewInsets = const FakeViewPadding(bottom: 300.0);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(controller.selection, const TextSelection.collapsed(offset: shortText.length));
    },
    variant: TargetPlatformVariant.mobile(),
  );

  testWidgets('Changing only the text while a selection handle is dragged does not end the drag', (
    WidgetTester tester,
  ) async {
    const text = 'aaa bbb ccc ddd eee';
    final controller = TextEditingController(text: text);
    final focusNode = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);
    final Offset Function(int) positionOf = await _pumpField(tester, controller, focusNode);

    // Double tap "ccc" to select it and show the selection handles.
    await _doubleTapAt(tester, positionOf(9) + const Offset(0.0, -2.0));
    expect(controller.selection.start, 8);
    expect(controller.selection.end, 11);

    // Drag the start handle onto "bbb".
    final double grabY = positionOf(8).dy + 10.0;
    final TestGesture gesture = await tester.startGesture(Offset(positionOf(8).dx, grabY));
    await tester.pump();
    await gesture.moveTo(Offset(positionOf(5).dx, grabY));
    await tester.pump();
    expect(controller.selection.start, 5);
    expect(controller.selection.end, 11);

    // The app appends text and keeps the selection.
    controller.value = controller.value.copyWith(text: '$text fff');
    await tester.pump();

    // The drag continues.
    await gesture.moveTo(Offset(positionOf(1).dx, grabY));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(controller.text, '$text fff');
    expect(controller.selection.start, 1);
    expect(controller.selection.end, 11);
    await gesture.up();
    await tester.pumpAndSettle();
  }, variant: TargetPlatformVariant.mobile());
}
