// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'editable_text_utils.dart';

// TODO(justinmc): Convert these copied Scribble tests to Scribe if they're
// valuable, then make sure everything in EditableText's Scribe functionality is
// tested.
void main() {
  final TestWidgetsFlutterBinding binding = TestWidgetsFlutterBinding.ensureInitialized();

  // TODO(justinmc): Consider cleaning up this setup stuff.
  const TextStyle textStyle = TextStyle();
  const Color cursorColor = Color.fromARGB(0xFF, 0xFF, 0x00, 0x00);
  final List<MethodCall> calls = <MethodCall>[];
  bool isFeatureAvailableReturnValue = true;
  late TextEditingController controller;
  late FocusNode focusNode;

  setUp(() async {
    binding.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.scribe, (MethodCall methodCall) {
        calls.add(methodCall);

        return switch (methodCall.method) {
          'Scribe.isFeatureAvailable' => Future<bool>.value(isFeatureAvailableReturnValue),
          'Scribe.startStylusHandwriting' => Future<void>.value(),
          _=> throw FlutterError('Unexpected method call: ${methodCall.method}'),
        };
      });

    controller = TextEditingController(
      text: 'Lorem ipsum dolor sit amet',
    );
    focusNode = FocusNode(debugLabel: 'EditableText Node');
  });

  tearDown(() {
    controller.dispose();
    focusNode.dispose();
    calls.clear();
  });

  // TODO(justinmc): More test paths. Test: a non-stylus event. isStylusHandwritingAvailable false. hitting a collapsed handle. hitting the end handle non-collapsed. Hitting outside of the field.
  testWidgets('when Scribe is available, starts handwriting on tap down', (WidgetTester tester) async {
    isFeatureAvailableReturnValue = true;

    await tester.pumpWidget(
      MaterialApp(
        home: EditableText(
          controller: controller,
          backgroundCursorColor: Colors.grey,
          focusNode: focusNode,
          style: textStyle,
          cursorColor: cursorColor,
          selectionControls: materialTextSelectionControls,
        ),
      ),
    );

    expect(focusNode.hasFocus, isFalse);

    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.stylus, pointer: 1);
    await gesture.down(tester.getCenter(find.byType(EditableText)));

    expect(calls, hasLength(2));
    expect(calls.first.method, 'Scribe.isFeatureAvailable');
    expect(calls[1].method, 'Scribe.startStylusHandwriting');
    expect(focusNode.hasFocus, isTrue);

    await gesture.up();

    // On web, let the browser handle handwriting input.
  }, skip: kIsWeb, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.android })); // [intended]

  testWidgets('when Scribe is unavailable, does not start handwriting on tap down', (WidgetTester tester) async {
    isFeatureAvailableReturnValue = false;

    await tester.pumpWidget(
      MaterialApp(
        home: EditableText(
          controller: controller,
          backgroundCursorColor: Colors.grey,
          focusNode: focusNode,
          style: textStyle,
          cursorColor: cursorColor,
          selectionControls: materialTextSelectionControls,
        ),
      ),
    );

    expect(focusNode.hasFocus, isFalse);

    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.stylus, pointer: 1);
    await gesture.down(tester.getCenter(find.byType(EditableText)));

    expect(calls, hasLength(1));
    expect(calls.first.method, 'Scribe.isFeatureAvailable');

    await gesture.up();

    // On web, let the browser handle handwriting input.
  }, skip: kIsWeb, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.android })); // [intended]

  testWidgets('tap down event must be from a stylus in order to start handwriting', (WidgetTester tester) async {
    isFeatureAvailableReturnValue = true;

    await tester.pumpWidget(
      MaterialApp(
        home: EditableText(
          controller: controller,
          backgroundCursorColor: Colors.grey,
          focusNode: focusNode,
          style: textStyle,
          cursorColor: cursorColor,
          selectionControls: materialTextSelectionControls,
        ),
      ),
    );

    expect(focusNode.hasFocus, isFalse);

    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse, pointer: 1);
    await gesture.down(tester.getCenter(find.byType(EditableText)));

    expect(calls, isEmpty);

    await gesture.up();

    // On web, let the browser handle handwriting input.
  }, skip: kIsWeb, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.android })); // [intended]

  testWidgets('tap down event on a selection handle is handled by the handle and does not start handwriting', (WidgetTester tester) async {
    isFeatureAvailableReturnValue = true;

    await tester.pumpWidget(
      MaterialApp(
        home: EditableText(
          controller: controller,
          backgroundCursorColor: Colors.grey,
          focusNode: focusNode,
          style: textStyle,
          cursorColor: cursorColor,
          selectionControls: materialTextSelectionControls,
          showSelectionHandles: true,
        ),
      ),
    );

    expect(focusNode.hasFocus, isFalse);
    expect(find.byType(CompositedTransformFollower), findsNothing);

    // Tap to show the collapsed selection handle.
    final Offset fieldOffset = tester.getTopLeft(find.byType(EditableText));
    await tester.tapAt(fieldOffset + const Offset(20.0, 10.0));
    await tester.pump();
    expect(find.byType(CompositedTransformFollower), findsOneWidget);

    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.stylus, pointer: 1);
    final Finder handleFinder = find.descendant(
      of: find.byType(CompositedTransformFollower),
      matching: find.byType(CustomPaint),
    );
    await gesture.down(tester.getCenter(handleFinder));

    expect(calls, hasLength(1));
    expect(calls.first.method, 'Scribe.isFeatureAvailable');
    expect(controller.selection.isCollapsed, isTrue);
    final int cursorStart = controller.selection.start;

    // Dragging on top of the handle moves it like normal.
    await gesture.moveBy(const Offset(20.0, 0.0));
    expect(controller.selection.isCollapsed, isTrue);
    expect(controller.selection.start, greaterThan(cursorStart));
    expect(calls, hasLength(1));

    await gesture.up();

    // On web, let the browser handle handwriting input.
  }, skip: kIsWeb, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.android })); // [intended]

  // TODO(justinmc): Test that you can start handwriting in the padding outside of the field.

  /*
  testWidgets('Declares itself for Scribble interaction if the bounds overlap the scribble rect and the widget is touchable', (WidgetTester tester) async {
    controller.text = 'Lorem ipsum dolor sit amet';

    await tester.pumpWidget(
      MaterialApp(
        home: EditableText(
          controller: controller,
          backgroundCursorColor: Colors.grey,
          focusNode: focusNode,
          style: textStyle,
          cursorColor: cursorColor,
          selectionControls: materialTextSelectionControls,
        ),
      ),
    );

    final List<dynamic> elementEntry = <dynamic>[TextInput.scribbleClients.keys.first, 0.0, 0.0, 800.0, 600.0];

    List<List<dynamic>> elements = await tester.testTextInput.scribbleRequestElementsInRect(const Rect.fromLTWH(0, 0, 1, 1));
    expect(elements.first, containsAll(elementEntry));

    // Touch is outside the bounds of the widget.
    elements = await tester.testTextInput.scribbleRequestElementsInRect(const Rect.fromLTWH(-1, -1, 1, 1));
    expect(elements.length, 0);

    // Widget is read only.
    await tester.pumpWidget(
      MaterialApp(
        home: EditableText(
          readOnly: true,
          controller: controller,
          backgroundCursorColor: Colors.grey,
          focusNode: focusNode,
          style: textStyle,
          cursorColor: cursorColor,
          selectionControls: materialTextSelectionControls,
        ),
      ),
    );

    elements = await tester.testTextInput.scribbleRequestElementsInRect(const Rect.fromLTWH(0, 0, 1, 1));
    expect(elements.length, 0);

    // Widget is not touchable.
    await tester.pumpWidget(
      MaterialApp(
        home: Stack(children: <Widget>[
            EditableText(
              controller: controller,
              backgroundCursorColor: Colors.grey,
              focusNode: focusNode,
              style: textStyle,
              cursorColor: cursorColor,
              selectionControls: materialTextSelectionControls,
            ),
            Positioned(
              left: 0,
              top: 0,
              right: 0,
              bottom: 0,
              child: Container(color: Colors.black),
            ),
          ],
        ),
      ),
    );

    elements = await tester.testTextInput.scribbleRequestElementsInRect(const Rect.fromLTWH(0, 0, 1, 1));
    expect(elements.length, 0);

    // Widget has scribble disabled.
    await tester.pumpWidget(
      MaterialApp(
        home: EditableText(
          controller: controller,
          backgroundCursorColor: Colors.grey,
          focusNode: focusNode,
          style: textStyle,
          cursorColor: cursorColor,
          selectionControls: materialTextSelectionControls,
          scribbleEnabled: false,
        ),
      ),
    );

    elements = await tester.testTextInput.scribbleRequestElementsInRect(const Rect.fromLTWH(0, 0, 1, 1));
    expect(elements.length, 0);


    // On web, we should rely on the browser's implementation of Scribble, so the engine will
    // never request the scribble elements.
  }, skip: kIsWeb, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.iOS })); // [intended]

  testWidgets('single line Scribble fields can show a horizontal placeholder', (WidgetTester tester) async {
    controller.text = 'Lorem ipsum dolor sit amet';

    await tester.pumpWidget(
      MaterialApp(
        home: EditableText(
          controller: controller,
          backgroundCursorColor: Colors.grey,
          focusNode: focusNode,
          style: textStyle,
          cursorColor: cursorColor,
          selectionControls: materialTextSelectionControls,
        ),
      ),
    );

    await tester.showKeyboard(find.byType(EditableText));

    tester.testTextInput.updateEditingValue(TextEditingValue(
      text: controller.text,
      selection: const TextSelection(baseOffset: 5, extentOffset: 5),
    ));
    await tester.pumpAndSettle();

    await tester.testTextInput.scribbleInsertPlaceholder();
    await tester.pumpAndSettle();

    TextSpan textSpan = findRenderEditable(tester).text! as TextSpan;
    expect(textSpan.children!.length, 3);
    expect((textSpan.children![0] as TextSpan).text, 'Lorem');
    expect(textSpan.children![1] is WidgetSpan, true);
    expect((textSpan.children![2] as TextSpan).text, ' ipsum dolor sit amet');

    await tester.testTextInput.scribbleRemovePlaceholder();
    await tester.pumpAndSettle();

    textSpan = findRenderEditable(tester).text! as TextSpan;
    expect(textSpan.children, null);
    expect(textSpan.text, 'Lorem ipsum dolor sit amet');

    // Widget has scribble disabled.
    await tester.pumpWidget(
      MaterialApp(
        home: EditableText(
          controller: controller,
          backgroundCursorColor: Colors.grey,
          focusNode: focusNode,
          style: textStyle,
          cursorColor: cursorColor,
          selectionControls: materialTextSelectionControls,
          scribbleEnabled: false,
        ),
      ),
    );

    await tester.showKeyboard(find.byType(EditableText));

    tester.testTextInput.updateEditingValue(TextEditingValue(
      text: controller.text,
      selection: const TextSelection(baseOffset: 5, extentOffset: 5),
    ));
    await tester.pumpAndSettle();

    await tester.testTextInput.scribbleInsertPlaceholder();
    await tester.pumpAndSettle();

    textSpan = findRenderEditable(tester).text! as TextSpan;
    expect(textSpan.children, null);
    expect(textSpan.text, 'Lorem ipsum dolor sit amet');

    // On web, we should rely on the browser's implementation of Scribble, so the framework
    // will not handle placeholders.
  }, skip: kIsWeb, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.iOS })); // [intended]

  testWidgets('multiline Scribble fields can show a vertical placeholder', (WidgetTester tester) async {
    controller.text = 'Lorem ipsum dolor sit amet';

    await tester.pumpWidget(
      MaterialApp(
        home: EditableText(
          controller: controller,
          backgroundCursorColor: Colors.grey,
          focusNode: focusNode,
          style: textStyle,
          cursorColor: cursorColor,
          selectionControls: materialTextSelectionControls,
          maxLines: 2,
        ),
      ),
    );

    await tester.showKeyboard(find.byType(EditableText));

    tester.testTextInput.updateEditingValue(TextEditingValue(
      text: controller.text,
      selection: const TextSelection(baseOffset: 5, extentOffset: 5),
    ));
    await tester.pumpAndSettle();

    await tester.testTextInput.scribbleInsertPlaceholder();
    await tester.pumpAndSettle();

    TextSpan textSpan = findRenderEditable(tester).text! as TextSpan;
    expect(textSpan.children!.length, 4);
    expect((textSpan.children![0] as TextSpan).text, 'Lorem');
    expect(textSpan.children![1] is WidgetSpan, true);
    expect(textSpan.children![2] is WidgetSpan, true);
    expect((textSpan.children![3] as TextSpan).text, ' ipsum dolor sit amet');

    await tester.testTextInput.scribbleRemovePlaceholder();
    await tester.pumpAndSettle();

    textSpan = findRenderEditable(tester).text! as TextSpan;
    expect(textSpan.children, null);
    expect(textSpan.text, 'Lorem ipsum dolor sit amet');

    // Widget has scribble disabled.
    await tester.pumpWidget(
      MaterialApp(
        home: EditableText(
          controller: controller,
          backgroundCursorColor: Colors.grey,
          focusNode: focusNode,
          style: textStyle,
          cursorColor: cursorColor,
          selectionControls: materialTextSelectionControls,
          maxLines: 2,
          scribbleEnabled: false,
        ),
      ),
    );

    await tester.showKeyboard(find.byType(EditableText));

    tester.testTextInput.updateEditingValue(TextEditingValue(
      text: controller.text,
      selection: const TextSelection(baseOffset: 5, extentOffset: 5),
    ));
    await tester.pumpAndSettle();

    await tester.testTextInput.scribbleInsertPlaceholder();
    await tester.pumpAndSettle();

    textSpan = findRenderEditable(tester).text! as TextSpan;
    expect(textSpan.children, null);
    expect(textSpan.text, 'Lorem ipsum dolor sit amet');

    // On web, we should rely on the browser's implementation of Scribble, so the framework
    // will not handle placeholders.
  }, skip: kIsWeb, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.iOS })); // [intended]

  testWidgets('selection rects are sent when they change', (WidgetTester tester) async {
    addTearDown(tester.view.reset);
    // Ensure selection rects are sent on iPhone (using SE 3rd gen size)
    tester.view.physicalSize = const Size(750.0, 1334.0);

    final List<List<SelectionRect>> log = <List<SelectionRect>>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.textInput, (MethodCall methodCall) {
      if (methodCall.method == 'TextInput.setSelectionRects') {
        final List<dynamic> args = methodCall.arguments as List<dynamic>;
        final List<SelectionRect> selectionRects = <SelectionRect>[];
        for (final dynamic rect in args) {
          selectionRects.add(SelectionRect(
            position: (rect as List<dynamic>)[4] as int,
            bounds: Rect.fromLTWH(rect[0] as double, rect[1] as double, rect[2] as double, rect[3] as double),
          ));
        }
        log.add(selectionRects);
      }
      return null;
    });

    final ScrollController scrollController = ScrollController();
    addTearDown(scrollController.dispose);
    controller.text = 'Text1';

    Future<void> pumpEditableText({ double? width, double? height, TextAlign textAlign = TextAlign.start }) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: SizedBox(
                width: width,
                height: height,
                child: EditableText(
                  controller: controller,
                  textAlign: textAlign,
                  scrollController: scrollController,
                  maxLines: null,
                  focusNode: focusNode,
                  cursorWidth: 0,
                  style: Typography.material2018().black.titleMedium!,
                  cursorColor: Colors.blue,
                  backgroundCursorColor: Colors.grey,
                ),
              ),
            ),
          ),
        ),
      );
    }

    await pumpEditableText();
    expect(log, isEmpty);

    await tester.showKeyboard(find.byType(EditableText));
    // First update.
    expect(log.single, const <SelectionRect>[
      SelectionRect(position: 0, bounds: Rect.fromLTRB(0.0, 0.0, 14.0, 14.0)),
      SelectionRect(position: 1, bounds: Rect.fromLTRB(14.0, 0.0, 28.0, 14.0)),
      SelectionRect(position: 2, bounds: Rect.fromLTRB(28.0, 0.0, 42.0, 14.0)),
      SelectionRect(position: 3, bounds: Rect.fromLTRB(42.0, 0.0, 56.0, 14.0)),
      SelectionRect(position: 4, bounds: Rect.fromLTRB(56.0, 0.0, 70.0, 14.0))
    ]);
    log.clear();

    await tester.pumpAndSettle();
    expect(log, isEmpty);

    await pumpEditableText();
    expect(log, isEmpty);

    // Change the width such that each character occupies a line.
    await pumpEditableText(width: 20);
    expect(log.single, const <SelectionRect>[
      SelectionRect(position: 0, bounds: Rect.fromLTRB(0.0, 0.0, 14.0, 14.0)),
      SelectionRect(position: 1, bounds: Rect.fromLTRB(0.0, 14.0, 14.0, 28.0)),
      SelectionRect(position: 2, bounds: Rect.fromLTRB(0.0, 28.0, 14.0, 42.0)),
      SelectionRect(position: 3, bounds: Rect.fromLTRB(0.0, 42.0, 14.0, 56.0)),
      SelectionRect(position: 4, bounds: Rect.fromLTRB(0.0, 56.0, 14.0, 70.0))
    ]);
    log.clear();

    await tester.enterText(find.byType(EditableText), 'Text1👨‍👩‍👦');
    await tester.pump();
    expect(log.single, const <SelectionRect>[
      SelectionRect(position: 0, bounds: Rect.fromLTRB(0.0, 0.0, 14.0, 14.0)),
      SelectionRect(position: 1, bounds: Rect.fromLTRB(0.0, 14.0, 14.0, 28.0)),
      SelectionRect(position: 2, bounds: Rect.fromLTRB(0.0, 28.0, 14.0, 42.0)),
      SelectionRect(position: 3, bounds: Rect.fromLTRB(0.0, 42.0, 14.0, 56.0)),
      SelectionRect(position: 4, bounds: Rect.fromLTRB(0.0, 56.0, 14.0, 70.0)),
      SelectionRect(position: 5, bounds: Rect.fromLTRB(0.0, 70.0, 42.0, 84.0)),
    ]);
    log.clear();

    // The 4th line will be partially visible.
    await pumpEditableText(width: 20, height: 45);
    expect(log.single, const <SelectionRect>[
      SelectionRect(position: 0, bounds: Rect.fromLTRB(0.0, 0.0, 14.0, 14.0)),
      SelectionRect(position: 1, bounds: Rect.fromLTRB(0.0, 14.0, 14.0, 28.0)),
      SelectionRect(position: 2, bounds: Rect.fromLTRB(0.0, 28.0, 14.0, 42.0)),
      SelectionRect(position: 3, bounds: Rect.fromLTRB(0.0, 42.0, 14.0, 56.0)),
    ]);
    log.clear();

    await pumpEditableText(width: 20, height: 45, textAlign: TextAlign.right);
    // This is 1px off from being completely right-aligned. The 1px width is
    // reserved for caret.
    expect(log.single, const <SelectionRect>[
      SelectionRect(position: 0, bounds: Rect.fromLTRB(5.0, 0.0, 19.0, 14.0)),
      SelectionRect(position: 1, bounds: Rect.fromLTRB(5.0, 14.0, 19.0, 28.0)),
      SelectionRect(position: 2, bounds: Rect.fromLTRB(5.0, 28.0, 19.0, 42.0)),
      SelectionRect(position: 3, bounds: Rect.fromLTRB(5.0, 42.0, 19.0, 56.0)),
      // These 2 lines will be out of bounds.
      // SelectionRect(position: 4, bounds: Rect.fromLTRB(5.0, 56.0, 19.0, 70.0)),
      // SelectionRect(position: 5, bounds: Rect.fromLTRB(-23.0, 70.0, 19.0, 84.0)),
    ]);
    log.clear();

    expect(scrollController.offset, 0);

    // Scrolling also triggers update.
    scrollController.jumpTo(14);
    await tester.pumpAndSettle();
    expect(log.single, const <SelectionRect>[
      SelectionRect(position: 0, bounds: Rect.fromLTRB(5.0, -14.0, 19.0, 0.0)),
      SelectionRect(position: 1, bounds: Rect.fromLTRB(5.0, 0.0, 19.0, 14.0)),
      SelectionRect(position: 2, bounds: Rect.fromLTRB(5.0, 14.0, 19.0, 28.0)),
      SelectionRect(position: 3, bounds: Rect.fromLTRB(5.0, 28.0, 19.0, 42.0)),
      SelectionRect(position: 4, bounds: Rect.fromLTRB(5.0, 42.0, 19.0, 56.0)),
      // This line is skipped because it's below the bottom edge of the render
      // object.
      // SelectionRect(position: 5, bounds: Rect.fromLTRB(5.0, 56.0, 47.0, 70.0)),
    ]);
    log.clear();

    // On web, we should rely on the browser's implementation of Scribble, so we will not send selection rects.
  }, skip: kIsWeb, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.iOS })); // [intended]

  testWidgets('selection rects are not sent if scribbleEnabled is false', (WidgetTester tester) async {
    final List<MethodCall> log = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.textInput, (MethodCall methodCall) async {
      log.add(methodCall);
      return null;
    });

    controller.text = 'Text1';

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children:  <Widget>[
              EditableText(
                key: ValueKey<String>(controller.text),
                controller: controller,
                focusNode: focusNode,
                style: Typography.material2018().black.titleMedium!,
                cursorColor: Colors.blue,
                backgroundCursorColor: Colors.grey,
                scribbleEnabled: false,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.showKeyboard(find.byKey(ValueKey<String>(controller.text)));

    // There should be a new platform message updating the selection rects.
    expect(log.where((MethodCall m) => m.method == 'TextInput.setSelectionRects').length, 0);

    // On web, we should rely on the browser's implementation of Scribble, so we will not send selection rects.
  }, skip: kIsWeb, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.iOS })); // [intended]

  testWidgets('selection rects sent even when character corners are outside of paintBounds', (WidgetTester tester) async {
    final List<List<SelectionRect>> log = <List<SelectionRect>>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.textInput, (MethodCall methodCall) {
      if (methodCall.method == 'TextInput.setSelectionRects') {
        final List<dynamic> args = methodCall.arguments as List<dynamic>;
        final List<SelectionRect> selectionRects = <SelectionRect>[];
        for (final dynamic rect in args) {
          selectionRects.add(SelectionRect(
            position: (rect as List<dynamic>)[4] as int,
            bounds: Rect.fromLTWH(rect[0] as double, rect[1] as double, rect[2] as double, rect[3] as double),
          ));
        }
        log.add(selectionRects);
      }
      return null;
    });

    final ScrollController scrollController = ScrollController();
    addTearDown(scrollController.dispose);
    controller.text = 'Text1';

    final GlobalKey<EditableTextState> editableTextKey = GlobalKey();

    Future<void> pumpEditableText({ double? width, double? height, TextAlign textAlign = TextAlign.start }) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: SizedBox(
                width: width,
                height: height,
                child: EditableText(
                  controller: controller,
                  textAlign: textAlign,
                  scrollController: scrollController,
                  maxLines: null,
                  focusNode: focusNode,
                  cursorWidth: 0,
                  key: editableTextKey,
                  style: Typography.material2018().black.titleMedium!,
                  cursorColor: Colors.blue,
                  backgroundCursorColor: Colors.grey,
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Set height to 1 pixel less than full height.
    await pumpEditableText(height: 13);
    expect(log, isEmpty);

    // Scroll so that the top of each character is above the top of the renderEditable
    // and the bottom of each character is below the bottom of the renderEditable.
    final ViewportOffset offset = ViewportOffset.fixed(0.5);
    addTearDown(offset.dispose);
    editableTextKey.currentState!.renderEditable.offset = offset;

    await tester.showKeyboard(find.byType(EditableText));
    // We should get all the rects.
    expect(log.single, const <SelectionRect>[
      SelectionRect(position: 0, bounds: Rect.fromLTRB(0.0, -0.5, 14.0, 13.5)),
      SelectionRect(position: 1, bounds: Rect.fromLTRB(14.0, -0.5, 28.0, 13.5)),
      SelectionRect(position: 2, bounds: Rect.fromLTRB(28.0, -0.5, 42.0, 13.5)),
      SelectionRect(position: 3, bounds: Rect.fromLTRB(42.0, -0.5, 56.0, 13.5)),
      SelectionRect(position: 4, bounds: Rect.fromLTRB(56.0, -0.5, 70.0, 13.5))
    ]);
    log.clear();

    // On web, we should rely on the browser's implementation of Scribble, so we will not send selection rects.
  }, skip: kIsWeb, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.iOS })); // [intended]
  */
}
