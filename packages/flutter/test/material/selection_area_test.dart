// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../widgets/process_text_utils.dart';

Offset textOffsetToPosition(RenderParagraph paragraph, int offset) {
  const caret = Rect.fromLTWH(0.0, 0.0, 2.0, 20.0);
  final Offset localOffset = paragraph.getOffsetForCaret(TextPosition(offset: offset), caret);
  return paragraph.localToGlobal(localOffset);
}

void main() {
  testWidgets('SelectionArea uses correct selection controls', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: SelectionArea(child: Text('abc'))));
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

  testWidgets('Does not crash when long pressing on padding after dragging', (
    WidgetTester tester,
  ) async {
    // Regression test for https://github.com/flutter/flutter/issues/123378
    await tester.pumpWidget(
      const MaterialApp(
        color: Color(0xFF2196F3),
        title: 'Demo',
        home: Scaffold(
          body: SelectionArea(
            child: Padding(padding: EdgeInsets.all(100.0), child: Text('Hello World')),
          ),
        ),
      ),
    );
    final TestGesture dragging = await tester.startGesture(const Offset(10, 10));
    addTearDown(dragging.removePointer);
    await tester.pump(const Duration(milliseconds: 500));
    await dragging.moveTo(const Offset(90, 90));
    await dragging.up();

    final TestGesture longpress = await tester.startGesture(const Offset(20, 20));
    addTearDown(longpress.removePointer);
    await tester.pump(const Duration(milliseconds: 500));
    await longpress.up();

    expect(tester.takeException(), isNull);
  });

  // Regression test for https://github.com/flutter/flutter/issues/111370
  testWidgets(
    'Handle is correctly transformed when the text is inside of a FittedBox ',
    (WidgetTester tester) async {
      final Key textKey = UniqueKey();
      await tester.pumpWidget(
        MaterialApp(
          color: const Color(0xFF2196F3),
          home: Scaffold(
            body: SelectionArea(
              child: SizedBox(
                height: 100,
                child: FittedBox(
                  fit: BoxFit.fill,
                  child: Text('test', key: textKey),
                ),
              ),
            ),
          ),
        ),
      );

      final TestGesture longpress = await tester.startGesture(tester.getCenter(find.byType(Text)));
      addTearDown(longpress.removePointer);
      await tester.pump(const Duration(milliseconds: 500));
      await longpress.up();

      // Text box is scaled by 5.
      final RenderBox textBox = tester.firstRenderObject(find.byKey(textKey));
      expect(textBox.size.height, 20.0);
      final Offset textPoint = textBox.localToGlobal(const Offset(0, 20));
      expect(textPoint, equals(const Offset(0, 100)));

      // Find handles and verify their sizes.
      expect(find.byType(Overlay), findsOneWidget);
      expect(
        find.descendant(of: find.byType(Overlay), matching: find.byType(CustomPaint)),
        findsNWidgets(2),
      );
      final Iterable<RenderBox> handles = tester.renderObjectList(
        find.descendant(of: find.byType(Overlay), matching: find.byType(CustomPaint)),
      );

      // The handle height is determined by the formula:
      // textLineHeight + _kSelectionHandleRadius * 2 - _kSelectionHandleOverlap .
      // The text line height will be the value of the fontSize.
      // The constant _kSelectionHandleRadius has the value of 6.
      // The constant _kSelectionHandleOverlap has the value of 1.5.
      // The handle height before scaling is 20.0 + 6 * 2 - 1.5 = 30.5.

      final double handleHeightBeforeScaling = handles.first.size.height;
      expect(handleHeightBeforeScaling, 30.5);

      final Offset handleHeightAfterScaling =
          handles.first.localToGlobal(const Offset(0, 30.5)) -
          handles.first.localToGlobal(Offset.zero);

      // The handle height after scaling is  30.5 * 5 = 152.5
      expect(handleHeightAfterScaling, equals(const Offset(0.0, 152.5)));
    },
    skip: isBrowser, // [intended]
    variant: const TargetPlatformVariant(<TargetPlatform>{TargetPlatform.iOS}),
  );

  testWidgets(
    'builds the default context menu by default on Android and iOS web',
    (WidgetTester tester) async {
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: SelectionArea(focusNode: focusNode, child: const Text('How are you?')),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AdaptiveTextSelectionToolbar), findsNothing);

      // Show the toolbar by longpressing.
      final RenderParagraph paragraph1 = tester.renderObject<RenderParagraph>(
        find.descendant(of: find.text('How are you?'), matching: find.byType(RichText)),
      );
      final TestGesture gesture = await tester.startGesture(
        textOffsetToPosition(paragraph1, 6),
      ); // at the 'r'
      addTearDown(gesture.removePointer);
      await tester.pump(const Duration(milliseconds: 500));
      // `are` is selected.
      expect(paragraph1.selections[0], const TextSelection(baseOffset: 4, extentOffset: 7));

      await gesture.up();
      await tester.pumpAndSettle();

      expect(find.byType(AdaptiveTextSelectionToolbar), findsOneWidget);
    },
    // TODO(Renzo-Olivares): Remove this test when the web context menu
    // for Android and iOS is re-enabled.
    // See: https://github.com/flutter/flutter/issues/177123.
    // [intended] Android and iOS use the flutter rendered menu on the web.
    skip:
        !kIsWeb ||
        !<TargetPlatform>{
          TargetPlatform.android,
          TargetPlatform.iOS,
        }.contains(defaultTargetPlatform),
  );

  testWidgets(
    'builds the default context menu by default',
    (WidgetTester tester) async {
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: SelectionArea(focusNode: focusNode, child: const Text('How are you?')),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AdaptiveTextSelectionToolbar), findsNothing);

      // Show the toolbar by longpressing.
      final RenderParagraph paragraph1 = tester.renderObject<RenderParagraph>(
        find.descendant(of: find.text('How are you?'), matching: find.byType(RichText)),
      );
      final TestGesture gesture = await tester.startGesture(
        textOffsetToPosition(paragraph1, 6),
      ); // at the 'r'
      addTearDown(gesture.removePointer);
      await tester.pump(const Duration(milliseconds: 500));
      // `are` is selected.
      expect(paragraph1.selections[0], const TextSelection(baseOffset: 4, extentOffset: 7));

      await gesture.up();
      await tester.pumpAndSettle();

      expect(find.byType(AdaptiveTextSelectionToolbar), findsOneWidget);
    },
    skip: kIsWeb, // [intended]
  );

  testWidgets(
    'builds a custom context menu if provided',
    (WidgetTester tester) async {
      final GlobalKey key = GlobalKey();
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: SelectionArea(
            focusNode: focusNode,
            contextMenuBuilder:
                (BuildContext context, SelectableRegionState selectableRegionState) {
                  return Placeholder(key: key);
                },
            child: const Text('How are you?'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AdaptiveTextSelectionToolbar), findsNothing);
      expect(find.byKey(key), findsNothing);

      // Show the toolbar by longpressing.
      final RenderParagraph paragraph1 = tester.renderObject<RenderParagraph>(
        find.descendant(of: find.text('How are you?'), matching: find.byType(RichText)),
      );
      final TestGesture gesture = await tester.startGesture(
        textOffsetToPosition(paragraph1, 6),
      ); // at the 'r'
      addTearDown(gesture.removePointer);
      await tester.pump(const Duration(milliseconds: 500));
      // `are` is selected.
      expect(paragraph1.selections[0], const TextSelection(baseOffset: 4, extentOffset: 7));

      await gesture.up();
      await tester.pumpAndSettle();

      expect(find.byType(AdaptiveTextSelectionToolbar), findsNothing);
      expect(find.byKey(key), findsOneWidget);
    },
    skip: kIsWeb, // [intended]
  );

  testWidgets(
    'Text processing actions are added to the toolbar',
    (WidgetTester tester) async {
      final mockProcessTextHandler = MockProcessTextHandler();
      TestWidgetsFlutterBinding.ensureInitialized().defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.processText,
        mockProcessTextHandler.handleMethodCall,
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.processText,
          null,
        ),
      );

      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: SelectionArea(focusNode: focusNode, child: const Text('How are you?')),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AdaptiveTextSelectionToolbar), findsNothing);

      final RenderParagraph paragraph = tester.renderObject<RenderParagraph>(
        find.descendant(of: find.text('How are you?'), matching: find.byType(RichText)),
      );
      final TestGesture gesture = await tester.startGesture(
        textOffsetToPosition(paragraph, 6),
      ); // at the 'r'
      addTearDown(gesture.removePointer);
      await tester.pump(const Duration(milliseconds: 500));
      // `are` is selected.
      expect(paragraph.selections[0], const TextSelection(baseOffset: 4, extentOffset: 7));

      await gesture.up();
      await tester.pumpAndSettle();

      // The toolbar is visible.
      expect(find.byType(AdaptiveTextSelectionToolbar), findsOneWidget);

      // The text processing actions are visible on Android only.
      final areTextActionsSupported = defaultTargetPlatform == TargetPlatform.android;
      expect(find.text(fakeAction1Label), areTextActionsSupported ? findsOneWidget : findsNothing);
      expect(find.text(fakeAction2Label), areTextActionsSupported ? findsOneWidget : findsNothing);
    },
    variant: TargetPlatformVariant.all(),
    skip: kIsWeb, // [intended]
  );

  testWidgets('onSelectionChange is called when the selection changes', (
    WidgetTester tester,
  ) async {
    SelectedContent? content;

    await tester.pumpWidget(
      MaterialApp(
        home: SelectionArea(
          child: const Text('How are you'),
          onSelectionChanged: (SelectedContent? selectedContent) => content = selectedContent,
        ),
      ),
    );
    final RenderParagraph paragraph = tester.renderObject<RenderParagraph>(
      find.descendant(of: find.text('How are you'), matching: find.byType(RichText)),
    );
    final TestGesture gesture = await tester.startGesture(
      textOffsetToPosition(paragraph, 4),
      kind: PointerDeviceKind.mouse,
    );
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
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle(kDoubleTapTimeout);
    expect(content, isNotNull);
    expect(content!.plainText, '');

    await gesture.down(textOffsetToPosition(paragraph, 3));
    await tester.pump();
    await gesture.moveTo(textOffsetToPosition(paragraph, 0));
    await gesture.up();
    await tester.pump();
    expect(content, isNotNull);
    expect(content!.plainText, 'How');
  });

  testWidgets(
    'stopping drag of end handle will show the toolbar',
    (WidgetTester tester) async {
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      // Regression test for https://github.com/flutter/flutter/issues/119314
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: false),
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.only(top: 64),
              child: Column(
                children: <Widget>[
                  const Text('How are you?'),
                  SelectionArea(focusNode: focusNode, child: const Text('Good, and you?')),
                  const Text('Fine, thank you.'),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final RenderParagraph paragraph2 = tester.renderObject<RenderParagraph>(
        find.descendant(of: find.text('Good, and you?'), matching: find.byType(RichText)),
      );
      final TestGesture gesture = await tester.startGesture(
        textOffsetToPosition(paragraph2, 7),
      ); // at the 'a'
      addTearDown(gesture.removePointer);
      await tester.pump(const Duration(milliseconds: 500));
      await gesture.up();
      final List<TextBox> boxes = paragraph2.getBoxesForSelection(paragraph2.selections[0]);
      expect(boxes.length, 1);
      await tester.pumpAndSettle();
      // There is a selection now.
      // We check the presence of the copy button to make sure the selection toolbar
      // is showing.
      expect(find.text('Copy'), findsOneWidget);

      // This is the position of the selection handle displayed at the end.
      final Offset handlePos = paragraph2.localToGlobal(boxes[0].toRect().bottomRight);
      await gesture.down(handlePos);
      await gesture.moveTo(
        textOffsetToPosition(paragraph2, 11) + Offset(0, paragraph2.size.height / 2),
      );
      await tester.pump();

      await gesture.up();
      await tester.pump();

      // After lifting the finger up, the selection toolbar should be showing again.
      expect(find.text('Copy'), findsOneWidget);
    },
    variant: TargetPlatformVariant.mobile(),
    skip: kIsWeb, // [intended]
  );

  testWidgets(
    'Can only drag one selection handle at a time on iOS',
    (WidgetTester tester) async {
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: false),
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.only(top: 64),
              child: Center(
                child: SelectionArea(
                  focusNode: focusNode,
                  child: const Text('one two three four five'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final RenderParagraph paragraph = tester.renderObject<RenderParagraph>(
        find.descendant(of: find.text('one two three four five'), matching: find.byType(RichText)),
      );
      final TestGesture gesture = await tester.startGesture(
        textOffsetToPosition(paragraph, 11),
      ); // at the 'e'.
      addTearDown(gesture.removePointer);
      await tester.pump(const Duration(milliseconds: 500));
      await gesture.up();
      await tester.pumpAndSettle();
      final List<TextBox> boxes = paragraph.getBoxesForSelection(paragraph.selections[0]);
      expect(boxes.length, 1);
      await tester.pumpAndSettle();
      // There is a selection now.
      expect(paragraph.selections.length, 1);
      expect(paragraph.selections[0], const TextSelection(baseOffset: 8, extentOffset: 13));

      // This is the position of the selection handle displayed at the end.
      final Offset endHandlePos = paragraph.localToGlobal(boxes[0].toRect().bottomRight);
      await gesture.down(endHandlePos);
      await gesture.moveTo(
        textOffsetToPosition(paragraph, 22) + Offset(0, paragraph.size.height / 2),
      );
      await tester.pumpAndSettle();

      expect(paragraph.selections.length, 1);
      expect(paragraph.selections[0], const TextSelection(baseOffset: 8, extentOffset: 22));

      // Attempt to move the start handle while still touching the end handle.
      final Offset startHandlePos = paragraph.localToGlobal(boxes[0].toRect().bottomLeft);
      final TestGesture startHandleGesture = await tester.startGesture(startHandlePos);
      addTearDown(startHandleGesture.removePointer);
      await tester.pump();
      await startHandleGesture.moveTo(
        textOffsetToPosition(paragraph, 0) + Offset(0, paragraph.size.height / 2),
      );
      await tester.pump();
      await gesture.up();
      await startHandleGesture.up();
      await tester.pumpAndSettle();
      // Selection should not change when dragging start handle.
      expect(paragraph.selections.length, 1);
      expect(paragraph.selections[0], const TextSelection(baseOffset: 8, extentOffset: 22));
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    skip: kIsWeb, // [intended]
  );

  testWidgets(
    'Can only drag one selection handle at a time on Android web',
    (WidgetTester tester) async {
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: false),
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.only(top: 64),
              child: Center(
                child: SelectionArea(
                  focusNode: focusNode,
                  child: const Text('one two three four five'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final RenderParagraph paragraph = tester.renderObject<RenderParagraph>(
        find.descendant(of: find.text('one two three four five'), matching: find.byType(RichText)),
      );
      final TestGesture gesture = await tester.startGesture(
        textOffsetToPosition(paragraph, 11),
      ); // at the 'e'.
      addTearDown(gesture.removePointer);
      await tester.pump(const Duration(milliseconds: 500));
      await gesture.up();
      await tester.pumpAndSettle();
      final List<TextBox> boxes = paragraph.getBoxesForSelection(paragraph.selections[0]);
      expect(boxes.length, 1);
      await tester.pumpAndSettle();
      // There is a selection now.
      expect(paragraph.selections.length, 1);
      expect(paragraph.selections[0], const TextSelection(baseOffset: 8, extentOffset: 13));

      // This is the position of the selection handle displayed at the end.
      final Offset endHandlePos = paragraph.localToGlobal(boxes[0].toRect().bottomRight);
      await gesture.down(endHandlePos);
      await gesture.moveTo(
        textOffsetToPosition(paragraph, 22) + Offset(0, paragraph.size.height / 2),
      );
      await tester.pumpAndSettle();

      expect(paragraph.selections.length, 1);
      expect(paragraph.selections[0], const TextSelection(baseOffset: 8, extentOffset: 22));

      // Attempt to move the start handle while still touching the end handle.
      final Offset startHandlePos = paragraph.localToGlobal(boxes[0].toRect().bottomLeft);
      final TestGesture startHandleGesture = await tester.startGesture(startHandlePos);
      addTearDown(startHandleGesture.removePointer);
      await tester.pump();
      await startHandleGesture.moveTo(
        textOffsetToPosition(paragraph, 0) + Offset(0, paragraph.size.height / 2),
      );
      await tester.pump();
      await gesture.up();
      await startHandleGesture.up();
      await tester.pumpAndSettle();
      // Selection should not change when dragging start handle.
      expect(paragraph.selections.length, 1);
      expect(paragraph.selections[0], const TextSelection(baseOffset: 8, extentOffset: 22));
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
    skip: !kIsWeb, // [intended] on native both selection handles can be dragged at a time.
  );

  testWidgets(
    'Can drag both selection handles at a time on Android',
    (WidgetTester tester) async {
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: false),
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.only(top: 64),
              child: Center(
                child: SelectionArea(
                  focusNode: focusNode,
                  child: const Text('one two three four five'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final RenderParagraph paragraph = tester.renderObject<RenderParagraph>(
        find.descendant(of: find.text('one two three four five'), matching: find.byType(RichText)),
      );
      final TestGesture gesture = await tester.startGesture(
        textOffsetToPosition(paragraph, 11),
      ); // at the 'e'.
      addTearDown(gesture.removePointer);
      await tester.pump(const Duration(milliseconds: 500));
      await gesture.up();
      await tester.pumpAndSettle();
      final List<TextBox> boxes = paragraph.getBoxesForSelection(paragraph.selections[0]);
      expect(boxes.length, 1);
      await tester.pumpAndSettle();
      // There is a selection now.
      expect(paragraph.selections.length, 1);
      expect(paragraph.selections[0], const TextSelection(baseOffset: 8, extentOffset: 13));

      // This is the position of the selection handle displayed at the end.
      final Offset endHandlePos = paragraph.localToGlobal(boxes[0].toRect().bottomRight);
      await gesture.down(endHandlePos);
      await gesture.moveTo(
        textOffsetToPosition(paragraph, 22) + Offset(0, paragraph.size.height / 2),
      );
      await tester.pumpAndSettle();

      expect(paragraph.selections.length, 1);
      expect(paragraph.selections[0], const TextSelection(baseOffset: 8, extentOffset: 22));

      // Attempt to move the start handle while still touching the end handle.
      final Offset startHandlePos = paragraph.localToGlobal(boxes[0].toRect().bottomLeft);
      final TestGesture startHandleGesture = await tester.startGesture(startHandlePos);
      addTearDown(startHandleGesture.removePointer);
      await tester.pump();
      await startHandleGesture.moveTo(
        textOffsetToPosition(paragraph, 0) + Offset(0, paragraph.size.height / 2),
      );
      await tester.pump();
      await gesture.up();
      await startHandleGesture.up();
      await tester.pumpAndSettle();
      // Selection changes when dragging start handle.
      expect(paragraph.selections.length, 1);
      expect(paragraph.selections[0], const TextSelection(baseOffset: 0, extentOffset: 22));
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
    skip: kIsWeb, // [intended] on web only one selection handle can be dragged at a time.
  );

  // Regression test for https://github.com/flutter/flutter/issues/174246 .
  // This is a control case against its Web counterpart in
  // html_element_view_test.dart.
  testWidgets('SelectionArea applies correct mouse cursors in its empty region', (
    WidgetTester tester,
  ) async {
    final GlobalKey innerRegion = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          // Region 1 (fullscreen)
          body: MouseRegion(
            cursor: SystemMouseCursors.grab,
            child: Center(
              child: Container(
                decoration: BoxDecoration(border: Border.all()),
                // Region 2 (SelectionArea)
                child: SelectionArea(
                  child: Padding(
                    padding: const EdgeInsetsGeometry.all(40),
                    // Region 3 (inner MouseRegion)
                    child: MouseRegion(
                      key: innerRegion,
                      cursor: SystemMouseCursors.forbidden,
                      onHover: (_) {},
                      child: Container(color: const Color(0xFFAA9933), width: 200, height: 50),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    const region1 = Offset(10, 10);
    final Offset region2 = tester.getTopLeft(find.byKey(innerRegion)) - const Offset(3, 3);
    final Offset region3 = tester.getCenter(find.byKey(innerRegion));

    final TestGesture gesture = await tester.startGesture(region1, kind: PointerDeviceKind.mouse);
    addTearDown(gesture.removePointer);
    expect(
      RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
      SystemMouseCursors.grab,
    );

    await gesture.moveTo(region2);
    expect(
      RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
      SystemMouseCursors.grab,
    );

    await gesture.moveTo(region3);
    expect(
      RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
      SystemMouseCursors.forbidden,
    );

    await gesture.moveTo(region2);
    expect(
      RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
      SystemMouseCursors.grab,
    );
  }, skip: kIsWeb); // There's a Web version in html_element_view_test.dart

  testWidgets('SelectionArea does not crash at zero area', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: SizedBox.shrink(child: SelectionArea(child: Text('X'))),
        ),
      ),
    );
    expect(tester.getSize(find.byType(SelectionArea)), Size.zero);
  });
}
