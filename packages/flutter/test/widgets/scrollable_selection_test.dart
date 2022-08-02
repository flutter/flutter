// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'clipboard_utils.dart';

Offset textOffsetToPosition(RenderParagraph paragraph, int offset) {
  const Rect caret = Rect.fromLTWH(0.0, 0.0, 2.0, 20.0);
  final Offset localOffset = paragraph.getOffsetForCaret(TextPosition(offset: offset), caret);
  return paragraph.localToGlobal(localOffset);
}

Offset globalize(Offset point, RenderBox box) {
  return box.localToGlobal(point);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final MockClipboard mockClipboard = MockClipboard();

  setUp(() async {
    TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, mockClipboard.handleMethodCall);
    await Clipboard.setData(const ClipboardData(text: 'empty'));
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets('mouse can select multiple widgets', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: SelectionArea(
        selectionControls: materialTextSelectionControls,
        child: ListView.builder(
          itemCount: 100,
          itemBuilder: (BuildContext context, int index) {
            return Text('Item $index');
          },
        ),
      ),
    ));

    final RenderParagraph paragraph1 = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('Item 0'), matching: find.byType(RichText)));
    final TestGesture gesture = await tester.startGesture(textOffsetToPosition(paragraph1, 2), kind: ui.PointerDeviceKind.mouse);
    addTearDown(gesture.removePointer);
    await tester.pump();

    await gesture.moveTo(textOffsetToPosition(paragraph1, 4));
    await tester.pump();
    expect(paragraph1.selections[0], const TextSelection(baseOffset: 2, extentOffset: 4));

    final RenderParagraph paragraph2 = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('Item 1'), matching: find.byType(RichText)));
    await gesture.moveTo(textOffsetToPosition(paragraph2, 5));
    // Should select the rest of paragraph 1.
    expect(paragraph1.selections[0], const TextSelection(baseOffset: 2, extentOffset: 6));
    expect(paragraph2.selections[0], const TextSelection(baseOffset: 0, extentOffset: 5));

    final RenderParagraph paragraph3 = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('Item 3'), matching: find.byType(RichText)));
    await gesture.moveTo(textOffsetToPosition(paragraph3, 3));
    expect(paragraph1.selections[0], const TextSelection(baseOffset: 2, extentOffset: 6));
    expect(paragraph2.selections[0], const TextSelection(baseOffset: 0, extentOffset: 6));
    expect(paragraph3.selections[0], const TextSelection(baseOffset: 0, extentOffset: 3));

    await gesture.up();
  });

  testWidgets('mouse can select multiple widgets - horizontal', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: SelectionArea(
        selectionControls: materialTextSelectionControls,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: 100,
          itemBuilder: (BuildContext context, int index) {
            return Text('Item $index');
          },
        ),
      ),
    ));

    final RenderParagraph paragraph1 = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('Item 0'), matching: find.byType(RichText)));
    final TestGesture gesture = await tester.startGesture(textOffsetToPosition(paragraph1, 2), kind: ui.PointerDeviceKind.mouse);
    addTearDown(gesture.removePointer);
    await tester.pump();

    await gesture.moveTo(textOffsetToPosition(paragraph1, 4));
    await tester.pump();
    expect(paragraph1.selections[0], const TextSelection(baseOffset: 2, extentOffset: 4));

    final RenderParagraph paragraph2 = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('Item 1'), matching: find.byType(RichText)));
    await gesture.moveTo(textOffsetToPosition(paragraph2, 5) + const Offset(0, 5));
    // Should select the rest of paragraph 1.
    expect(paragraph1.selections[0], const TextSelection(baseOffset: 2, extentOffset: 6));
    expect(paragraph2.selections[0], const TextSelection(baseOffset: 0, extentOffset: 5));

    await gesture.up();
  });

  testWidgets('select to scroll forward', (WidgetTester tester) async {
    final ScrollController controller = ScrollController();
    await tester.pumpWidget(MaterialApp(
      home: SelectionArea(
        selectionControls: materialTextSelectionControls,
        child: ListView.builder(
          controller: controller,
          itemCount: 100,
          itemBuilder: (BuildContext context, int index) {
            return Text('Item $index');
          },
        ),
      ),
    ));

    final RenderParagraph paragraph1 = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('Item 0'), matching: find.byType(RichText)));
    final TestGesture gesture = await tester.startGesture(textOffsetToPosition(paragraph1, 2), kind: ui.PointerDeviceKind.mouse);
    addTearDown(gesture.removePointer);
    await tester.pump();
    expect(controller.offset, 0.0);
    double previousOffset = controller.offset;

    await gesture.moveTo(tester.getBottomRight(find.byType(ListView)));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(controller.offset > previousOffset, isTrue);
    previousOffset = controller.offset;

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(controller.offset > previousOffset, isTrue);

    // Scroll to the end.
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(controller.offset, 4200.0);
    final RenderParagraph paragraph99 = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('Item 99'), matching: find.byType(RichText)));
    final RenderParagraph paragraph98 = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('Item 98'), matching: find.byType(RichText)));
    final RenderParagraph paragraph97 = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('Item 97'), matching: find.byType(RichText)));
    final RenderParagraph paragraph96 = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('Item 96'), matching: find.byType(RichText)));
    expect(paragraph99.selections[0], const TextSelection(baseOffset: 0, extentOffset: 7));
    expect(paragraph98.selections[0], const TextSelection(baseOffset: 0, extentOffset: 7));
    expect(paragraph97.selections[0], const TextSelection(baseOffset: 0, extentOffset: 7));
    expect(paragraph96.selections[0], const TextSelection(baseOffset: 0, extentOffset: 7));

    await gesture.up();
  });

  testWidgets('select to scroll backward', (WidgetTester tester) async {
    final ScrollController controller = ScrollController();
    await tester.pumpWidget(MaterialApp(
      home: SelectionArea(
        selectionControls: materialTextSelectionControls,
        child: ListView.builder(
          controller: controller,
          itemCount: 100,
          itemBuilder: (BuildContext context, int index) {
            return Text('Item $index');
          },
        ),
      ),
    ));

    controller.jumpTo(4000);
    await tester.pumpAndSettle();

    final TestGesture gesture = await tester.startGesture(tester.getCenter(find.byType(ListView)), kind: ui.PointerDeviceKind.mouse);
    addTearDown(gesture.removePointer);
    await tester.pump();
    expect(controller.offset, 4000);
    double previousOffset = controller.offset;

    await gesture.moveTo(tester.getTopLeft(find.byType(ListView)));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(controller.offset < previousOffset, isTrue);
    previousOffset = controller.offset;

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(controller.offset < previousOffset, isTrue);

    // Scroll to the beginning.
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(controller.offset, 0.0);
    final RenderParagraph paragraph0 = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('Item 0'), matching: find.byType(RichText)));
    final RenderParagraph paragraph1 = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('Item 1'), matching: find.byType(RichText)));
    final RenderParagraph paragraph2 = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('Item 2'), matching: find.byType(RichText)));
    final RenderParagraph paragraph3 = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('Item 3'), matching: find.byType(RichText)));
    expect(paragraph0.selections[0], const TextSelection(baseOffset: 6, extentOffset: 0));
    expect(paragraph1.selections[0], const TextSelection(baseOffset: 6, extentOffset: 0));
    expect(paragraph2.selections[0], const TextSelection(baseOffset: 6, extentOffset: 0));
    expect(paragraph3.selections[0], const TextSelection(baseOffset: 6, extentOffset: 0));
  });

  testWidgets('select to scroll forward - horizontal', (WidgetTester tester) async {
    final ScrollController controller = ScrollController();
    await tester.pumpWidget(MaterialApp(
      home: SelectionArea(
        selectionControls: materialTextSelectionControls,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          controller: controller,
          itemCount: 10,
          itemBuilder: (BuildContext context, int index) {
            return Text('Item $index');
          },
        ),
      ),
    ));

    final RenderParagraph paragraph1 = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('Item 0'), matching: find.byType(RichText)));
    final TestGesture gesture = await tester.startGesture(textOffsetToPosition(paragraph1, 2), kind: ui.PointerDeviceKind.mouse);
    addTearDown(gesture.removePointer);
    await tester.pump();
    expect(controller.offset, 0.0);
    double previousOffset = controller.offset;

    await gesture.moveTo(tester.getBottomRight(find.byType(ListView)));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(controller.offset > previousOffset, isTrue);
    previousOffset = controller.offset;

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(controller.offset > previousOffset, isTrue);

    // Scroll to the end.
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(controller.offset, 2080.0);
    final RenderParagraph paragraph9 = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('Item 9'), matching: find.byType(RichText)));
    final RenderParagraph paragraph8 = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('Item 8'), matching: find.byType(RichText)));
    final RenderParagraph paragraph7 = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('Item 7'), matching: find.byType(RichText)));
    expect(paragraph9.selections[0], const TextSelection(baseOffset: 0, extentOffset: 6));
    expect(paragraph8.selections[0], const TextSelection(baseOffset: 0, extentOffset: 6));
    expect(paragraph7.selections[0], const TextSelection(baseOffset: 0, extentOffset: 6));

    await gesture.up();
  });

  testWidgets('select to scroll backward - horizontal', (WidgetTester tester) async {
    final ScrollController controller = ScrollController();
    await tester.pumpWidget(MaterialApp(
      home: SelectionArea(
        selectionControls: materialTextSelectionControls,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          controller: controller,
          itemCount: 10,
          itemBuilder: (BuildContext context, int index) {
            return Text('Item $index');
          },
        ),
      ),
    ));

    controller.jumpTo(2080);
    await tester.pumpAndSettle();

    final TestGesture gesture = await tester.startGesture(tester.getCenter(find.byType(ListView)), kind: ui.PointerDeviceKind.mouse);
    addTearDown(gesture.removePointer);
    await tester.pump();
    expect(controller.offset, 2080);
    double previousOffset = controller.offset;

    await gesture.moveTo(tester.getTopLeft(find.byType(ListView)));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(controller.offset < previousOffset, isTrue);
    previousOffset = controller.offset;

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(controller.offset < previousOffset, isTrue);

    // Scroll to the beginning.
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(controller.offset, 0.0);
    final RenderParagraph paragraph0 = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('Item 0'), matching: find.byType(RichText)));
    final RenderParagraph paragraph1 = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('Item 1'), matching: find.byType(RichText)));
    final RenderParagraph paragraph2 = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('Item 2'), matching: find.byType(RichText)));
    expect(paragraph0.selections[0], const TextSelection(baseOffset: 6, extentOffset: 0));
    expect(paragraph1.selections[0], const TextSelection(baseOffset: 6, extentOffset: 0));
    expect(paragraph2.selections[0], const TextSelection(baseOffset: 6, extentOffset: 0));

    await gesture.up();
  });

  testWidgets('preserve selection when out of view.', (WidgetTester tester) async {
    final ScrollController controller = ScrollController();
    await tester.pumpWidget(MaterialApp(
      home: SelectionArea(
        selectionControls: materialTextSelectionControls,
        child: ListView.builder(
          controller: controller,
          itemCount: 100,
          itemBuilder: (BuildContext context, int index) {
            return Text('Item $index');
          },
        ),
      ),
    ));

    controller.jumpTo(2000);
    await tester.pumpAndSettle();
    expect(find.text('Item 50'), findsOneWidget);
    RenderParagraph paragraph50 = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('Item 50'), matching: find.byType(RichText)));
    final TestGesture gesture = await tester.startGesture(textOffsetToPosition(paragraph50, 2), kind: ui.PointerDeviceKind.mouse);
    addTearDown(gesture.removePointer);
    await tester.pump();
    await gesture.moveTo(textOffsetToPosition(paragraph50, 4));
    await gesture.up();
    expect(paragraph50.selections[0], const TextSelection(baseOffset: 2, extentOffset: 4));

    controller.jumpTo(0);
    await tester.pumpAndSettle();
    expect(find.text('Item 50'), findsNothing);

    controller.jumpTo(2000);
    await tester.pumpAndSettle();
    expect(find.text('Item 50'), findsOneWidget);
    paragraph50 = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('Item 50'), matching: find.byType(RichText)));
    expect(paragraph50.selections[0], const TextSelection(baseOffset: 2, extentOffset: 4));

    controller.jumpTo(4000);
    await tester.pumpAndSettle();
    expect(find.text('Item 50'), findsNothing);

    controller.jumpTo(2000);
    await tester.pumpAndSettle();
    expect(find.text('Item 50'), findsOneWidget);
    paragraph50 = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('Item 50'), matching: find.byType(RichText)));
    expect(paragraph50.selections[0], const TextSelection(baseOffset: 2, extentOffset: 4));
  });

  testWidgets('can select all non-Apple', (WidgetTester tester) async {
    final FocusNode node = FocusNode();
    await tester.pumpWidget(MaterialApp(
      home: SelectionArea(
        focusNode: node,
        selectionControls: materialTextSelectionControls,
        child: ListView.builder(
          itemCount: 100,
          itemBuilder: (BuildContext context, int index) {
            return Text('Item $index');
          },
        ),
      ),
    ));
    await tester.pumpAndSettle();
    node.requestFocus();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyA);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyA);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();

    for (int i = 0; i < 13; i += 1) {
      final RenderParagraph paragraph = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('Item $i'), matching: find.byType(RichText)));
      expect(paragraph.selections[0], TextSelection(baseOffset: 0, extentOffset: 'Item $i'.length));
    }
    expect(find.text('Item 13'), findsNothing);
  }, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.android, TargetPlatform.windows, TargetPlatform.linux, TargetPlatform.fuchsia }));

  testWidgets('can select all - Apple', (WidgetTester tester) async {
    final FocusNode node = FocusNode();
    await tester.pumpWidget(MaterialApp(
      home: SelectionArea(
        focusNode: node,
        selectionControls: materialTextSelectionControls,
        child: ListView.builder(
          itemCount: 100,
          itemBuilder: (BuildContext context, int index) {
            return Text('Item $index');
          },
        ),
      ),
    ));
    await tester.pumpAndSettle();
    node.requestFocus();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyA);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyA);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
    await tester.pump();

    for (int i = 0; i < 13; i += 1) {
      final RenderParagraph paragraph = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('Item $i'), matching: find.byType(RichText)));
      expect(paragraph.selections[0], TextSelection(baseOffset: 0, extentOffset: 'Item $i'.length));
    }
    expect(find.text('Item 13'), findsNothing);
  }, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.iOS, TargetPlatform.macOS }));

  testWidgets('select to scroll by dragging selection handles forward', (WidgetTester tester) async {
    final ScrollController controller = ScrollController();
    await tester.pumpWidget(MaterialApp(
      home: SelectionArea(
        selectionControls: materialTextSelectionControls,
        child: ListView.builder(
          controller: controller,
          itemCount: 100,
          itemBuilder: (BuildContext context, int index) {
            return Text('Item $index');
          },
        ),
      ),
    ));
    await tester.pumpAndSettle();

    // Long press to bring up the selection handles.
    final RenderParagraph paragraph0 = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('Item 0'), matching: find.byType(RichText)));
    final TestGesture gesture = await tester.startGesture(textOffsetToPosition(paragraph0, 2));
    addTearDown(gesture.removePointer);
    await tester.pump(const Duration(milliseconds: 500));
    await gesture.up();
    expect(paragraph0.selections[0], const TextSelection(baseOffset: 0, extentOffset: 4));

    final List<TextBox> boxes = paragraph0.getBoxesForSelection(paragraph0.selections[0]);
    expect(boxes.length, 1);
    final Offset handlePos = globalize(boxes[0].toRect().bottomRight, paragraph0);
    await gesture.down(handlePos);

    expect(controller.offset, 0.0);
    double previousOffset = controller.offset;

    await gesture.moveTo(tester.getBottomRight(find.byType(ListView)));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(controller.offset > previousOffset, isTrue);
    previousOffset = controller.offset;

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(controller.offset > previousOffset, isTrue);

    // Scroll to the end.
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(controller.offset, 4200.0);
    final RenderParagraph paragraph99 = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('Item 99'), matching: find.byType(RichText)));
    final RenderParagraph paragraph98 = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('Item 98'), matching: find.byType(RichText)));
    final RenderParagraph paragraph97 = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('Item 97'), matching: find.byType(RichText)));
    final RenderParagraph paragraph96 = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('Item 96'), matching: find.byType(RichText)));
    expect(paragraph99.selections[0], const TextSelection(baseOffset: 0, extentOffset: 7));
    expect(paragraph98.selections[0], const TextSelection(baseOffset: 0, extentOffset: 7));
    expect(paragraph97.selections[0], const TextSelection(baseOffset: 0, extentOffset: 7));
    expect(paragraph96.selections[0], const TextSelection(baseOffset: 0, extentOffset: 7));
    await gesture.up();
  });

  group('Complex cases', () {
    testWidgets('selection starts outside of the scrollable', (WidgetTester tester) async {
      final ScrollController controller = ScrollController();
      await tester.pumpWidget(MaterialApp(
        home: SelectionArea(
          selectionControls: materialTextSelectionControls,
          child: Column(
            children: <Widget>[
              const Text('Item 0'),
              SizedBox(
                height: 400,
                child: ListView.builder(
                  controller: controller,
                  itemCount: 100,
                  itemBuilder: (BuildContext context, int index) {
                    return Text('Inner item $index');
                  },
                ),
              ),
              const Text('Item 1'),
            ],
          ),
        ),
      ));
      await tester.pumpAndSettle();

      controller.jumpTo(1000);
      await tester.pumpAndSettle();
      final RenderParagraph paragraph0 = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('Item 0'), matching: find.byType(RichText)));
      final TestGesture gesture = await tester.startGesture(textOffsetToPosition(paragraph0, 2), kind: ui.PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);
      final RenderParagraph paragraph1 = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('Item 1'), matching: find.byType(RichText)));
      await gesture.moveTo(textOffsetToPosition(paragraph1, 2) + const Offset(0, 5));
      await tester.pumpAndSettle();
      await gesture.up();

      // The entire scrollable should be selected.
      expect(paragraph0.selections[0], const TextSelection(baseOffset: 2, extentOffset: 6));
      expect(paragraph1.selections[0], const TextSelection(baseOffset: 0, extentOffset: 2));
      final RenderParagraph innerParagraph = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('Inner item 20'), matching: find.byType(RichText)));
      expect(innerParagraph.selections[0], const TextSelection(baseOffset: 0, extentOffset: 13));
      // Should not scroll the inner scrollable.
      expect(controller.offset, 1000.0);
    });

    testWidgets('nested scrollables keep selection alive', (WidgetTester tester) async {
      final ScrollController outerController = ScrollController();
      final ScrollController innerController = ScrollController();
      await tester.pumpWidget(MaterialApp(
        home: SelectionArea(
          selectionControls: materialTextSelectionControls,
          child: ListView.builder(
            controller: outerController,
            itemCount: 100,
            itemBuilder: (BuildContext context, int index) {
              if (index == 2) {
                return SizedBox(
                  height: 700,
                  child: ListView.builder(
                    controller: innerController,
                    itemCount: 100,
                    itemBuilder: (BuildContext context, int index) {
                      return Text('Iteminner $index');
                    },
                  ),
                );
              }
              return Text('Item $index');
            },
          ),
        ),
      ));
      await tester.pumpAndSettle();

      innerController.jumpTo(1000);
      await tester.pumpAndSettle();
      RenderParagraph innerParagraph23 = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('Iteminner 23'), matching: find.byType(RichText)));
      final TestGesture gesture = await tester.startGesture(textOffsetToPosition(innerParagraph23, 2) + const Offset(0, 5), kind: ui.PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);
      RenderParagraph innerParagraph24 = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('Iteminner 24'), matching: find.byType(RichText)));
      await gesture.moveTo(textOffsetToPosition(innerParagraph24, 2) + const Offset(0, 5));
      await tester.pumpAndSettle();
      await gesture.up();
      expect(innerParagraph23.selections[0], const TextSelection(baseOffset: 2, extentOffset: 12));
      expect(innerParagraph24.selections[0], const TextSelection(baseOffset: 0, extentOffset: 2));

      innerController.jumpTo(2000);
      await tester.pumpAndSettle();
      expect(find.descendant(of: find.text('Iteminner 23'), matching: find.byType(RichText)), findsNothing);

      outerController.jumpTo(2000);
      await tester.pumpAndSettle();
      expect(find.descendant(of: find.text('Iteminner 23'), matching: find.byType(RichText)), findsNothing);

      // Selected item is still kept alive.
      expect(find.descendant(of: find.text('Iteminner 23'), matching: find.byType(RichText), skipOffstage: false), findsNothing);

      // Selection stays the same after scrolling back.
      outerController.jumpTo(0);
      await tester.pumpAndSettle();
      expect(innerController.offset, 2000.0);
      innerController.jumpTo(1000);
      await tester.pumpAndSettle();
      innerParagraph23 = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('Iteminner 23'), matching: find.byType(RichText)));
      innerParagraph24 = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('Iteminner 24'), matching: find.byType(RichText)));
      expect(innerParagraph23.selections[0], const TextSelection(baseOffset: 2, extentOffset: 12));
      expect(innerParagraph24.selections[0], const TextSelection(baseOffset: 0, extentOffset: 2));
    });

    testWidgets('can copy off screen selection - Apple', (WidgetTester tester) async {
      final ScrollController controller = ScrollController();
      final FocusNode focusNode = FocusNode();
      await tester.pumpWidget(MaterialApp(
        home: SelectionArea(
          focusNode: focusNode,
          selectionControls: materialTextSelectionControls,
          child: ListView.builder(
            controller: controller,
            itemCount: 100,
            itemBuilder: (BuildContext context, int index) {
              return Text('Item $index');
            },
          ),
        ),
      ));
      focusNode.requestFocus();
      await tester.pumpAndSettle();
      final RenderParagraph paragraph0 = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('Item 0'), matching: find.byType(RichText)));
      final TestGesture gesture = await tester.startGesture(textOffsetToPosition(paragraph0, 2) + const Offset(0, 5), kind: ui.PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);
      final RenderParagraph paragraph1 = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('Item 1'), matching: find.byType(RichText)));
      await gesture.moveTo(textOffsetToPosition(paragraph1, 2) + const Offset(0, 5));
      await tester.pumpAndSettle();
      await gesture.up();
      expect(paragraph0.selections[0], const TextSelection(baseOffset: 2, extentOffset: 6));
      expect(paragraph1.selections[0], const TextSelection(baseOffset: 0, extentOffset: 2));

      // Scroll the selected text out off the screen.
      controller.jumpTo(1000);
      await tester.pumpAndSettle();
      expect(find.descendant(of: find.text('Item 0'), matching: find.byType(RichText)), findsNothing);
      expect(find.descendant(of: find.text('Item 1'), matching: find.byType(RichText)), findsNothing);

      // Start copying.
      await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyC);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyC);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);

      final Map<String, dynamic> clipboardData = mockClipboard.clipboardData as Map<String, dynamic>;
      expect(clipboardData['text'], 'em 0It');
    }, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.iOS, TargetPlatform.macOS }));

    testWidgets('can copy off screen selection - non-Apple', (WidgetTester tester) async {
      final ScrollController controller = ScrollController();
      final FocusNode focusNode = FocusNode();
      await tester.pumpWidget(MaterialApp(
        home: SelectionArea(
          focusNode: focusNode,
          selectionControls: materialTextSelectionControls,
          child: ListView.builder(
            controller: controller,
            itemCount: 100,
            itemBuilder: (BuildContext context, int index) {
              return Text('Item $index');
            },
          ),
        ),
      ));
      focusNode.requestFocus();
      await tester.pumpAndSettle();
      final RenderParagraph paragraph0 = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('Item 0'), matching: find.byType(RichText)));
      final TestGesture gesture = await tester.startGesture(textOffsetToPosition(paragraph0, 2) + const Offset(0, 5), kind: ui.PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);
      final RenderParagraph paragraph1 = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('Item 1'), matching: find.byType(RichText)));
      await gesture.moveTo(textOffsetToPosition(paragraph1, 2) + const Offset(0, 5));
      await tester.pumpAndSettle();
      await gesture.up();
      expect(paragraph0.selections[0], const TextSelection(baseOffset: 2, extentOffset: 6));
      expect(paragraph1.selections[0], const TextSelection(baseOffset: 0, extentOffset: 2));

      // Scroll the selected text out off the screen.
      controller.jumpTo(1000);
      await tester.pumpAndSettle();
      expect(find.descendant(of: find.text('Item 0'), matching: find.byType(RichText)), findsNothing);
      expect(find.descendant(of: find.text('Item 1'), matching: find.byType(RichText)), findsNothing);

      // Start copying.
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyC);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyC);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);

      final Map<String, dynamic> clipboardData = mockClipboard.clipboardData as Map<String, dynamic>;
      expect(clipboardData['text'], 'em 0It');
    }, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.android, TargetPlatform.windows, TargetPlatform.linux, TargetPlatform.fuchsia }));
  });
}
