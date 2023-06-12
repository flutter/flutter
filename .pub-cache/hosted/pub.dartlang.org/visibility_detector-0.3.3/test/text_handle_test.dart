import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visibility_detector/visibility_detector.dart';

void main() {
  final visibilityDetectorKey = UniqueKey();

  // Disable VisibilityDetector timers.
  VisibilityDetectorController.instance.updateInterval = Duration.zero;

  testWidgets(
    'VisibilityDetector does not affect the positioning of text selection '
    'handles',
    (WidgetTester tester) async {
      final expectedSelectionHandles = await _setUpSelectionHandles(
        tester,
        null,
      );

      final actualSelectionHandles = await _setUpSelectionHandles(
        tester,
        (textField) => VisibilityDetector(
          key: visibilityDetectorKey,
          onVisibilityChanged: (visibilityInfo) {},
          child: textField,
        ),
      );

      expect(actualSelectionHandles, expectedSelectionHandles);
    },
  );
}

/// Sets up a [TextField] with sample text and a sample selection.
///
/// [wrapTextField] is a function that takes the [TextField] as an argument and
/// returns it wrapped in another widget.  If [wrapTextField] is null, the
/// [TextField] will be added to the widget tree directly.
///
/// Returns the bounding rectangles (in global coordinates).  The returned
/// [List] will have 3 elements:
/// 0: The [Rect] of the [TextField].
/// 1: The [Rect] of the starting selection handle.
/// 2: The [Rect] of the ending selection handle.
Future<List<Rect>> _setUpSelectionHandles(
  WidgetTester tester,
  Widget Function(Widget)? wrapTextField,
) async {
  final textController = TextEditingController()
    ..text = 'The five boxing wizards jump quickly';
  final textField = TextField(controller: textController);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        appBar: AppBar(),
        body: (wrapTextField ?? (x) => x)(textField),
      ),
    ),
  );

  // The [TextField] must be focused first.  Otherwise any changes we make
  // to the selection will be lost when it gains focus.
  final textFieldFinder = find.byType(TextField);
  await tester.tap(textFieldFinder);

  const selection = TextSelection(baseOffset: 4, extentOffset: 10);
  textController.selection = selection;
  await tester.pumpAndSettle();

  final state = tester.state<EditableTextState>(find.byType(EditableText));
  expect(state.selectionOverlay!.handlesAreVisible, true);

  // Find the text selection handles (via [CustomPaint] widgets within
  // [CompositedTransformFollower] parents).
  const handleCount = 2;
  final selectionHandles = find.descendant(
    of: find.byType(CompositedTransformFollower),
    matching: find.byType(CustomPaint),
  );
  expect(selectionHandles, findsNWidgets(handleCount));

  final selectionHandleRects = [
    for (var i = 0; i < handleCount; i += 1)
      tester.getRect(selectionHandles.at(i)),
  ];

  expect(selectionHandleRects[0], isNot(equals(selectionHandleRects[1])));
  return [tester.getRect(textFieldFinder), ...selectionHandleRects];
}
