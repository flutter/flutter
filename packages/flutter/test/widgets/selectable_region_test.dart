// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../widgets/clipboard_utils.dart';

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

  group('SelectionArea', () {
    testWidgets('mouse selection sends correct events', (WidgetTester tester) async {
      final UniqueKey spy = UniqueKey();
      await tester.pumpWidget(
          MaterialApp(
            home: SelectableRegion(
              focusNode: FocusNode(),
              selectionControls: materialTextSelectionControls,
              child: SelectionSpy(key: spy),
            ),
          )
      );

      final RenderSelectionSpy renderSelectionSpy = tester.renderObject<RenderSelectionSpy>(find.byKey(spy));
      final TestGesture gesture = await tester.startGesture(const Offset(200.0, 200.0), kind: PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);
      renderSelectionSpy.events.clear();

      await gesture.moveTo(const Offset(200.0, 100.0));
      expect(renderSelectionSpy.events.length, 2);
      expect(renderSelectionSpy.events[0].type, SelectionEventType.startEdgeUpdate);
      final SelectionEdgeUpdateEvent startEdge = renderSelectionSpy.events[0] as SelectionEdgeUpdateEvent;
      expect(startEdge.globalPosition, const Offset(200.0, 200.0));
      expect(renderSelectionSpy.events[1].type, SelectionEventType.endEdgeUpdate);
      SelectionEdgeUpdateEvent endEdge = renderSelectionSpy.events[1] as SelectionEdgeUpdateEvent;
      expect(endEdge.globalPosition, const Offset(200.0, 100.0));
      renderSelectionSpy.events.clear();

      await gesture.moveTo(const Offset(100.0, 100.0));
      expect(renderSelectionSpy.events.length, 1);
      expect(renderSelectionSpy.events[0].type, SelectionEventType.endEdgeUpdate);
      endEdge = renderSelectionSpy.events[0] as SelectionEdgeUpdateEvent;
      expect(endEdge.globalPosition, const Offset(100.0, 100.0));

      await gesture.up();
    }, skip: kIsWeb); // https://github.com/flutter/flutter/issues/102410.

    testWidgets('touch does not accept drag', (WidgetTester tester) async {
      final UniqueKey spy = UniqueKey();
      await tester.pumpWidget(
          MaterialApp(
            home: SelectableRegion(
              focusNode: FocusNode(),
              selectionControls: materialTextSelectionControls,
              child: SelectionSpy(key: spy),
            ),
          )
      );

      final RenderSelectionSpy renderSelectionSpy = tester.renderObject<RenderSelectionSpy>(find.byKey(spy));
      final TestGesture gesture = await tester.startGesture(const Offset(200.0, 200.0));
      addTearDown(gesture.removePointer);
      await gesture.moveTo(const Offset(200.0, 100.0));
      await gesture.up();
      expect(
        renderSelectionSpy.events.every((SelectionEvent element) => element is ClearSelectionEvent),
        isTrue
      );
    });

    testWidgets('mouse selection always cancels previous selection', (WidgetTester tester) async {
      final UniqueKey spy = UniqueKey();
      await tester.pumpWidget(
          MaterialApp(
            home: SelectableRegion(
              focusNode: FocusNode(),
              selectionControls: materialTextSelectionControls,
              child: SelectionSpy(key: spy),
            ),
          )
      );

      final RenderSelectionSpy renderSelectionSpy = tester.renderObject<RenderSelectionSpy>(find.byKey(spy));
      final TestGesture gesture = await tester.startGesture(const Offset(200.0, 200.0), kind: PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);
      expect(renderSelectionSpy.events.length, 1);
      expect(renderSelectionSpy.events[0], isA<ClearSelectionEvent>());
    }, skip: kIsWeb); // https://github.com/flutter/flutter/issues/102410.

    testWidgets('touch long press sends select-word event', (WidgetTester tester) async {
      final UniqueKey spy = UniqueKey();
      await tester.pumpWidget(
          MaterialApp(
            home: SelectableRegion(
              focusNode: FocusNode(),
              selectionControls: materialTextSelectionControls,
              child: SelectionSpy(key: spy),
            ),
          )
      );

      final RenderSelectionSpy renderSelectionSpy = tester.renderObject<RenderSelectionSpy>(find.byKey(spy));
      renderSelectionSpy.events.clear();
      final TestGesture gesture = await tester.startGesture(const Offset(200.0, 200.0));
      addTearDown(gesture.removePointer);
      await tester.pump(const Duration(milliseconds: 500));
      await gesture.up();
      expect(renderSelectionSpy.events.length, 1);
      expect(renderSelectionSpy.events[0], isA<SelectWordSelectionEvent>());
      final SelectWordSelectionEvent selectionEvent = renderSelectionSpy.events[0] as SelectWordSelectionEvent;
      expect(selectionEvent.globalPosition, const Offset(200.0, 200.0));
    });

    testWidgets('touch long press and drag sends correct events', (WidgetTester tester) async {
      final UniqueKey spy = UniqueKey();
      await tester.pumpWidget(
          MaterialApp(
            home: SelectableRegion(
              focusNode: FocusNode(),
              selectionControls: materialTextSelectionControls,
              child: SelectionSpy(key: spy),
            ),
          )
      );

      final RenderSelectionSpy renderSelectionSpy = tester.renderObject<RenderSelectionSpy>(find.byKey(spy));
      renderSelectionSpy.events.clear();
      final TestGesture gesture = await tester.startGesture(const Offset(200.0, 200.0));
      addTearDown(gesture.removePointer);
      await tester.pump(const Duration(milliseconds: 500));
      expect(renderSelectionSpy.events.length, 1);
      expect(renderSelectionSpy.events[0], isA<SelectWordSelectionEvent>());
      final SelectWordSelectionEvent selectionEvent = renderSelectionSpy.events[0] as SelectWordSelectionEvent;
      expect(selectionEvent.globalPosition, const Offset(200.0, 200.0));

      renderSelectionSpy.events.clear();
      await gesture.moveTo(const Offset(200.0, 50.0));
      await gesture.up();
      expect(renderSelectionSpy.events.length, 1);
      expect(renderSelectionSpy.events[0].type, SelectionEventType.endEdgeUpdate);
      final SelectionEdgeUpdateEvent edgeEvent = renderSelectionSpy.events[0] as SelectionEdgeUpdateEvent;
      expect(edgeEvent.globalPosition, const Offset(200.0, 50.0));
    });

    testWidgets('mouse long press does not send select-word event', (WidgetTester tester) async {
      final UniqueKey spy = UniqueKey();
      await tester.pumpWidget(
        MaterialApp(
          home: SelectableRegion(
            focusNode: FocusNode(),
            selectionControls: materialTextSelectionControls,
            child: SelectionSpy(key: spy),
          ),
        ),
      );

      final RenderSelectionSpy renderSelectionSpy = tester.renderObject<RenderSelectionSpy>(find.byKey(spy));
      renderSelectionSpy.events.clear();
      final TestGesture gesture = await tester.startGesture(const Offset(200.0, 200.0), kind: PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);
      await tester.pump(const Duration(milliseconds: 500));
      await gesture.up();
      expect(
        renderSelectionSpy.events.every((SelectionEvent element) => element is ClearSelectionEvent),
        isTrue,
      );
    });
  });

  group('SelectionArea integration', () {
    testWidgets('mouse can select single text', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SelectableRegion(
            focusNode: FocusNode(),
            selectionControls: materialTextSelectionControls,
            child: const Center(
              child: Text('How are you'),
            ),
          ),
        ),
      );
      final RenderParagraph paragraph = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('How are you'), matching: find.byType(RichText)));
      final TestGesture gesture = await tester.startGesture(textOffsetToPosition(paragraph, 2), kind: PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);
      await tester.pump();

      await gesture.moveTo(textOffsetToPosition(paragraph, 4));
      await tester.pump();
      expect(paragraph.selections[0], const TextSelection(baseOffset: 2, extentOffset: 4));

      await gesture.moveTo(textOffsetToPosition(paragraph, 6));
      await tester.pump();
      expect(paragraph.selections[0], const TextSelection(baseOffset: 2, extentOffset: 6));

      // Check backward selection.
      await gesture.moveTo(textOffsetToPosition(paragraph, 1));
      await tester.pump();
      expect(paragraph.selections[0], const TextSelection(baseOffset: 2, extentOffset: 1));

      // Start a new drag.
      await gesture.up();
      await gesture.down(textOffsetToPosition(paragraph, 5));
      expect(paragraph.selections.isEmpty, isTrue);

      // Selecting across line should select to the end.
      await gesture.moveTo(textOffsetToPosition(paragraph, 5) + const Offset(0.0, 200.0));
      await tester.pump();
      expect(paragraph.selections[0], const TextSelection(baseOffset: 5, extentOffset: 11));

      await gesture.up();
    });

    testWidgets('mouse can select multiple widgets', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SelectableRegion(
            focusNode: FocusNode(),
            selectionControls: materialTextSelectionControls,
            child: Column(
              children: const <Widget>[
                Text('How are you?'),
                Text('Good, and you?'),
                Text('Fine, thank you.'),
              ],
            ),
          ),
        ),
      );
      final RenderParagraph paragraph1 = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('How are you?'), matching: find.byType(RichText)));
      final TestGesture gesture = await tester.startGesture(textOffsetToPosition(paragraph1, 2), kind: PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);
      await tester.pump();

      await gesture.moveTo(textOffsetToPosition(paragraph1, 4));
      await tester.pump();
      expect(paragraph1.selections[0], const TextSelection(baseOffset: 2, extentOffset: 4));

      final RenderParagraph paragraph2 = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('Good, and you?'), matching: find.byType(RichText)));
      await gesture.moveTo(textOffsetToPosition(paragraph2, 5));
      // Should select the rest of paragraph 1.
      expect(paragraph1.selections[0], const TextSelection(baseOffset: 2, extentOffset: 12));
      expect(paragraph2.selections[0], const TextSelection(baseOffset: 0, extentOffset: 5));

      final RenderParagraph paragraph3 = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('Fine, thank you.'), matching: find.byType(RichText)));
      await gesture.moveTo(textOffsetToPosition(paragraph3, 6));
      expect(paragraph1.selections[0], const TextSelection(baseOffset: 2, extentOffset: 12));
      expect(paragraph2.selections[0], const TextSelection(baseOffset: 0, extentOffset: 14));
      expect(paragraph3.selections[0], const TextSelection(baseOffset: 0, extentOffset: 6));

      await gesture.up();
    });

    testWidgets('mouse can work with disabled container', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SelectableRegion(
            focusNode: FocusNode(),
            selectionControls: materialTextSelectionControls,
            child: Column(
              children: const <Widget>[
                Text('How are you?'),
                SelectionContainer.disabled(child: Text('Good, and you?')),
                Text('Fine, thank you.'),
              ],
            ),
          ),
        ),
      );
      final RenderParagraph paragraph1 = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('How are you?'), matching: find.byType(RichText)));
      final TestGesture gesture = await tester.startGesture(textOffsetToPosition(paragraph1, 2), kind: PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);
      await tester.pump();

      await gesture.moveTo(textOffsetToPosition(paragraph1, 4));
      await tester.pump();
      expect(paragraph1.selections[0], const TextSelection(baseOffset: 2, extentOffset: 4));

      final RenderParagraph paragraph2 = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('Good, and you?'), matching: find.byType(RichText)));
      await gesture.moveTo(textOffsetToPosition(paragraph2, 5));
      // Should select the rest of paragraph 1.
      expect(paragraph1.selections[0], const TextSelection(baseOffset: 2, extentOffset: 12));
      // paragraph2 is in a disabled container.
      expect(paragraph2.selections.isEmpty, isTrue);

      final RenderParagraph paragraph3 = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('Fine, thank you.'), matching: find.byType(RichText)));
      await gesture.moveTo(textOffsetToPosition(paragraph3, 6));
      expect(paragraph1.selections[0], const TextSelection(baseOffset: 2, extentOffset: 12));
      expect(paragraph2.selections.isEmpty, isTrue);
      expect(paragraph3.selections[0], const TextSelection(baseOffset: 0, extentOffset: 6));

      await gesture.up();
    });

    testWidgets('mouse can reverse selection', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SelectableRegion(
            focusNode: FocusNode(),
            selectionControls: materialTextSelectionControls,
            child: Column(
              children: const <Widget>[
                Text('How are you?'),
                Text('Good, and you?'),
                Text('Fine, thank you.'),
              ],
            ),
          ),
        ),
      );
      final RenderParagraph paragraph3 = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('Fine, thank you.'), matching: find.byType(RichText)));
      final TestGesture gesture = await tester.startGesture(textOffsetToPosition(paragraph3, 10), kind: PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);
      await tester.pump();

      await gesture.moveTo(textOffsetToPosition(paragraph3, 4));
      await tester.pump();
      expect(paragraph3.selections[0], const TextSelection(baseOffset: 10, extentOffset: 4));

      final RenderParagraph paragraph2 = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('Good, and you?'), matching: find.byType(RichText)));
      await gesture.moveTo(textOffsetToPosition(paragraph2, 5));
      expect(paragraph3.selections[0], const TextSelection(baseOffset: 10, extentOffset: 0));
      expect(paragraph2.selections[0], const TextSelection(baseOffset: 14, extentOffset: 5));

      final RenderParagraph paragraph1 = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('How are you?'), matching: find.byType(RichText)));
      await gesture.moveTo(textOffsetToPosition(paragraph1, 6));
      expect(paragraph3.selections[0], const TextSelection(baseOffset: 10, extentOffset: 0));
      expect(paragraph2.selections[0], const TextSelection(baseOffset: 14, extentOffset: 0));
      expect(paragraph1.selections[0], const TextSelection(baseOffset: 12, extentOffset: 6));

      await gesture.up();
    });

    testWidgets('can copy a selection made with the mouse', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SelectableRegion(
            focusNode: FocusNode(),
            selectionControls: materialTextSelectionControls,
            child: Column(
              children: const <Widget>[
                Text('How are you?'),
                Text('Good, and you?'),
                Text('Fine, thank you.'),
              ],
            ),
          ),
        ),
      );
      // Select from offset 2 of paragraph 1 to offset 6 of paragraph3.
      final RenderParagraph paragraph1 = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('How are you?'), matching: find.byType(RichText)));
      final TestGesture gesture = await tester.startGesture(textOffsetToPosition(paragraph1, 2), kind: PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);
      await tester.pump();

      final RenderParagraph paragraph3 = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('Fine, thank you.'), matching: find.byType(RichText)));
      await gesture.moveTo(textOffsetToPosition(paragraph3, 6));
      await gesture.up();

      // keyboard copy.
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyC);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyC);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);

      final Map<String, dynamic> clipboardData = mockClipboard.clipboardData as Map<String, dynamic>;
      expect(clipboardData['text'], 'w are you?Good, and you?Fine, ');
    }, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.android, TargetPlatform.windows, TargetPlatform.linux, TargetPlatform.fuchsia }));

    testWidgets(
      'does not override TextField keyboard shortcuts if the TextField is focused - non apple',
      (WidgetTester tester) async {
        final TextEditingController controller = TextEditingController(text: 'I am fine, thank you.');
        final FocusNode selectableRegionFocus = FocusNode();
        final FocusNode textFieldFocus = FocusNode();
        await tester.pumpWidget(
          MaterialApp(
            home: Material(
              child: SelectableRegion(
                focusNode: selectableRegionFocus,
                selectionControls: materialTextSelectionControls,
                child: Column(
                  children: <Widget>[
                    const Text('How are you?'),
                    const Text('Good, and you?'),
                    TextField(controller: controller, focusNode: textFieldFocus),
                  ],
                ),
              ),
            ),
          ),
        );
        textFieldFocus.requestFocus();
        await tester.pump();

        // Make sure keyboard select all works on TextField.
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.sendKeyDownEvent(LogicalKeyboardKey.keyA);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.keyA);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        expect(controller.selection, const TextSelection(baseOffset: 0, extentOffset: 21));

        // Make sure no selection in SelectableRegion.
        final RenderParagraph paragraph1 = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('How are you?'), matching: find.byType(RichText)));
        final RenderParagraph paragraph2 = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('Good, and you?'), matching: find.byType(RichText)));
        expect(paragraph1.selections.isEmpty, isTrue);
        expect(paragraph2.selections.isEmpty, isTrue);

        // Reset selection and focus selectable region.
        controller.selection = const TextSelection.collapsed(offset: -1);
        selectableRegionFocus.requestFocus();
        await tester.pump();

        // Make sure keyboard select all will be handled by selectable region now.
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.sendKeyDownEvent(LogicalKeyboardKey.keyA);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.keyA);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        expect(controller.selection, const TextSelection.collapsed(offset: -1));
        expect(paragraph2.selections[0], const TextSelection(baseOffset: 0, extentOffset: 14));
        expect(paragraph1.selections[0], const TextSelection(baseOffset: 0, extentOffset: 12));
      },
      variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.android, TargetPlatform.windows, TargetPlatform.linux, TargetPlatform.fuchsia }),
      skip: kIsWeb, // [intended] the web handles this on its own.
    );

    testWidgets(
      'does not override TextField keyboard shortcuts if the TextField is focused - apple',
      (WidgetTester tester) async {
        final TextEditingController controller = TextEditingController(text: 'I am fine, thank you.');
        final FocusNode selectableRegionFocus = FocusNode();
        final FocusNode textFieldFocus = FocusNode();
        await tester.pumpWidget(
          MaterialApp(
            home: Material(
              child: SelectableRegion(
                focusNode: selectableRegionFocus,
                selectionControls: materialTextSelectionControls,
                child: Column(
                  children: <Widget>[
                    const Text('How are you?'),
                    const Text('Good, and you?'),
                    TextField(controller: controller, focusNode: textFieldFocus),
                  ],
                ),
              ),
            ),
          ),
        );
        textFieldFocus.requestFocus();
        await tester.pump();

        // Make sure keyboard select all works on TextField.
        await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
        await tester.sendKeyDownEvent(LogicalKeyboardKey.keyA);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.keyA);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
        expect(controller.selection, const TextSelection(baseOffset: 0, extentOffset: 21));

        // Make sure no selection in SelectableRegion.
        final RenderParagraph paragraph1 = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('How are you?'), matching: find.byType(RichText)));
        final RenderParagraph paragraph2 = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('Good, and you?'), matching: find.byType(RichText)));
        expect(paragraph1.selections.isEmpty, isTrue);
        expect(paragraph2.selections.isEmpty, isTrue);

        // Reset selection and focus selectable region.
        controller.selection = const TextSelection.collapsed(offset: -1);
        selectableRegionFocus.requestFocus();
        await tester.pump();

        // Make sure keyboard select all will be handled by selectable region now.
        await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
        await tester.sendKeyDownEvent(LogicalKeyboardKey.keyA);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.keyA);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
        expect(controller.selection, const TextSelection.collapsed(offset: -1));
        expect(paragraph2.selections[0], const TextSelection(baseOffset: 0, extentOffset: 14));
        expect(paragraph1.selections[0], const TextSelection(baseOffset: 0, extentOffset: 12));
      },
      variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.iOS, TargetPlatform.macOS }),
      skip: kIsWeb, // [intended] the web handles this on its own.
    );

    testWidgets('select all', (WidgetTester tester) async {
      final FocusNode focusNode = FocusNode();
      await tester.pumpWidget(
        MaterialApp(
          home: SelectableRegion(
            focusNode: focusNode,
            selectionControls: materialTextSelectionControls,
            child: Column(
              children: const <Widget>[
                Text('How are you?'),
                Text('Good, and you?'),
                Text('Fine, thank you.'),
              ],
            ),
          ),
        ),
      );
      focusNode.requestFocus();

      // keyboard select all.
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyA);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyA);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);

      final RenderParagraph paragraph3 = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('Fine, thank you.'), matching: find.byType(RichText)));
      final RenderParagraph paragraph2 = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('Good, and you?'), matching: find.byType(RichText)));
      final RenderParagraph paragraph1 = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('How are you?'), matching: find.byType(RichText)));
      expect(paragraph3.selections[0], const TextSelection(baseOffset: 0, extentOffset: 16));
      expect(paragraph2.selections[0], const TextSelection(baseOffset: 0, extentOffset: 14));
      expect(paragraph1.selections[0], const TextSelection(baseOffset: 0, extentOffset: 12));
    }, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.android, TargetPlatform.windows, TargetPlatform.linux, TargetPlatform.fuchsia }));

    testWidgets(
      'mouse selection can handle widget span', (WidgetTester tester) async {
      final UniqueKey outerText = UniqueKey();
      await tester.pumpWidget(
        MaterialApp(
          home: SelectableRegion(
            focusNode: FocusNode(),
            selectionControls: materialTextSelectionControls,
            child: Center(
              child: Text.rich(
                const TextSpan(
                    children: <InlineSpan>[
                      TextSpan(text: 'How are you?'),
                      WidgetSpan(child: Text('Good, and you?')),
                      TextSpan(text: 'Fine, thank you.'),
                    ]
                ),
                key: outerText,
              ),
            ),
          ),
        ),
      );
      final RenderParagraph paragraph = tester.renderObject<RenderParagraph>(find.descendant(of: find.byKey(outerText), matching: find.byType(RichText)).first);
      final TestGesture gesture = await tester.startGesture(textOffsetToPosition(paragraph, 2), kind: PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);
      await tester.pump();
      await gesture.moveTo(textOffsetToPosition(paragraph, 17)); // right after `Fine`.
      await gesture.up();

      // keyboard copy.
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyC);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyC);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      final Map<String, dynamic> clipboardData = mockClipboard.clipboardData as Map<String, dynamic>;
      expect(clipboardData['text'], 'w are you?Good, and you?Fine');
    },
      variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.android, TargetPlatform.windows, TargetPlatform.linux, TargetPlatform.fuchsia }),
      skip: isBrowser, // https://github.com/flutter/flutter/issues/61020
    );

    testWidgets(
      'widget span is ignored if it does not contain text - non Apple',
      (WidgetTester tester) async {
        final UniqueKey outerText = UniqueKey();
        await tester.pumpWidget(
          MaterialApp(
            home: SelectableRegion(
              focusNode: FocusNode(),
              selectionControls: materialTextSelectionControls,
              child: Center(
                child: Text.rich(
                  const TextSpan(
                      children: <InlineSpan>[
                        TextSpan(text: 'How are you?'),
                        WidgetSpan(child: Placeholder()),
                        TextSpan(text: 'Fine, thank you.'),
                      ]
                  ),
                  key: outerText,
                ),
              ),
            ),
          ),
        );
        final RenderParagraph paragraph = tester.renderObject<RenderParagraph>(find.descendant(of: find.byKey(outerText), matching: find.byType(RichText)).first);
        final TestGesture gesture = await tester.startGesture(textOffsetToPosition(paragraph, 2), kind: PointerDeviceKind.mouse);
        addTearDown(gesture.removePointer);
        await tester.pump();
        await gesture.moveTo(textOffsetToPosition(paragraph, 17)); // right after `Fine`.
        await gesture.up();

        // keyboard copy.
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.sendKeyDownEvent(LogicalKeyboardKey.keyC);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.keyC);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        final Map<String, dynamic> clipboardData = mockClipboard.clipboardData as Map<String, dynamic>;
        expect(clipboardData['text'], 'w are you?Fine');
      },
      variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.android, TargetPlatform.windows, TargetPlatform.linux, TargetPlatform.fuchsia }),
      skip: isBrowser, // https://github.com/flutter/flutter/issues/61020
    );

    testWidgets(
      'widget span is ignored if it does not contain text - Apple',
          (WidgetTester tester) async {
        final UniqueKey outerText = UniqueKey();
        await tester.pumpWidget(
          MaterialApp(
            home: SelectableRegion(
              focusNode: FocusNode(),
              selectionControls: materialTextSelectionControls,
              child: Center(
                child: Text.rich(
                  const TextSpan(
                      children: <InlineSpan>[
                        TextSpan(text: 'How are you?'),
                        WidgetSpan(child: Placeholder()),
                        TextSpan(text: 'Fine, thank you.'),
                      ]
                  ),
                  key: outerText,
                ),
              ),
            ),
          ),
        );
        final RenderParagraph paragraph = tester.renderObject<RenderParagraph>(find.descendant(of: find.byKey(outerText), matching: find.byType(RichText)).first);
        final TestGesture gesture = await tester.startGesture(textOffsetToPosition(paragraph, 2), kind: PointerDeviceKind.mouse);
        addTearDown(gesture.removePointer);
        await tester.pump();
        await gesture.moveTo(textOffsetToPosition(paragraph, 17)); // right after `Fine`.
        await gesture.up();

        // keyboard copy.
        await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
        await tester.sendKeyDownEvent(LogicalKeyboardKey.keyC);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.keyC);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
        final Map<String, dynamic> clipboardData = mockClipboard.clipboardData as Map<String, dynamic>;
        expect(clipboardData['text'], 'w are you?Fine');
      },
      variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.iOS, TargetPlatform.macOS }),
      skip: isBrowser, // https://github.com/flutter/flutter/issues/61020
    );

    testWidgets('mouse can select across bidi text', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SelectableRegion(
            focusNode: FocusNode(),
            selectionControls: materialTextSelectionControls,
            child: Column(
              children: const <Widget>[
                Text('How are you?'),
                Text('جيد وانت؟', textDirection: TextDirection.rtl),
                Text('Fine, thank you.'),
              ],
            ),
          ),
        ),
      );
      final RenderParagraph paragraph1 = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('How are you?'), matching: find.byType(RichText)));
      final TestGesture gesture = await tester.startGesture(textOffsetToPosition(paragraph1, 2), kind: PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);
      await tester.pump();

      await gesture.moveTo(textOffsetToPosition(paragraph1, 4));
      await tester.pump();
      expect(paragraph1.selections[0], const TextSelection(baseOffset: 2, extentOffset: 4));

      final RenderParagraph paragraph2 = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('جيد وانت؟'), matching: find.byType(RichText)));
      await gesture.moveTo(textOffsetToPosition(paragraph2, 5));
      // Should select the rest of paragraph 1.
      expect(paragraph1.selections[0], const TextSelection(baseOffset: 2, extentOffset: 12));
      expect(paragraph2.selections[0], const TextSelection(baseOffset: 0, extentOffset: 5));

      final RenderParagraph paragraph3 = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('Fine, thank you.'), matching: find.byType(RichText)));
      // Add a little offset to cross the boundary between paragraph 2 and 3.
      await gesture.moveTo(textOffsetToPosition(paragraph3, 6) + const Offset(0, 1));
      expect(paragraph1.selections[0], const TextSelection(baseOffset: 2, extentOffset: 12));
      expect(paragraph2.selections[0], const TextSelection(baseOffset: 0, extentOffset: 8));
      expect(paragraph3.selections[0], const TextSelection(baseOffset: 0, extentOffset: 6));

      await gesture.up();
    }, skip: isBrowser); // https://github.com/flutter/flutter/issues/61020

    testWidgets('long press and drag touch selection', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SelectableRegion(
            focusNode: FocusNode(),
            selectionControls: materialTextSelectionControls,
            child: Column(
              children: const <Widget>[
                Text('How are you?'),
                Text('Good, and you?'),
                Text('Fine, thank you.'),
              ],
            ),
          ),
        ),
      );
      final RenderParagraph paragraph1 = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('How are you?'), matching: find.byType(RichText)));
      final TestGesture gesture = await tester.startGesture(textOffsetToPosition(paragraph1, 6)); // at the 'r'
      addTearDown(gesture.removePointer);
      await tester.pump(const Duration(milliseconds: 500));
      // `are` is selected.
      expect(paragraph1.selections[0], const TextSelection(baseOffset: 4, extentOffset: 7));

      final RenderParagraph paragraph2 = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('Good, and you?'), matching: find.byType(RichText)));
      await gesture.moveTo(textOffsetToPosition(paragraph2, 5));
      expect(paragraph1.selections[0], const TextSelection(baseOffset: 4, extentOffset: 12));
      expect(paragraph2.selections[0], const TextSelection(baseOffset: 0, extentOffset: 5));
      await gesture.up();
    });

    testWidgets('can drag end selection handle', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SelectableRegion(
            focusNode: FocusNode(),
            selectionControls: materialTextSelectionControls,
            child: Column(
              children: const <Widget>[
                Text('How are you?'),
                Text('Good, and you?'),
                Text('Fine, thank you.'),
              ],
            ),
          ),
        ),
      );
      final RenderParagraph paragraph1 = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('How are you?'), matching: find.byType(RichText)));
      final TestGesture gesture = await tester.startGesture(textOffsetToPosition(paragraph1, 6)); // at the 'r'
      addTearDown(gesture.removePointer);
      await tester.pump(const Duration(milliseconds: 500));
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 500));
      expect(paragraph1.selections[0], const TextSelection(baseOffset: 4, extentOffset: 7));
      final List<TextBox> boxes = paragraph1.getBoxesForSelection(paragraph1.selections[0]);
      expect(boxes.length, 1);

      final Offset handlePos = globalize(boxes[0].toRect().bottomRight, paragraph1);
      await gesture.down(handlePos);
      final RenderParagraph paragraph2 = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('Good, and you?'), matching: find.byType(RichText)));
      await gesture.moveTo(textOffsetToPosition(paragraph2, 5) + Offset(0, paragraph2.size.height / 2));
      expect(paragraph1.selections[0], const TextSelection(baseOffset: 4, extentOffset: 12));
      expect(paragraph2.selections[0], const TextSelection(baseOffset: 0, extentOffset: 5));

      final RenderParagraph paragraph3 = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('Fine, thank you.'), matching: find.byType(RichText)));
      await gesture.moveTo(textOffsetToPosition(paragraph3, 6) + Offset(0, paragraph3.size.height / 2));
      expect(paragraph1.selections[0], const TextSelection(baseOffset: 4, extentOffset: 12));
      expect(paragraph2.selections[0], const TextSelection(baseOffset: 0, extentOffset: 14));
      expect(paragraph3.selections[0], const TextSelection(baseOffset: 0, extentOffset: 6));
      await gesture.up();
    });

    testWidgets('can drag start selection handle', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SelectableRegion(
            focusNode: FocusNode(),
            selectionControls: materialTextSelectionControls,
            child: Column(
              children: const <Widget>[
                Text('How are you?'),
                Text('Good, and you?'),
                Text('Fine, thank you.'),
              ],
            ),
          ),
        ),
      );
      final RenderParagraph paragraph3 = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('Fine, thank you.'), matching: find.byType(RichText)));
      final TestGesture gesture = await tester.startGesture(textOffsetToPosition(paragraph3, 7)); // at the 'h'
      addTearDown(gesture.removePointer);
      await tester.pump(const Duration(milliseconds: 500));
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 500));
      expect(paragraph3.selections[0], const TextSelection(baseOffset: 6, extentOffset: 11));
      final List<TextBox> boxes = paragraph3.getBoxesForSelection(paragraph3.selections[0]);
      expect(boxes.length, 1);

      final Offset handlePos = globalize(boxes[0].toRect().bottomLeft, paragraph3);
      await gesture.down(handlePos);
      final RenderParagraph paragraph2 = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('Good, and you?'), matching: find.byType(RichText)));
      await gesture.moveTo(textOffsetToPosition(paragraph2, 5) + Offset(0, paragraph2.size.height / 2));
      expect(paragraph3.selections[0], const TextSelection(baseOffset: 0, extentOffset: 11));
      expect(paragraph2.selections[0], const TextSelection(baseOffset: 5, extentOffset: 14));

      final RenderParagraph paragraph1 = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('How are you?'), matching: find.byType(RichText)));
      await gesture.moveTo(textOffsetToPosition(paragraph1, 6) + Offset(0, paragraph1.size.height / 2));
      expect(paragraph3.selections[0], const TextSelection(baseOffset: 0, extentOffset: 11));
      expect(paragraph2.selections[0], const TextSelection(baseOffset: 0, extentOffset: 14));
      expect(paragraph1.selections[0], const TextSelection(baseOffset: 6, extentOffset: 12));
      await gesture.up();
    });

    testWidgets('can drag start selection handle across end selection handle', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SelectableRegion(
            focusNode: FocusNode(),
            selectionControls: materialTextSelectionControls,
            child: Column(
              children: const <Widget>[
                Text('How are you?'),
                Text('Good, and you?'),
                Text('Fine, thank you.'),
              ],
            ),
          ),
        ),
      );
      final RenderParagraph paragraph3 = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('Fine, thank you.'), matching: find.byType(RichText)));
      final TestGesture gesture = await tester.startGesture(textOffsetToPosition(paragraph3, 7)); // at the 'h'
      addTearDown(gesture.removePointer);
      await tester.pump(const Duration(milliseconds: 500));
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 500));
      expect(paragraph3.selections[0], const TextSelection(baseOffset: 6, extentOffset: 11));
      final List<TextBox> boxes = paragraph3.getBoxesForSelection(paragraph3.selections[0]);
      expect(boxes.length, 1);

      final Offset handlePos = globalize(boxes[0].toRect().bottomLeft, paragraph3);
      await gesture.down(handlePos);
      await gesture.moveTo(textOffsetToPosition(paragraph3, 14) + Offset(0, paragraph3.size.height / 2));
      expect(paragraph3.selections[0], const TextSelection(baseOffset: 14, extentOffset: 11));

      await gesture.moveTo(textOffsetToPosition(paragraph3, 4) + Offset(0, paragraph3.size.height / 2));
      expect(paragraph3.selections[0], const TextSelection(baseOffset: 4, extentOffset: 11));
      await gesture.up();
    });

    testWidgets('can drag end selection handle across start selection handle', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SelectableRegion(
            focusNode: FocusNode(),
            selectionControls: materialTextSelectionControls,
            child: Column(
              children: const <Widget>[
                Text('How are you?'),
                Text('Good, and you?'),
                Text('Fine, thank you.'),
              ],
            ),
          ),
        ),
      );
      final RenderParagraph paragraph3 = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('Fine, thank you.'), matching: find.byType(RichText)));
      final TestGesture gesture = await tester.startGesture(textOffsetToPosition(paragraph3, 7)); // at the 'h'
      addTearDown(gesture.removePointer);
      await tester.pump(const Duration(milliseconds: 500));
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 500));
      expect(paragraph3.selections[0], const TextSelection(baseOffset: 6, extentOffset: 11));
      final List<TextBox> boxes = paragraph3.getBoxesForSelection(paragraph3.selections[0]);
      expect(boxes.length, 1);

      final Offset handlePos = globalize(boxes[0].toRect().bottomRight, paragraph3);
      await gesture.down(handlePos);
      await gesture.moveTo(textOffsetToPosition(paragraph3, 4) + Offset(0, paragraph3.size.height / 2));
      expect(paragraph3.selections[0], const TextSelection(baseOffset: 6, extentOffset: 4));

      await gesture.moveTo(textOffsetToPosition(paragraph3, 12) + Offset(0, paragraph3.size.height / 2));
      expect(paragraph3.selections[0], const TextSelection(baseOffset: 6, extentOffset: 12));
      await gesture.up();
    });

    testWidgets('can select all from toolbar', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SelectableRegion(
            focusNode: FocusNode(),
            selectionControls: materialTextSelectionControls,
            child: Column(
              children: const <Widget>[
                Text('How are you?'),
                Text('Good, and you?'),
                Text('Fine, thank you.'),
              ],
            ),
          ),
        ),
      );
      final RenderParagraph paragraph3 = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('Fine, thank you.'), matching: find.byType(RichText)));
      final TestGesture gesture = await tester.startGesture(textOffsetToPosition(paragraph3, 7)); // at the 'h'
      addTearDown(gesture.removePointer);
      await tester.pump(const Duration(milliseconds: 500));
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 500));
      expect(paragraph3.selections[0], const TextSelection(baseOffset: 6, extentOffset: 11));
      expect(find.text('Select all'), findsOneWidget);

      await tester.tap(find.text('Select all'));
      await tester.pump();

      final RenderParagraph paragraph2 = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('Good, and you?'), matching: find.byType(RichText)));
      final RenderParagraph paragraph1 = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('How are you?'), matching: find.byType(RichText)));
      expect(paragraph3.selections[0], const TextSelection(baseOffset: 0, extentOffset: 16));
      expect(paragraph2.selections[0], const TextSelection(baseOffset: 0, extentOffset: 14));
      expect(paragraph1.selections[0], const TextSelection(baseOffset: 0, extentOffset: 12));
    }, skip: kIsWeb); // [intended] Web uses its native context menu.

    testWidgets('can copy from toolbar', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SelectableRegion(
            focusNode: FocusNode(),
            selectionControls: materialTextSelectionControls,
            child: Column(
              children: const <Widget>[
                Text('How are you?'),
                Text('Good, and you?'),
                Text('Fine, thank you.'),
              ],
            ),
          ),
        ),
      );
      final RenderParagraph paragraph3 = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('Fine, thank you.'), matching: find.byType(RichText)));
      final TestGesture gesture = await tester.startGesture(textOffsetToPosition(paragraph3, 7)); // at the 'h'
      addTearDown(gesture.removePointer);
      await tester.pump(const Duration(milliseconds: 500));
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 500));
      expect(paragraph3.selections[0], const TextSelection(baseOffset: 6, extentOffset: 11));
      expect(find.text('Copy'), findsOneWidget);

      await tester.tap(find.text('Copy'));
      await tester.pump();

      // Selection should be cleared.
      final RenderParagraph paragraph2 = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('Good, and you?'), matching: find.byType(RichText)));
      final RenderParagraph paragraph1 = tester.renderObject<RenderParagraph>(find.descendant(of: find.text('How are you?'), matching: find.byType(RichText)));
      expect(paragraph3.selections.isEmpty, isTrue);
      expect(paragraph2.selections.isEmpty, isTrue);
      expect(paragraph1.selections.isEmpty, isTrue);

      final Map<String, dynamic> clipboardData = mockClipboard.clipboardData as Map<String, dynamic>;
      expect(clipboardData['text'], 'thank');
    }, skip: kIsWeb); // [intended] Web uses its native context menu.
  });
}

