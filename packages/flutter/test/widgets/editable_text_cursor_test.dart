// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file is run as part of a reduced test set in CI on Mac and Windows
// machines.
@Tags(<String>['reduced-test-set'])

@TestOn('!chrome')
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';
import 'editable_text_utils.dart';

final TextEditingController controller = TextEditingController();
final FocusNode focusNode = FocusNode();
final FocusScopeNode focusScopeNode = FocusScopeNode();
const TextStyle textStyle = TextStyle();
const Color cursorColor = Color.fromARGB(0xFF, 0xFF, 0x00, 0x00);

void main() {
  setUp(() async {
    // Fill the clipboard so that the Paste option is available in the text
    // selection menu.
    await Clipboard.setData(const ClipboardData(text: 'Clipboard data'));
  });

  testWidgets('cursor has expected width, height, and radius', (WidgetTester tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(devicePixelRatio: 1.0),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: EditableText(
            backgroundCursorColor: Colors.grey,
            controller: controller,
            focusNode: focusNode,
            style: textStyle,
            cursorColor: cursorColor,
            cursorWidth: 10.0,
            cursorHeight: 10.0,
            cursorRadius: const Radius.circular(2.0),
          ),
        ),
      ),
    );

    final EditableText editableText = tester.firstWidget(find.byType(EditableText));
    expect(editableText.cursorWidth, 10.0);
    expect(editableText.cursorHeight, 10.0);
    expect(editableText.cursorRadius!.x, 2.0);
  });

  testWidgets('cursor layout has correct width', (WidgetTester tester) async {
    EditableText.debugDeterministicCursor = true;
    final GlobalKey<EditableTextState> editableTextKey = GlobalKey<EditableTextState>();

    late String changedValue;
    final Widget widget = MaterialApp(
      home: RepaintBoundary(
        key: const ValueKey<int>(1),
        child: EditableText(
          backgroundCursorColor: Colors.grey,
          key: editableTextKey,
          controller: TextEditingController(),
          focusNode: FocusNode(),
          style: Typography.material2018(platform: TargetPlatform.android).black.subtitle1!,
          cursorColor: Colors.blue,
          selectionControls: materialTextSelectionControls,
          keyboardType: TextInputType.text,
          onChanged: (String value) {
            changedValue = value;
          },
          cursorWidth: 15.0,
        ),
      ),
    );
    await tester.pumpWidget(widget);

    // Populate a fake clipboard.
    const String clipboardContent = ' ';
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (MethodCall methodCall) async {
      if (methodCall.method == 'Clipboard.getData')
        return const <String, dynamic>{'text': clipboardContent};
      if (methodCall.method == 'Clipboard.hasStrings')
        return <String, dynamic>{'value': clipboardContent.isNotEmpty};
      return null;
    });

    // Long-press to bring up the text editing controls.
    final Finder textFinder = find.byKey(editableTextKey);
    await tester.longPress(textFinder);
    tester.state<EditableTextState>(textFinder).showToolbar();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Paste'));
    await tester.pump();

    expect(changedValue, clipboardContent);

    await expectLater(
      find.byKey(const ValueKey<int>(1)),
      matchesGoldenFile('editable_text_test.0.png'),
    );
    EditableText.debugDeterministicCursor = false;
  });

  testWidgets('cursor layout has correct radius', (WidgetTester tester) async {
    final GlobalKey<EditableTextState> editableTextKey = GlobalKey<EditableTextState>();

    late String changedValue;
    final Widget widget = MaterialApp(
      home: RepaintBoundary(
        key: const ValueKey<int>(1),
        child: EditableText(
          backgroundCursorColor: Colors.grey,
          key: editableTextKey,
          controller: TextEditingController(),
          focusNode: FocusNode(),
          style: Typography.material2018(platform: TargetPlatform.android).black.subtitle1!,
          cursorColor: Colors.blue,
          selectionControls: materialTextSelectionControls,
          keyboardType: TextInputType.text,
          onChanged: (String value) {
            changedValue = value;
          },
          cursorWidth: 15.0,
          cursorRadius: const Radius.circular(3.0),
        ),
      ),
    );
    await tester.pumpWidget(widget);

    // Populate a fake clipboard.
    const String clipboardContent = ' ';
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (MethodCall methodCall) async {
      if (methodCall.method == 'Clipboard.getData')
        return const <String, dynamic>{'text': clipboardContent};
      if (methodCall.method == 'Clipboard.hasStrings')
        return <String, dynamic>{'value': clipboardContent.isNotEmpty};
      return null;
    });

    // Long-press to bring up the text editing controls.
    final Finder textFinder = find.byKey(editableTextKey);
    await tester.longPress(textFinder);
    tester.state<EditableTextState>(textFinder).showToolbar();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Paste'));
    await tester.pump();

    expect(changedValue, clipboardContent);

    await expectLater(
      find.byKey(const ValueKey<int>(1)),
      matchesGoldenFile('editable_text_test.1.png'),
    );
  });

  testWidgets('Cursor animates', (WidgetTester tester) async {
    const Widget widget = MaterialApp(
      home: Material(
        child: TextField(
          maxLines: 3,
        ),
      ),
    );
    await tester.pumpWidget(widget);

    await tester.tap(find.byType(TextField));
    await tester.pump();

    final EditableTextState editableTextState = tester.firstState(find.byType(EditableText));
    final RenderEditable renderEditable = editableTextState.renderEditable;

    expect(renderEditable.cursorColor!.alpha, 255);

    // Trigger initial timer. When focusing the first time, the cursor shows
    // for slightly longer than the average on time.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    // Start timing standard cursor show period.
    expect(renderEditable.cursorColor!.alpha, 255);
    expect(renderEditable, paints..rrect(color: const Color(0xff2196f3)));

    await tester.pump(const Duration(milliseconds: 500));
    // Start to animate the cursor away.
    expect(renderEditable.cursorColor!.alpha, 255);
    expect(renderEditable, paints..rrect(color: const Color(0xff2196f3)));

    await tester.pump(const Duration(milliseconds: 100));
    expect(renderEditable.cursorColor!.alpha, 110);
    expect(renderEditable, paints..rrect(color: const Color(0x6e2196f3)));

    await tester.pump(const Duration(milliseconds: 100));
    expect(renderEditable.cursorColor!.alpha, 16);
    expect(renderEditable, paints..rrect(color: const Color(0x102196f3)));

    await tester.pump(const Duration(milliseconds: 100));
    expect(renderEditable.cursorColor!.alpha, 0);
    // Don't try to draw the cursor.
    expect(renderEditable, paintsExactlyCountTimes(#drawRRect, 0));

    // Wait some more while the cursor is gone. It'll trigger the cursor to
    // start animating in again.
    await tester.pump(const Duration(milliseconds: 300));
    expect(renderEditable.cursorColor!.alpha, 0);
    expect(renderEditable, paintsExactlyCountTimes(#drawRRect, 0));

    await tester.pump(const Duration(milliseconds: 50));
    // Cursor starts coming back.
    expect(renderEditable.cursorColor!.alpha, 79);
    expect(renderEditable, paints..rrect(color: const Color(0x4f2196f3)));
  }, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.iOS,  TargetPlatform.macOS }));

  testWidgets('Cursor does not animate on Android', (WidgetTester tester) async {
    final Color defaultCursorColor = Color(ThemeData.fallback().colorScheme.primary.value);
    const Widget widget = MaterialApp(
      home: Material(
        child: TextField(
          maxLines: 3,
        ),
      ),
    );
    await tester.pumpWidget(widget);

    await tester.tap(find.byType(TextField));
    await tester.pump();

    final EditableTextState editableTextState = tester.firstState(find.byType(EditableText));
    final RenderEditable renderEditable = editableTextState.renderEditable;

    await tester.pump();
    expect(renderEditable.cursorColor!.alpha, 255);
    expect(renderEditable, paints..rect(color: defaultCursorColor));

    // Android cursor goes from exactly on to exactly off on the 500ms dot.
    await tester.pump(const Duration(milliseconds: 499));
    expect(renderEditable.cursorColor!.alpha, 255);
    expect(renderEditable, paints..rect(color: defaultCursorColor));

    await tester.pump(const Duration(milliseconds: 1));
    expect(renderEditable.cursorColor!.alpha, 0);
    // Don't try to draw the cursor.
    expect(renderEditable, paintsExactlyCountTimes(#drawRect, 0));

    await tester.pump(const Duration(milliseconds: 500));
    expect(renderEditable.cursorColor!.alpha, 255);
    expect(renderEditable, paints..rect(color: defaultCursorColor));

    await tester.pump(const Duration(milliseconds: 500));
    expect(renderEditable.cursorColor!.alpha, 0);
    expect(renderEditable, paintsExactlyCountTimes(#drawRect, 0));
  });

  testWidgets('Cursor does not animates when debugDeterministicCursor is set', (WidgetTester tester) async {
    EditableText.debugDeterministicCursor = true;
    final Color defaultCursorColor = Color(ThemeData.fallback().colorScheme.primary.value);
    const Widget widget = MaterialApp(
      home: Material(
        child: TextField(
          maxLines: 3,
        ),
      ),
    );
    await tester.pumpWidget(widget);

    await tester.tap(find.byType(TextField));
    await tester.pump();

    final EditableTextState editableTextState = tester.firstState(find.byType(EditableText));
    final RenderEditable renderEditable = editableTextState.renderEditable;

    expect(renderEditable.cursorColor!.alpha, 255);

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(renderEditable.cursorColor!.alpha, 255);
    expect(renderEditable, paints..rrect(color: defaultCursorColor));

    // Cursor draw never changes.
    await tester.pump(const Duration(milliseconds: 200));
    expect(renderEditable.cursorColor!.alpha, 255);
    expect(renderEditable, paints..rrect(color: defaultCursorColor));

    // No more transient calls.
    await tester.pumpAndSettle();
    expect(renderEditable.cursorColor!.alpha, 255);
    expect(renderEditable, paints..rrect(color: defaultCursorColor));

    EditableText.debugDeterministicCursor = false;
  }, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.iOS,  TargetPlatform.macOS }));

  testWidgets('Cursor does not animate on Android when debugDeterministicCursor is set', (WidgetTester tester) async {
    final Color defaultCursorColor = Color(ThemeData.fallback().colorScheme.primary.value);
    EditableText.debugDeterministicCursor = true;
    const Widget widget = MaterialApp(
      home: Material(
        child: TextField(
          maxLines: 3,
        ),
      ),
    );
    await tester.pumpWidget(widget);

    await tester.tap(find.byType(TextField));
    await tester.pump();

    final EditableTextState editableTextState = tester.firstState(find.byType(EditableText));
    final RenderEditable renderEditable = editableTextState.renderEditable;

    await tester.pump();
    expect(renderEditable.cursorColor!.alpha, 255);
    expect(renderEditable, paints..rect(color: defaultCursorColor));

    await tester.pump(const Duration(milliseconds: 500));
    expect(renderEditable.cursorColor!.alpha, 255);
    expect(renderEditable, paints..rect(color: defaultCursorColor));

    // Cursor draw never changes.
    await tester.pump(const Duration(milliseconds: 500));
    expect(renderEditable.cursorColor!.alpha, 255);
    expect(renderEditable, paints..rect(color: defaultCursorColor));

    // No more transient calls.
    await tester.pumpAndSettle();
    expect(renderEditable.cursorColor!.alpha, 255);
    expect(renderEditable, paints..rect(color: defaultCursorColor));

    EditableText.debugDeterministicCursor = false;
  });

  testWidgets('Cursor animation restarts when it is moved using keys on desktop', (WidgetTester tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;

    const String testText = 'Some text long enough to move the cursor around';
    final TextEditingController controller = TextEditingController(text: testText);
    final Widget widget = MaterialApp(
      home: EditableText(
        controller: controller,
        focusNode: FocusNode(),
        style: const TextStyle(fontSize: 20.0),
        maxLines: 1,
        cursorColor: Colors.blue,
        backgroundCursorColor: Colors.grey,
        cursorOpacityAnimates: false,
        selectionControls: materialTextSelectionControls,
        keyboardType: TextInputType.text,
        textAlign: TextAlign.left,
      ),
    );
    await tester.pumpWidget(widget);

    await tester.tap(find.byType(EditableText));
    await tester.pump();

    final EditableTextState editableTextState = tester.firstState(find.byType(EditableText));
    final RenderEditable renderEditable = editableTextState.renderEditable;

    await tester.pump();
    expect(renderEditable.cursorColor!.alpha, 255);
    expect(renderEditable, paints..rect(color: const Color(0xff2196f3)));

    // Android cursor goes from exactly on to exactly off on the 500ms dot.
    await tester.pump(const Duration(milliseconds: 499));
    expect(renderEditable.cursorColor!.alpha, 255);
    expect(renderEditable, paints..rect(color: const Color(0xff2196f3)));

    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowLeft);

    await tester.pump();
    expect(renderEditable.cursorColor!.alpha, 255);
    expect(renderEditable, paints..rect(color: const Color(0xff2196f3)));

    await tester.pump(const Duration(milliseconds: 200));
    expect(renderEditable.cursorColor!.alpha, 255);
    expect(renderEditable, paints..rect(color: const Color(0xff2196f3)));

    await tester.pump(const Duration(milliseconds: 299));
    expect(renderEditable.cursorColor!.alpha, 255);
    expect(renderEditable, paints..rect(color: const Color(0xff2196f3)));

    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);

    await tester.pump();
    expect(renderEditable.cursorColor!.alpha, 255);
    expect(renderEditable, paints..rect(color: const Color(0xff2196f3)));

    await tester.pump(const Duration(milliseconds: 200));
    expect(renderEditable.cursorColor!.alpha, 255);
    expect(renderEditable, paints..rect(color: const Color(0xff2196f3)));

    await tester.pump(const Duration(milliseconds: 299));
    expect(renderEditable.cursorColor!.alpha, 255);
    expect(renderEditable, paints..rect(color: const Color(0xff2196f3)));

    await tester.pump(const Duration(milliseconds: 1));
    expect(renderEditable.cursorColor!.alpha, 0);
    expect(renderEditable, paintsExactlyCountTimes(#drawRect, 0));

    debugDefaultTargetPlatformOverride = null;
  }, variant: KeySimulatorTransitModeVariant.all());

  testWidgets('Cursor does not show when showCursor set to false', (WidgetTester tester) async {
    const Widget widget = MaterialApp(
      home: Material(
        child: TextField(
          showCursor: false,
          maxLines: 3,
        ),
      ),
    );
    await tester.pumpWidget(widget);

    await tester.tap(find.byType(TextField));
    await tester.pump();

    final EditableTextState editableTextState = tester.firstState(find.byType(EditableText));
    final RenderEditable renderEditable = editableTextState.renderEditable;

    // Make sure it does not paint for a period of time.
    await tester.pump(const Duration(milliseconds: 200));
    expect(renderEditable, paintsExactlyCountTimes(#drawRect, 0));

    await tester.pump(const Duration(milliseconds: 200));
    expect(renderEditable, paintsExactlyCountTimes(#drawRect, 0));

    await tester.pump(const Duration(milliseconds: 200));
    expect(renderEditable, paintsExactlyCountTimes(#drawRect, 0));
  });

  testWidgets('Cursor radius is 2.0', (WidgetTester tester) async {
    const Widget widget = MaterialApp(
      home: Material(
        child: TextField(
          maxLines: 3,
        ),
      ),
    );
    await tester.pumpWidget(widget);

    final EditableTextState editableTextState = tester.firstState(find.byType(EditableText));
    final RenderEditable renderEditable = editableTextState.renderEditable;

    expect(renderEditable.cursorRadius, const Radius.circular(2.0));
  }, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.iOS,  TargetPlatform.macOS }));

  testWidgets('Cursor gets placed correctly after going out of bounds', (WidgetTester tester) async {
    const String text = 'hello world this is fun and cool and awesome!';
    controller.text = text;
    final FocusNode focusNode = FocusNode();

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(devicePixelRatio: 1),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: FocusScope(
            node: focusScopeNode,
            autofocus: true,
            child: EditableText(
              backgroundCursorColor: Colors.grey,
              controller: controller,
              focusNode: focusNode,
              style: textStyle,
              cursorColor: cursorColor,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(EditableText));
    final RenderEditable renderEditable = findRenderEditable(tester);
    renderEditable.selection = const TextSelection(baseOffset: 29, extentOffset: 29);

    expect(controller.selection.baseOffset, 29);

    final EditableTextState editableTextState = tester.firstState(find.byType(EditableText));

    // Sets the origin.
    editableTextState.updateFloatingCursor(RawFloatingCursorPoint(state: FloatingCursorDragState.Start, offset: const Offset(20, 20)));

    expect(controller.selection.baseOffset, 29);

    // Moves the cursor super far right
    editableTextState.updateFloatingCursor(RawFloatingCursorPoint(
      state: FloatingCursorDragState.Update,
      offset: const Offset(2090, 20),
    ));
    editableTextState.updateFloatingCursor(RawFloatingCursorPoint(
      state: FloatingCursorDragState.Update,
      offset: const Offset(2100, 20),
    ));
    editableTextState.updateFloatingCursor(RawFloatingCursorPoint(
      state: FloatingCursorDragState.Update,
      offset: const Offset(2090, 20),
    ));

    // After peaking the cursor, we move in the opposite direction.
    editableTextState.updateFloatingCursor(RawFloatingCursorPoint(
      state: FloatingCursorDragState.Update,
      offset: const Offset(1400, 20),
    ));

    editableTextState.updateFloatingCursor(RawFloatingCursorPoint(state: FloatingCursorDragState.End));

    await tester.pumpAndSettle();
    // The cursor has been set.
    expect(controller.selection.baseOffset, 8);

    // Go in the other direction.

    // Sets the origin.
    editableTextState.updateFloatingCursor(RawFloatingCursorPoint(state: FloatingCursorDragState.Start, offset: const Offset(20, 20)));

    editableTextState.updateFloatingCursor(RawFloatingCursorPoint(
      state: FloatingCursorDragState.Update,
      offset: const Offset(-5000, 20),
    ));
    editableTextState.updateFloatingCursor(RawFloatingCursorPoint(
      state: FloatingCursorDragState.Update,
      offset: const Offset(-5010, 20),
    ));
    editableTextState.updateFloatingCursor(RawFloatingCursorPoint(
      state: FloatingCursorDragState.Update,
      offset: const Offset(-5000, 20),
    ));

    // Move back in the opposite direction only a few hundred.
    editableTextState.updateFloatingCursor(RawFloatingCursorPoint(
      state: FloatingCursorDragState.Update,
      offset: const Offset(-4850, 20),
    ));

    editableTextState.updateFloatingCursor(RawFloatingCursorPoint(state: FloatingCursorDragState.End));

    await tester.pumpAndSettle();

    expect(controller.selection.baseOffset, 10);
  });

  testWidgets('Updating the floating cursor correctly moves the cursor', (WidgetTester tester) async {
    const String text = 'hello world this is fun and cool and awesome!';
    controller.text = text;
    final FocusNode focusNode = FocusNode();

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(devicePixelRatio: 1),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: FocusScope(
            node: focusScopeNode,
            autofocus: true,
            child: EditableText(
              backgroundCursorColor: Colors.grey,
              controller: controller,
              focusNode: focusNode,
              style: textStyle,
              cursorColor: cursorColor,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(EditableText));
    final RenderEditable renderEditable = findRenderEditable(tester);
    renderEditable.selection = const TextSelection(baseOffset: 29, extentOffset: 29);

    expect(controller.selection.baseOffset, 29);

    final EditableTextState editableTextState = tester.firstState(find.byType(EditableText));

    // Sets the origin.
    editableTextState.updateFloatingCursor(RawFloatingCursorPoint(
      state: FloatingCursorDragState.Start,
      offset: const Offset(20, 20),
    ));

    expect(controller.selection.baseOffset, 29);

    // Moves the cursor right a few characters.
    editableTextState.updateFloatingCursor(RawFloatingCursorPoint(
      state: FloatingCursorDragState.Update,
      offset: const Offset(-250, 20),
    ));

    // But we have not yet set the offset because the user is not done placing the cursor.
    expect(controller.selection.baseOffset, 29);

    editableTextState.updateFloatingCursor(RawFloatingCursorPoint(state: FloatingCursorDragState.End));

    await tester.pumpAndSettle();
    // The cursor has been set.
    expect(controller.selection.baseOffset, 10);
  });

  testWidgets('Updating the floating cursor can end without update', (WidgetTester tester) async {
    const String text = 'hello world this is fun and cool and awesome!';
    controller.text = text;
    final FocusNode focusNode = FocusNode();

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(devicePixelRatio: 1),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: FocusScope(
            node: focusScopeNode,
            autofocus: true,
            child: EditableText(
              backgroundCursorColor: Colors.grey,
              controller: controller,
              focusNode: focusNode,
              style: textStyle,
              cursorColor: cursorColor,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(EditableText));
    final RenderEditable renderEditable = findRenderEditable(tester);
    renderEditable.selection = const TextSelection(baseOffset: 29, extentOffset: 29);

    expect(controller.selection.baseOffset, 29);

    final EditableTextState editableTextState = tester.firstState(find.byType(EditableText));
    editableTextState.updateFloatingCursor(RawFloatingCursorPoint(state: FloatingCursorDragState.Start));

    expect(controller.selection.baseOffset, 29);

    editableTextState.updateFloatingCursor(RawFloatingCursorPoint(state: FloatingCursorDragState.End));

    await tester.pumpAndSettle();
    // The cursor did not change.
    expect(controller.selection.baseOffset, 29);
    expect(tester.takeException(), null);
  });

  // Regression test for https://github.com/flutter/flutter/pull/30475.
  testWidgets('Trying to select with the floating cursor does not crash', (WidgetTester tester) async {
    const String text = 'hello world this is fun and cool and awesome!';
    controller.text = text;
    final FocusNode focusNode = FocusNode();

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(devicePixelRatio: 1),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: FocusScope(
            node: focusScopeNode,
            autofocus: true,
            child: EditableText(
              backgroundCursorColor: Colors.grey,
              controller: controller,
              focusNode: focusNode,
              style: textStyle,
              cursorColor: cursorColor,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(EditableText));
    final RenderEditable renderEditable = findRenderEditable(tester);
    renderEditable.selection = const TextSelection(baseOffset: 29, extentOffset: 29);

    expect(controller.selection.baseOffset, 29);

    final EditableTextState editableTextState = tester.firstState(find.byType(EditableText));

    // Sets the origin.
    editableTextState.updateFloatingCursor(RawFloatingCursorPoint(
      state: FloatingCursorDragState.Start,
      offset: const Offset(20, 20),
    ));

    expect(controller.selection.baseOffset, 29);

    // Moves the cursor right a few characters.
    editableTextState.updateFloatingCursor(RawFloatingCursorPoint(
      state: FloatingCursorDragState.Update,
      offset: const Offset(-250, 20),
    ));

    // But we have not yet set the offset because the user is not done placing the cursor.
    expect(controller.selection.baseOffset, 29);

    editableTextState.updateFloatingCursor(RawFloatingCursorPoint(state: FloatingCursorDragState.End));
    // Immediately start a new floating cursor, in the same way as happens when
    // the user tries to select text in trackpad mode.
    editableTextState.updateFloatingCursor(RawFloatingCursorPoint(state: FloatingCursorDragState.Start, offset: const Offset(20, 20)));
    await tester.pumpAndSettle();

    // Set and move the second cursor like a selection. Previously, the second
    // Update here caused a crash.
    editableTextState.updateFloatingCursor(RawFloatingCursorPoint(
      state: FloatingCursorDragState.Update,
      offset: const Offset(-250, 20),
    ));
    editableTextState.updateFloatingCursor(RawFloatingCursorPoint(state: FloatingCursorDragState.End));
    await tester.pumpAndSettle();
  });

  testWidgets('autofocus sets cursor to the end of text', (WidgetTester tester) async {
    const String text = 'hello world';
    final FocusScopeNode focusScopeNode = FocusScopeNode();
    final FocusNode focusNode = FocusNode();

    controller.text = text;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(devicePixelRatio: 1.0),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: FocusScope(
            node: focusScopeNode,
            autofocus: true,
            child: EditableText(
              backgroundCursorColor: Colors.grey,
              controller: controller,
              focusNode: focusNode,
              autofocus: true,
              style: textStyle,
              cursorColor: cursorColor,
            ),
          ),
        ),
      ),
    );

    expect(focusNode.hasFocus, true);
    expect(controller.selection.isCollapsed, true);
    expect(controller.selection.baseOffset, text.length);
  });

  testWidgets('Floating cursor is painted', (WidgetTester tester) async {
    final TextEditingController controller = TextEditingController();
    const TextStyle textStyle = TextStyle();
    const String text = 'hello world this is fun and cool and awesome!';
    controller.text = text;
    final FocusNode focusNode = FocusNode();

    await tester.pumpWidget(
      MaterialApp(
        home: Padding(
          padding: const EdgeInsets.only(top: 0.25),
          child: Material(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              style: textStyle,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(EditableText));
    final RenderEditable editable = findRenderEditable(tester);
    editable.selection = const TextSelection(baseOffset: 29, extentOffset: 29);

    final EditableTextState editableTextState = tester.firstState(find.byType(EditableText));
    editableTextState.updateFloatingCursor(
      RawFloatingCursorPoint(state: FloatingCursorDragState.Start, offset: const Offset(20, 20)),
    );
    await tester.pump();

    expect(editable, paints
      ..rrect(
        rrect: RRect.fromRectAndRadius(
          const Rect.fromLTRB(463.3333435058594, -0.916666666666668, 465.3333435058594, 17.083333015441895),
          const Radius.circular(2.0),
        ),
        color: const Color(0xff999999),
      )
      ..rrect(
        rrect: RRect.fromRectAndRadius(
          const Rect.fromLTRB(463.8333435058594, -0.916666666666668, 466.8333435058594, 19.083333969116211),
          const Radius.circular(1.0),
        ),
        color: const Color(0xbf2196f3),
      ),
    );

    // Moves the cursor right a few characters.
    editableTextState.updateFloatingCursor(
      RawFloatingCursorPoint(
        state: FloatingCursorDragState.Update,
        offset: const Offset(-250, 20),
      ),
    );

    expect(find.byType(EditableText), paints
      ..rrect(
        rrect: RRect.fromRectAndRadius(
          const Rect.fromLTRB(191.3333282470703, -0.916666666666668, 193.3333282470703, 17.083333015441895),
          const Radius.circular(2.0),
        ),
        color: const Color(0xff999999),
      )
      ..rrect(
        rrect: RRect.fromRectAndRadius(
          const Rect.fromLTRB(193.83334350585938, -0.916666666666668, 196.83334350585938, 19.083333969116211),
          const Radius.circular(1.0),
        ),
        color: const Color(0xbf2196f3),
      ),
    );

    editableTextState.updateFloatingCursor(RawFloatingCursorPoint(state: FloatingCursorDragState.End));
    await tester.pumpAndSettle();
    debugDefaultTargetPlatformOverride = null;
  }, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.iOS,  TargetPlatform.macOS }));

  testWidgets('cursor layout', (WidgetTester tester) async {
    EditableText.debugDeterministicCursor = true;
    final GlobalKey<EditableTextState> editableTextKey = GlobalKey<EditableTextState>();

    late String changedValue;
    final Widget widget = MaterialApp(
      home: RepaintBoundary(
        key: const ValueKey<int>(1),
        child: Column(
          children: <Widget>[
            const SizedBox(width: 10, height: 10),
            EditableText(
              backgroundCursorColor: Colors.grey,
              key: editableTextKey,
              controller: TextEditingController(),
              focusNode: FocusNode(),
              style: Typography.material2018(platform: TargetPlatform.iOS).black.subtitle1!,
              cursorColor: Colors.blue,
              selectionControls: materialTextSelectionControls,
              keyboardType: TextInputType.text,
              onChanged: (String value) {
                changedValue = value;
              },
              cursorWidth: 15.0,
            ),
          ],
        ),
      ),
    );
    await tester.pumpWidget(widget);

    // Populate a fake clipboard.
    const String clipboardContent = 'Hello world!';
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (MethodCall methodCall) async {
      if (methodCall.method == 'Clipboard.getData')
        return const <String, dynamic>{'text': clipboardContent};
      if (methodCall.method == 'Clipboard.hasStrings')
        return <String, dynamic>{'value': clipboardContent.isNotEmpty};
      return null;
    });

    // Long-press to bring up the text editing controls.
    final Finder textFinder = find.byKey(editableTextKey);
    await tester.longPress(textFinder);
    tester.state<EditableTextState>(textFinder).showToolbar();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Paste'));
    await tester.pump();

    expect(changedValue, clipboardContent);

    await expectLater(
      find.byKey(const ValueKey<int>(1)),
      matchesGoldenFile('editable_text_test.2.png'),
    );
    EditableText.debugDeterministicCursor = false;
  }, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.iOS,  TargetPlatform.macOS }));

  testWidgets('cursor layout has correct height', (WidgetTester tester) async {
    EditableText.debugDeterministicCursor = true;
    final GlobalKey<EditableTextState> editableTextKey = GlobalKey<EditableTextState>();

    late String changedValue;
    final Widget widget = MaterialApp(
      home: RepaintBoundary(
        key: const ValueKey<int>(1),
        child: Column(
          children: <Widget>[
            const SizedBox(width: 10, height: 10),
            EditableText(
              backgroundCursorColor: Colors.grey,
              key: editableTextKey,
              controller: TextEditingController(),
              focusNode: FocusNode(),
              style: Typography.material2018(platform: TargetPlatform.iOS).black.subtitle1!,
              cursorColor: Colors.blue,
              selectionControls: materialTextSelectionControls,
              keyboardType: TextInputType.text,
              onChanged: (String value) {
                changedValue = value;
              },
              cursorWidth: 15.0,
              cursorHeight: 30.0,
            ),
          ],
        ),
      ),
    );
    await tester.pumpWidget(widget);

    // Populate a fake clipboard.
    const String clipboardContent = 'Hello world!';
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (MethodCall methodCall) async {
      if (methodCall.method == 'Clipboard.getData')
        return const <String, dynamic>{'text': clipboardContent};
      if (methodCall.method == 'Clipboard.hasStrings')
        return <String, dynamic>{'value': clipboardContent.isNotEmpty};
      return null;
    });

    // Long-press to bring up the text editing controls.
    final Finder textFinder = find.byKey(editableTextKey);
    await tester.longPress(textFinder);
    tester.state<EditableTextState>(textFinder).showToolbar();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Paste'));
    await tester.pump();

    expect(changedValue, clipboardContent);

    await expectLater(
      find.byKey(const ValueKey<int>(1)),
      matchesGoldenFile('editable_text_test.3.png'),
    );
    EditableText.debugDeterministicCursor = false;
  }, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.iOS,  TargetPlatform.macOS }));
}
