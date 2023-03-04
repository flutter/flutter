// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

Offset textOffsetToPosition(RenderParagraph paragraph, int offset) {
  const Rect caret = Rect.fromLTWH(0.0, 0.0, 2.0, 20.0);
  final Offset localOffset = paragraph.getOffsetForCaret(TextPosition(offset: offset), caret);
  return paragraph.localToGlobal(localOffset);
}

void main() {
  testWidgets('SelectionArea uses correct selection controls', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: SelectionArea(
        child: Text('abc'),
      ),
    ));
    final SelectableRegion region = tester.widget<SelectableRegion>(find.byType(SelectableRegion));

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        expect(region.selectionControls, materialTextSelectionHandleControls);
      case TargetPlatform.iOS:
        expect(region.selectionControls, cupertinoTextSelectionHandleControls);
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        expect(region.selectionControls, desktopTextSelectionHandleControls);
      case TargetPlatform.macOS:
        expect(region.selectionControls, cupertinoDesktopTextSelectionHandleControls);
    }
  }, variant: TargetPlatformVariant.all());

  testWidgets('builds the default context menu by default', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SelectionArea(
          focusNode: FocusNode(),
          child: const Text('How are you?'),
        ),
      ),
    );

    expect(find.byType(AdaptiveTextSelectionToolbar), findsNothing);

    // Show the toolbar by longpressing.
    final RenderParagraph paragraph1 = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('How are you?'), matching: find.byType(RichText)));
    final TestGesture gesture = await tester.startGesture(textOffsetToPosition(paragraph1, 6)); // at the 'r'
    addTearDown(gesture.removePointer);
    await tester.pump(const Duration(milliseconds: 500));
    // `are` is selected.
    expect(paragraph1.selections[0], const TextSelection(baseOffset: 4, extentOffset: 7));
    await tester.pumpAndSettle();

    expect(find.byType(AdaptiveTextSelectionToolbar), findsOneWidget);
  },
    skip: kIsWeb, // [intended]
  );

  testWidgets('builds a custom context menu if provided', (WidgetTester tester) async {
    final GlobalKey key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: SelectionArea(
          focusNode: FocusNode(),
          contextMenuBuilder: (
            BuildContext context,
            SelectableRegionState selectableRegionState,
          ) {
            return Placeholder(key: key);
          },
          child: const Text('How are you?'),
        ),
      ),
    );

    expect(find.byType(AdaptiveTextSelectionToolbar), findsNothing);
    expect(find.byKey(key), findsNothing);

    // Show the toolbar by longpressing.
    final RenderParagraph paragraph1 = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('How are you?'), matching: find.byType(RichText)));
    final TestGesture gesture = await tester.startGesture(textOffsetToPosition(paragraph1, 6)); // at the 'r'
    addTearDown(gesture.removePointer);
    await tester.pump(const Duration(milliseconds: 500));
    // `are` is selected.
    expect(paragraph1.selections[0], const TextSelection(baseOffset: 4, extentOffset: 7));
    await tester.pumpAndSettle();

    expect(find.byType(AdaptiveTextSelectionToolbar), findsNothing);
    expect(find.byKey(key), findsOneWidget);
  },
    skip: kIsWeb, // [intended]
  );

  testWidgets('onSelectionChange is called when the selection changes', (WidgetTester tester) async {
    SelectedContent? content;

    await tester.pumpWidget(MaterialApp(
      home: SelectionArea(
        child: const Text('How are you'),
        onSelectionChanged: (SelectedContent? selectedContent) => content = selectedContent,
      ),
    ));
    final RenderParagraph paragraph = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('How are you'), matching: find.byType(RichText)));
    final TestGesture gesture = await tester.startGesture(textOffsetToPosition(paragraph, 4), kind: PointerDeviceKind.mouse);
    expect(content, isNull);
    addTearDown(gesture.removePointer);
    await tester.pump();

    await gesture.moveTo(textOffsetToPosition(paragraph, 7));
    await gesture.up();
    await tester.pump();
    expect(content, isNotNull);
    expect(content!.plainText, 'are');

    // Backwards selection.
    await gesture.down(textOffsetToPosition(paragraph, 3));
    expect(content, isNull);
    await gesture.moveTo(textOffsetToPosition(paragraph, 0));
    await gesture.up();
    await tester.pump();
    expect(content, isNotNull);
    expect(content!.plainText, 'How');
  });

  testWidgets('stopping drag of end handle will show the toolbar', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/119314
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.only(top: 64),
            child: Column(
              children: <Widget>[
                const Text('How are you?'),
                SelectionArea(
                  focusNode: FocusNode(),
                  child: const Text('Good, and you?'),
                ),
                const Text('Fine, thank you.'),
              ],
            ),
          ),
        ),
      ),
    );
    final RenderParagraph paragraph2 = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('Good, and you?'), matching: find.byType(RichText)));
    final TestGesture gesture = await tester.startGesture(textOffsetToPosition(paragraph2, 7)); // at the 'a'
    addTearDown(gesture.removePointer);
    await tester.pump(const Duration(milliseconds: 500));
    await gesture.up();
    final List<TextBox> boxes = paragraph2.getBoxesForSelection(paragraph2.selections[0]);
    expect(boxes.length, 1);
    // There is a selection now.
    // We check the presence of the copy button to make sure the selection toolbar
    // is showing.
    expect(find.text('Copy'), findsOneWidget);

    // This is the position of the selection handle displayed at the end.
    final Offset handlePos = paragraph2.localToGlobal(boxes[0].toRect().bottomRight);
    await gesture.down(handlePos);
    await gesture.moveTo(textOffsetToPosition(paragraph2, 11) + Offset(0, paragraph2.size.height / 2));
    await tester.pump();

    await gesture.up();
    await tester.pump();

    // After lifting the finger up, the selection toolbar should be showing again.
    expect(find.text('Copy'), findsOneWidget);
  },
    variant: TargetPlatformVariant.all(),
    skip: kIsWeb, // [intended]
  );
}