class SelectionSpy extends LeafRenderObjectWidget {
  const SelectionSpy({
  super.key,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderSelectionSpy(
      SelectionContainer.maybeOf(context),
    );
  }

  @override
  void updateRenderObject(BuildContext context, covariant RenderObject renderObject) { }
}

class RenderSelectionSpy extends RenderProxyBox
    with Selectable, SelectionRegistrant {
  RenderSelectionSpy(
      SelectionRegistrar? registrar,
      ) {
    this.registrar = registrar;
  }

  final Set<VoidCallback> listeners = <VoidCallback>{};
  List<SelectionEvent> events = <SelectionEvent>[];

  @override
  void addListener(VoidCallback listener) => listeners.add(listener);

  @override
  void removeListener(VoidCallback listener) => listeners.remove(listener);

  @override
  SelectionResult dispatchSelectionEvent(SelectionEvent event) {
    events.add(event);
    return SelectionResult.end;
  }

  @override
  SelectedContent? getSelectedContent() {
    return const SelectedContent(plainText: 'content');
  }

  @override
  SelectionGeometry get value => _value;
  SelectionGeometry _value = SelectionGeometry(
    hasContent: true,
    status: SelectionStatus.uncollapsed,
    startSelectionPoint: const SelectionPoint(
      localPosition: Offset.zero,
      lineHeight: 0.0,
      handleType: TextSelectionHandleType.left,
    ),
    endSelectionPoint: const SelectionPoint(
      localPosition: Offset.zero,
      lineHeight: 0.0,
      handleType: TextSelectionHandleType.left,
    ),
  );
  set value(SelectionGeometry other) {
    if (other == _value) {
      return;
    }
    _value = other;
    for (final VoidCallback callback in listeners) {
      callback();
    }
  }

  @override
  void pushHandleLayers(LayerLink? startHandle, LayerLink? endHandle) { }
}


class TextTextSelectionControls extends TextSelectionControls {
  static final UniqueKey leftHandle = UniqueKey();
  static final UniqueKey rightHandle = UniqueKey();
  static final UniqueKey toolbar = UniqueKey();

  @override
  Size getHandleSize(double textLineHeight) => Size(textLineHeight, textLineHeight);

  @override
  Widget buildToolbar(
      BuildContext context,
      Rect globalEditableRegion,
      double textLineHeight,
      Offset selectionMidpoint,
      List<TextSelectionPoint> endpoints,
      TextSelectionDelegate delegate,
      ClipboardStatusNotifier? clipboardStatus,
      Offset? lastSecondaryTapDownPosition,
      ) {
    return TestToolbar(
      key: toolbar,
      globalEditableRegion: globalEditableRegion,
      textLineHeight: textLineHeight,
      selectionMidpoint: selectionMidpoint,
      endpoints: endpoints,
      delegate: delegate,
      clipboardStatus: clipboardStatus,
      lastSecondaryTapDownPosition: lastSecondaryTapDownPosition,
    );
  }

  @override
  Widget buildHandle(BuildContext context, TextSelectionHandleType type, double textHeight, [VoidCallback? onTap]) {
    return TestHandle(
      key: type == TextSelectionHandleType.left ? leftHandle : rightHandle,
      type: type,
      textHeight: textHeight,
    );
  }

  @override
  Offset getHandleAnchor(TextSelectionHandleType type, double textLineHeight) {
    return Offset.zero;
  }

  @override
  bool canSelectAll(TextSelectionDelegate delegate) => true;
}

class TestHandle extends StatelessWidget {
  const TestHandle({
  super.key,
  required this.type,
  required this.textHeight,
  });

  final TextSelectionHandleType type;
  final double textHeight;

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: textHeight, height: textHeight);
  }
}

class TestToolbar extends StatelessWidget {
  const TestToolbar({
  super.key,
  required this.globalEditableRegion,
  required this.textLineHeight,
  required this.selectionMidpoint,
  required this.endpoints,
  required this.delegate,
  required this.clipboardStatus,
  required this.lastSecondaryTapDownPosition,
  });

  final Rect globalEditableRegion;
  final double textLineHeight;
  final Offset selectionMidpoint;
  final List<TextSelectionPoint> endpoints;
  final TextSelectionDelegate delegate;
  final ClipboardStatusNotifier? clipboardStatus;
  final Offset? lastSecondaryTapDownPosition;

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: textLineHeight, height: textLineHeight);
  }
}
