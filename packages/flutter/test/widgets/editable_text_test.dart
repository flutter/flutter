// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:mockito/mockito.dart';

import 'semantics_tester.dart';

void main() {
  final TextEditingController controller = TextEditingController();
  final FocusNode focusNode = FocusNode();
  final FocusScopeNode focusScopeNode = FocusScopeNode();
  const TextStyle textStyle = TextStyle();
  const Color cursorColor = Color.fromARGB(0xFF, 0xFF, 0x00, 0x00);

  setUp(() {
    debugResetSemanticsIdCounter();
  });

  // Tests that the desired keyboard action button is requested.
  //
  // More technically, when an EditableText is given a particular [action], Flutter
  // requests [serializedActionName] when attaching to the platform's input
  // system.
  Future<void> _desiredKeyboardActionIsRequested({
    WidgetTester tester,
    TextInputAction action,
    String serializedActionName,
  }) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: FocusScope(
          node: focusScopeNode,
          autofocus: true,
          child: EditableText(
            controller: controller,
            focusNode: focusNode,
            textInputAction: action,
            style: textStyle,
            cursorColor: cursorColor,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(EditableText));
    await tester.showKeyboard(find.byType(EditableText));
    controller.text = 'test';
    await tester.idle();
    expect(tester.testTextInput.editingState['text'], equals('test'));
    expect(tester.testTextInput.setClientArgs['inputAction'],
        equals(serializedActionName));
  }

  testWidgets('has expected defaults', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: EditableText(
          controller: controller,
          focusNode: focusNode,
          style: textStyle,
          cursorColor: cursorColor,
        ),
      ),
    );

    final EditableText editableText =
        tester.firstWidget(find.byType(EditableText));
    expect(editableText.maxLines, equals(1));
    expect(editableText.obscureText, isFalse);
    expect(editableText.autocorrect, isTrue);
    expect(editableText.cursorWidth, 2.0);
  });

  testWidgets('cursor has expected width and radius',
      (WidgetTester tester) async {
    await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: EditableText(
          controller: controller,
          focusNode: focusNode,
          style: textStyle,
          cursorColor: cursorColor,
          cursorWidth: 10.0,
          cursorRadius: const Radius.circular(2.0),
        )));

    final EditableText editableText =
        tester.firstWidget(find.byType(EditableText));
    expect(editableText.cursorWidth, 10.0);
    expect(editableText.cursorRadius.x, 2.0);
  });

  testWidgets('text keyboard is requested when maxLines is default',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: FocusScope(
          node: focusScopeNode,
          autofocus: true,
          child: EditableText(
            controller: controller,
            focusNode: focusNode,
            style: textStyle,
            cursorColor: cursorColor,
          ),
        ),
      ),
    );
    await tester.tap(find.byType(EditableText));
    await tester.showKeyboard(find.byType(EditableText));
    controller.text = 'test';
    await tester.idle();
    final EditableText editableText =
        tester.firstWidget(find.byType(EditableText));
    expect(editableText.maxLines, equals(1));
    expect(tester.testTextInput.editingState['text'], equals('test'));
    expect(tester.testTextInput.setClientArgs['inputType']['name'],
        equals('TextInputType.text'));
    expect(tester.testTextInput.setClientArgs['inputAction'],
        equals('TextInputAction.done'));
  });

  testWidgets(
      'Keyboard is configured for "unspecified" action when explicitly requested',
      (WidgetTester tester) async {
    await _desiredKeyboardActionIsRequested(
      tester: tester,
      action: TextInputAction.unspecified,
      serializedActionName: 'TextInputAction.unspecified',
    );
  });

  testWidgets(
      'Keyboard is configured for "none" action when explicitly requested',
      (WidgetTester tester) async {
    await _desiredKeyboardActionIsRequested(
      tester: tester,
      action: TextInputAction.none,
      serializedActionName: 'TextInputAction.none',
    );
  });

  testWidgets(
      'Keyboard is configured for "done" action when explicitly requested',
      (WidgetTester tester) async {
    await _desiredKeyboardActionIsRequested(
      tester: tester,
      action: TextInputAction.done,
      serializedActionName: 'TextInputAction.done',
    );
  });

  testWidgets(
      'Keyboard is configured for "send" action when explicitly requested',
      (WidgetTester tester) async {
    await _desiredKeyboardActionIsRequested(
      tester: tester,
      action: TextInputAction.send,
      serializedActionName: 'TextInputAction.send',
    );
  });

  testWidgets(
      'Keyboard is configured for "go" action when explicitly requested',
      (WidgetTester tester) async {
    await _desiredKeyboardActionIsRequested(
      tester: tester,
      action: TextInputAction.go,
      serializedActionName: 'TextInputAction.go',
    );
  });

  testWidgets(
      'Keyboard is configured for "search" action when explicitly requested',
      (WidgetTester tester) async {
    await _desiredKeyboardActionIsRequested(
      tester: tester,
      action: TextInputAction.search,
      serializedActionName: 'TextInputAction.search',
    );
  });

  testWidgets(
      'Keyboard is configured for "send" action when explicitly requested',
      (WidgetTester tester) async {
    await _desiredKeyboardActionIsRequested(
      tester: tester,
      action: TextInputAction.send,
      serializedActionName: 'TextInputAction.send',
    );
  });

  testWidgets(
      'Keyboard is configured for "next" action when explicitly requested',
      (WidgetTester tester) async {
    await _desiredKeyboardActionIsRequested(
      tester: tester,
      action: TextInputAction.next,
      serializedActionName: 'TextInputAction.next',
    );
  });

  testWidgets(
      'Keyboard is configured for "previous" action when explicitly requested',
      (WidgetTester tester) async {
    await _desiredKeyboardActionIsRequested(
      tester: tester,
      action: TextInputAction.previous,
      serializedActionName: 'TextInputAction.previous',
    );
  });

  testWidgets(
      'Keyboard is configured for "continue" action when explicitly requested',
      (WidgetTester tester) async {
    await _desiredKeyboardActionIsRequested(
      tester: tester,
      action: TextInputAction.continueAction,
      serializedActionName: 'TextInputAction.continueAction',
    );
  });

  testWidgets(
      'Keyboard is configured for "join" action when explicitly requested',
      (WidgetTester tester) async {
    await _desiredKeyboardActionIsRequested(
      tester: tester,
      action: TextInputAction.join,
      serializedActionName: 'TextInputAction.join',
    );
  });

  testWidgets(
      'Keyboard is configured for "route" action when explicitly requested',
      (WidgetTester tester) async {
    await _desiredKeyboardActionIsRequested(
      tester: tester,
      action: TextInputAction.route,
      serializedActionName: 'TextInputAction.route',
    );
  });

  testWidgets(
      'Keyboard is configured for "emergencyCall" action when explicitly requested',
      (WidgetTester tester) async {
    await _desiredKeyboardActionIsRequested(
      tester: tester,
      action: TextInputAction.emergencyCall,
      serializedActionName: 'TextInputAction.emergencyCall',
    );
  });

  testWidgets('multiline keyboard is requested when set explicitly',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: FocusScope(
          node: focusScopeNode,
          autofocus: true,
          child: EditableText(
            controller: controller,
            focusNode: focusNode,
            keyboardType: TextInputType.multiline,
            style: textStyle,
            cursorColor: cursorColor,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(EditableText));
    await tester.showKeyboard(find.byType(EditableText));
    controller.text = 'test';
    await tester.idle();
    expect(tester.testTextInput.editingState['text'], equals('test'));
    expect(tester.testTextInput.setClientArgs['inputType']['name'],
        equals('TextInputType.multiline'));
    expect(tester.testTextInput.setClientArgs['inputAction'],
        equals('TextInputAction.newline'));
  });

  testWidgets('Multiline keyboard with newline action is requested when maxLines = null', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: FocusScope(
          node: focusScopeNode,
          autofocus: true,
          child: EditableText(
            controller: controller,
            focusNode: focusNode,
            maxLines: null,
            style: textStyle,
            cursorColor: cursorColor,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(EditableText));
    await tester.showKeyboard(find.byType(EditableText));
    controller.text = 'test';
    await tester.idle();
    expect(tester.testTextInput.editingState['text'], equals('test'));
    expect(tester.testTextInput.setClientArgs['inputType']['name'],
        equals('TextInputType.multiline'));
    expect(tester.testTextInput.setClientArgs['inputAction'],
        equals('TextInputAction.newline'));
  });

  testWidgets('Text keyboard is requested when explicitly set and maxLines = null', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: FocusScope(
          node: focusScopeNode,
          autofocus: true,
          child: EditableText(
            controller: controller,
            focusNode: focusNode,
            maxLines: null,
            keyboardType: TextInputType.text,
            style: textStyle,
            cursorColor: cursorColor,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(EditableText));
    await tester.showKeyboard(find.byType(EditableText));
    controller.text = 'test';
    await tester.idle();
    expect(tester.testTextInput.editingState['text'], equals('test'));
    expect(tester.testTextInput.setClientArgs['inputType']['name'],
        equals('TextInputType.text'));
    expect(tester.testTextInput.setClientArgs['inputAction'],
        equals('TextInputAction.done'));
  });

  testWidgets(
      'Correct keyboard is requested when set explicitly and maxLines > 1',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: FocusScope(
          node: focusScopeNode,
          autofocus: true,
          child: EditableText(
            controller: controller,
            focusNode: focusNode,
            keyboardType: TextInputType.phone,
            maxLines: 3,
            style: textStyle,
            cursorColor: cursorColor,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(EditableText));
    await tester.showKeyboard(find.byType(EditableText));
    controller.text = 'test';
    await tester.idle();
    expect(tester.testTextInput.editingState['text'], equals('test'));
    expect(tester.testTextInput.setClientArgs['inputType']['name'],
        equals('TextInputType.phone'));
    expect(tester.testTextInput.setClientArgs['inputAction'],
        equals('TextInputAction.done'));
  });

  testWidgets('multiline keyboard is requested when set implicitly',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: FocusScope(
          node: focusScopeNode,
          autofocus: true,
          child: EditableText(
            controller: controller,
            focusNode: focusNode,
            maxLines: 3, // Sets multiline keyboard implicitly.
            style: textStyle,
            cursorColor: cursorColor,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(EditableText));
    await tester.showKeyboard(find.byType(EditableText));
    controller.text = 'test';
    await tester.idle();
    expect(tester.testTextInput.editingState['text'], equals('test'));
    expect(tester.testTextInput.setClientArgs['inputType']['name'],
        equals('TextInputType.multiline'));
    expect(tester.testTextInput.setClientArgs['inputAction'],
        equals('TextInputAction.newline'));
  });

  testWidgets('single line inputs have correct default keyboard',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: FocusScope(
          node: focusScopeNode,
          autofocus: true,
          child: EditableText(
            controller: controller,
            focusNode: focusNode,
            maxLines: 1, // Sets text keyboard implicitly.
            style: textStyle,
            cursorColor: cursorColor,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(EditableText));
    await tester.showKeyboard(find.byType(EditableText));
    controller.text = 'test';
    await tester.idle();
    expect(tester.testTextInput.editingState['text'], equals('test'));
    expect(tester.testTextInput.setClientArgs['inputType']['name'],
        equals('TextInputType.text'));
    expect(tester.testTextInput.setClientArgs['inputAction'],
        equals('TextInputAction.done'));
  });

  testWidgets('Fires onChanged when text changes via TextSelectionOverlay',
      (WidgetTester tester) async {
    final GlobalKey<EditableTextState> editableTextKey =
        GlobalKey<EditableTextState>();

    String changedValue;
    final Widget widget = MaterialApp(
      home: EditableText(
        key: editableTextKey,
        controller: TextEditingController(),
        focusNode: FocusNode(),
        style: Typography(platform: TargetPlatform.android).black.subhead,
        cursorColor: Colors.blue,
        selectionControls: materialTextSelectionControls,
        keyboardType: TextInputType.text,
        onChanged: (String value) {
          changedValue = value;
        },
      ),
    );
    await tester.pumpWidget(widget);

    // Populate a fake clipboard.
    const String clipboardContent = 'Dobunezumi mitai ni utsukushiku naritai';
    SystemChannels.platform
        .setMockMethodCallHandler((MethodCall methodCall) async {
      if (methodCall.method == 'Clipboard.getData')
        return const <String, dynamic>{'text': clipboardContent};
      return null;
    });

    // Long-press to bring up the text editing controls.
    final Finder textFinder = find.byKey(editableTextKey);
    await tester.longPress(textFinder);
    await tester.pump();

    await tester.tap(find.text('PASTE'));
    await tester.pump();

    expect(changedValue, clipboardContent);
  });

  testWidgets('cursor layout has correct width', (WidgetTester tester) async {
    final GlobalKey<EditableTextState> editableTextKey =
        GlobalKey<EditableTextState>();

    String changedValue;
    final Widget widget = MaterialApp(
      home: RepaintBoundary(
        key: const ValueKey<int>(1),
        child: EditableText(
          key: editableTextKey,
          controller: TextEditingController(),
          focusNode: FocusNode(),
          style: Typography(platform: TargetPlatform.android).black.subhead,
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
    SystemChannels.platform
        .setMockMethodCallHandler((MethodCall methodCall) async {
      if (methodCall.method == 'Clipboard.getData')
        return const <String, dynamic>{'text': clipboardContent};
      return null;
    });

    // Long-press to bring up the text editing controls.
    final Finder textFinder = find.byKey(editableTextKey);
    await tester.longPress(textFinder);
    await tester.pump();

    await tester.tap(find.text('PASTE'));
    await tester.pump();

    expect(changedValue, clipboardContent);

    await expectLater(
      find.byKey(const ValueKey<int>(1)),
      matchesGoldenFile('editable_text_test.0.0.png'),
    );
  }, skip: !Platform.isLinux);

  testWidgets('cursor layout has correct radius', (WidgetTester tester) async {
    final GlobalKey<EditableTextState> editableTextKey =
        GlobalKey<EditableTextState>();

    String changedValue;
    final Widget widget = MaterialApp(
      home: RepaintBoundary(
        key: const ValueKey<int>(1),
        child: EditableText(
          key: editableTextKey,
          controller: TextEditingController(),
          focusNode: FocusNode(),
          style: Typography(platform: TargetPlatform.android).black.subhead,
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
    SystemChannels.platform
        .setMockMethodCallHandler((MethodCall methodCall) async {
      if (methodCall.method == 'Clipboard.getData')
        return const <String, dynamic>{'text': clipboardContent};
      return null;
    });

    // Long-press to bring up the text editing controls.
    final Finder textFinder = find.byKey(editableTextKey);
    await tester.longPress(textFinder);
    await tester.pump();

    await tester.tap(find.text('PASTE'));
    await tester.pump();

    expect(changedValue, clipboardContent);

    await expectLater(
      find.byKey(const ValueKey<int>(1)),
      matchesGoldenFile('editable_text_test.1.0.png'),
    );
  }, skip: !Platform.isLinux);

  testWidgets('Does not lose focus by default when "next" action is pressed',
      (WidgetTester tester) async {
    final GlobalKey<EditableTextState> editableTextKey =
        GlobalKey<EditableTextState>();
    final FocusNode focusNode = FocusNode();

    final Widget widget = MaterialApp(
      home: EditableText(
        key: editableTextKey,
        controller: TextEditingController(),
        focusNode: focusNode,
        style: Typography(platform: TargetPlatform.android).black.subhead,
        cursorColor: Colors.blue,
        selectionControls: materialTextSelectionControls,
        keyboardType: TextInputType.text,
      ),
    );
    await tester.pumpWidget(widget);

    // Select EditableText to give it focus.
    final Finder textFinder = find.byKey(editableTextKey);
    await tester.tap(textFinder);
    await tester.pump();

    assert(focusNode.hasFocus);

    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();

    // Still has focus after pressing "next".
    expect(focusNode.hasFocus, true);
  });

  testWidgets(
      'Does not lose focus by default when "done" action is pressed and onEditingComplete is provided',
      (WidgetTester tester) async {
    final GlobalKey<EditableTextState> editableTextKey =
        GlobalKey<EditableTextState>();
    final FocusNode focusNode = FocusNode();

    final Widget widget = MaterialApp(
      home: EditableText(
        key: editableTextKey,
        controller: TextEditingController(),
        focusNode: focusNode,
        style: Typography(platform: TargetPlatform.android).black.subhead,
        cursorColor: Colors.blue,
        selectionControls: materialTextSelectionControls,
        keyboardType: TextInputType.text,
        onEditingComplete: () {
          // This prevents the default focus change behavior on submission.
        },
      ),
    );
    await tester.pumpWidget(widget);

    // Select EditableText to give it focus.
    final Finder textFinder = find.byKey(editableTextKey);
    await tester.tap(textFinder);
    await tester.pump();

    assert(focusNode.hasFocus);

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    // Still has focus even though "done" was pressed because onEditingComplete
    // was provided and it overrides the default behavior.
    expect(focusNode.hasFocus, true);
  });

  testWidgets(
      'When "done" is pressed callbacks are invoked: onEditingComplete > onSubmitted',
      (WidgetTester tester) async {
    final GlobalKey<EditableTextState> editableTextKey =
        GlobalKey<EditableTextState>();
    final FocusNode focusNode = FocusNode();

    bool onEditingCompleteCalled = false;
    bool onSubmittedCalled = false;

    final Widget widget = MaterialApp(
      home: EditableText(
        key: editableTextKey,
        controller: TextEditingController(),
        focusNode: focusNode,
        style: Typography(platform: TargetPlatform.android).black.subhead,
        cursorColor: Colors.blue,
        onEditingComplete: () {
          onEditingCompleteCalled = true;
          expect(onSubmittedCalled, false);
        },
        onSubmitted: (String value) {
          onSubmittedCalled = true;
          expect(onEditingCompleteCalled, true);
        },
      ),
    );
    await tester.pumpWidget(widget);

    // Select EditableText to give it focus.
    final Finder textFinder = find.byKey(editableTextKey);
    await tester.tap(textFinder);
    await tester.pump();

    assert(focusNode.hasFocus);

    // The execution path starting with receiveAction() will trigger the
    // onEditingComplete and onSubmission callbacks.
    await tester.testTextInput.receiveAction(TextInputAction.done);

    // The expectations we care about are up above in the onEditingComplete
    // and onSubmission callbacks.
  });

  testWidgets(
      'When "next" is pressed callbacks are invoked: onEditingComplete > onSubmitted',
      (WidgetTester tester) async {
    final GlobalKey<EditableTextState> editableTextKey =
        GlobalKey<EditableTextState>();
    final FocusNode focusNode = FocusNode();

    bool onEditingCompleteCalled = false;
    bool onSubmittedCalled = false;

    final Widget widget = MaterialApp(
      home: EditableText(
        key: editableTextKey,
        controller: TextEditingController(),
        focusNode: focusNode,
        style: Typography(platform: TargetPlatform.android).black.subhead,
        cursorColor: Colors.blue,
        onEditingComplete: () {
          onEditingCompleteCalled = true;
          assert(!onSubmittedCalled);
        },
        onSubmitted: (String value) {
          onSubmittedCalled = true;
          assert(onEditingCompleteCalled);
        },
      ),
    );
    await tester.pumpWidget(widget);

    // Select EditableText to give it focus.
    final Finder textFinder = find.byKey(editableTextKey);
    await tester.tap(textFinder);
    await tester.pump();

    assert(focusNode.hasFocus);

    // The execution path starting with receiveAction() will trigger the
    // onEditingComplete and onSubmission callbacks.
    await tester.testTextInput.receiveAction(TextInputAction.done);

    // The expectations we care about are up above in the onEditingComplete
    // and onSubmission callbacks.
  });

  testWidgets(
      'When "newline" action is called on a Editable text with maxLines == 1 callbacks are invoked: onEditingComplete > onSubmitted',
      (WidgetTester tester) async {
    final GlobalKey<EditableTextState> editableTextKey =
        GlobalKey<EditableTextState>();
    final FocusNode focusNode = FocusNode();

    bool onEditingCompleteCalled = false;
    bool onSubmittedCalled = false;

    final Widget widget = MaterialApp(
      home: EditableText(
        key: editableTextKey,
        controller: TextEditingController(),
        focusNode: focusNode,
        style: Typography(platform: TargetPlatform.android).black.subhead,
        cursorColor: Colors.blue,
        maxLines: 1,
        onEditingComplete: () {
          onEditingCompleteCalled = true;
          assert(!onSubmittedCalled);
        },
        onSubmitted: (String value) {
          onSubmittedCalled = true;
          assert(onEditingCompleteCalled);
        },
      ),
    );
    await tester.pumpWidget(widget);

    // Select EditableText to give it focus.
    final Finder textFinder = find.byKey(editableTextKey);
    await tester.tap(textFinder);
    await tester.pump();

    assert(focusNode.hasFocus);

    // The execution path starting with receiveAction() will trigger the
    // onEditingComplete and onSubmission callbacks.
    await tester.testTextInput.receiveAction(TextInputAction.newline);
    // The expectations we care about are up above in the onEditingComplete
    // and onSubmission callbacks.
  });

testWidgets(
      'When "newline" action is called on a Editable text with maxLines != 1, onEditingComplete and onSubmitted callbacks are not invoked.',
      (WidgetTester tester) async {
    final GlobalKey<EditableTextState> editableTextKey =
        GlobalKey<EditableTextState>();
    final FocusNode focusNode = FocusNode();

    bool onEditingCompleteCalled = false;
    bool onSubmittedCalled = false;

    final Widget widget = MaterialApp(
      home: EditableText(
        key: editableTextKey,
        controller: TextEditingController(),
        focusNode: focusNode,
        style: Typography(platform: TargetPlatform.android).black.subhead,
        cursorColor: Colors.blue,
        maxLines: 3,
        onEditingComplete: () {
          onEditingCompleteCalled = true;
        },
        onSubmitted: (String value) {
          onSubmittedCalled = true;
        },
      ),
    );
    await tester.pumpWidget(widget);

    // Select EditableText to give it focus.
    final Finder textFinder = find.byKey(editableTextKey);
    await tester.tap(textFinder);
    await tester.pump();

    assert(focusNode.hasFocus);

    // The execution path starting with receiveAction() will trigger the
    // onEditingComplete and onSubmission callbacks.
    await tester.testTextInput.receiveAction(TextInputAction.newline);

    // These callbacks shouldn't have been triggered.
    assert(!onSubmittedCalled);
    assert(!onEditingCompleteCalled);
  });

  testWidgets('Changing controller updates EditableText',
      (WidgetTester tester) async {
    final GlobalKey<EditableTextState> editableTextKey =
        GlobalKey<EditableTextState>();
    final TextEditingController controller1 =
        TextEditingController(text: 'Wibble');
    final TextEditingController controller2 =
        TextEditingController(text: 'Wobble');
    TextEditingController currentController = controller1;
    StateSetter setState;

    Widget builder() {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setter) {
          setState = setter;
          return Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: Material(
                child: EditableText(
                  key: editableTextKey,
                  controller: currentController,
                  focusNode: FocusNode(),
                  style: Typography(platform: TargetPlatform.android)
                      .black
                      .subhead,
                  cursorColor: Colors.blue,
                  selectionControls: materialTextSelectionControls,
                  keyboardType: TextInputType.text,
                  onChanged: (String value) {},
                ),
              ),
            ),
          );
        },
      );
    }

    await tester.pumpWidget(builder());
    await tester.showKeyboard(find.byType(EditableText));

    // Verify TextInput.setEditingState is fired with updated text when controller is replaced.
    final List<MethodCall> log = <MethodCall>[];
    SystemChannels.textInput.setMockMethodCallHandler((MethodCall methodCall) async {
      log.add(methodCall);
    });
    setState(() {
      currentController = controller2;
    });
    await tester.pump();

    expect(log, hasLength(1));
    expect(
        log.single,
        isMethodCall(
          'TextInput.setEditingState',
          arguments: const <String, dynamic>{
            'text': 'Wobble',
            'selectionBase': -1,
            'selectionExtent': -1,
            'selectionAffinity': 'TextAffinity.downstream',
            'selectionIsDirectional': false,
            'composingBase': -1,
            'composingExtent': -1,
          },
        ));
  });

  testWidgets('EditableText identifies as text field (w/ focus) in semantics',
      (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: FocusScope(
          node: focusScopeNode,
          autofocus: true,
          child: EditableText(
            controller: controller,
            focusNode: focusNode,
            style: textStyle,
            cursorColor: cursorColor,
          ),
        ),
      ),
    );

    expect(semantics,
        includesNodeWith(flags: <SemanticsFlag>[SemanticsFlag.isTextField]));

    await tester.tap(find.byType(EditableText));
    await tester.idle();
    await tester.pump();

    expect(
        semantics,
        includesNodeWith(flags: <SemanticsFlag>[
          SemanticsFlag.isTextField,
          SemanticsFlag.isFocused
        ]));

    semantics.dispose();
  });

  testWidgets('EditableText includes text as value in semantics',
      (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    const String value1 = 'EditableText content';

    controller.text = value1;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: FocusScope(
          node: focusScopeNode,
          child: EditableText(
            controller: controller,
            focusNode: focusNode,
            style: textStyle,
            cursorColor: cursorColor,
          ),
        ),
      ),
    );

    expect(
        semantics,
        includesNodeWith(
          flags: <SemanticsFlag>[SemanticsFlag.isTextField],
          value: value1,
        ));

    const String value2 = 'Changed the EditableText content';
    controller.text = value2;
    await tester.idle();
    await tester.pump();

    expect(
        semantics,
        includesNodeWith(
          flags: <SemanticsFlag>[SemanticsFlag.isTextField],
          value: value2,
        ));

    semantics.dispose();
  });

  testWidgets('changing selection with keyboard does not show handles',
      (WidgetTester tester) async {
    const String value1 = 'Hello World';

    controller.text = value1;

    await tester.pumpWidget(
      MaterialApp(
        home: EditableText(
          controller: controller,
          selectionControls: materialTextSelectionControls,
          focusNode: focusNode,
          style: textStyle,
          cursorColor: cursorColor,
        ),
      ),
    );

    // Simulate selection change via tap to show handles.
    final RenderEditable render = tester.allRenderObjects
        .firstWhere((RenderObject o) => o.runtimeType == RenderEditable);
    render.onSelectionChanged(const TextSelection.collapsed(offset: 4), render,
        SelectionChangedCause.tap);

    await tester.pumpAndSettle();
    final EditableTextState textState = tester.state(find.byType(EditableText));

    expect(textState.selectionOverlay.handlesAreVisible, isTrue);
    expect(
        textState.selectionOverlay.selectionDelegate.textEditingValue.selection,
        const TextSelection.collapsed(offset: 4));

    // Simulate selection change via keyboard and expect handles to disappear.
    render.onSelectionChanged(const TextSelection.collapsed(offset: 10), render,
        SelectionChangedCause.keyboard);
    await tester.pumpAndSettle();

    expect(textState.selectionOverlay.handlesAreVisible, isFalse);
    expect(
        textState.selectionOverlay.selectionDelegate.textEditingValue.selection,
        const TextSelection.collapsed(offset: 10));
  });

  testWidgets('exposes correct cursor movement semantics',
      (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    controller.text = 'test';

    await tester.pumpWidget(MaterialApp(
      home: EditableText(
        controller: controller,
        focusNode: focusNode,
        style: textStyle,
        cursorColor: cursorColor,
      ),
    ));

    expect(
        semantics,
        includesNodeWith(
          value: 'test',
        ));

    controller.selection =
        TextSelection.collapsed(offset: controller.text.length);
    await tester.pumpAndSettle();

    // At end, can only go backwards.
    expect(
        semantics,
        includesNodeWith(
          value: 'test',
          actions: <SemanticsAction>[
            SemanticsAction.moveCursorBackwardByCharacter,
            SemanticsAction.moveCursorBackwardByWord,
            SemanticsAction.setSelection,
          ],
        ));

    controller.selection =
        TextSelection.collapsed(offset: controller.text.length - 2);
    await tester.pumpAndSettle();

    // Somewhere in the middle, can go in both directions.
    expect(
        semantics,
        includesNodeWith(
          value: 'test',
          actions: <SemanticsAction>[
            SemanticsAction.moveCursorBackwardByCharacter,
            SemanticsAction.moveCursorForwardByCharacter,
            SemanticsAction.moveCursorBackwardByWord,
            SemanticsAction.moveCursorForwardByWord,
            SemanticsAction.setSelection,
          ],
        ));

    controller.selection = const TextSelection.collapsed(offset: 0);
    await tester.pumpAndSettle();

    // At beginning, can only go forward.
    expect(
        semantics,
        includesNodeWith(
          value: 'test',
          actions: <SemanticsAction>[
            SemanticsAction.moveCursorForwardByCharacter,
            SemanticsAction.moveCursorForwardByWord,
            SemanticsAction.setSelection,
          ],
        ));

    semantics.dispose();
  });

  testWidgets('can move cursor with a11y means - character', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);
    const bool doNotExtendSelection = false;

    controller.text = 'test';
    controller.selection =
        TextSelection.collapsed(offset: controller.text.length);

    await tester.pumpWidget(MaterialApp(
      home: EditableText(
        controller: controller,
        focusNode: focusNode,
        style: textStyle,
        cursorColor: cursorColor,
      ),
    ));

    expect(
        semantics,
        includesNodeWith(
          value: 'test',
          actions: <SemanticsAction>[
            SemanticsAction.moveCursorBackwardByCharacter,
            SemanticsAction.moveCursorBackwardByWord,
          ],
        ));

    final RenderEditable render = tester.allRenderObjects
        .firstWhere((RenderObject o) => o.runtimeType == RenderEditable);
    final int semanticsId = render.debugSemantics.id;

    expect(controller.selection.baseOffset, 4);
    expect(controller.selection.extentOffset, 4);

    tester.binding.pipelineOwner.semanticsOwner.performAction(semanticsId,
        SemanticsAction.moveCursorBackwardByCharacter, doNotExtendSelection);
    await tester.pumpAndSettle();

    expect(controller.selection.baseOffset, 3);
    expect(controller.selection.extentOffset, 3);

    expect(
        semantics,
        includesNodeWith(
          value: 'test',
          actions: <SemanticsAction>[
            SemanticsAction.moveCursorBackwardByCharacter,
            SemanticsAction.moveCursorForwardByCharacter,
            SemanticsAction.moveCursorBackwardByWord,
            SemanticsAction.moveCursorForwardByWord,
            SemanticsAction.setSelection,
          ],
        ));

    tester.binding.pipelineOwner.semanticsOwner.performAction(semanticsId,
        SemanticsAction.moveCursorBackwardByCharacter, doNotExtendSelection);
    await tester.pumpAndSettle();
    tester.binding.pipelineOwner.semanticsOwner.performAction(semanticsId,
        SemanticsAction.moveCursorBackwardByCharacter, doNotExtendSelection);
    await tester.pumpAndSettle();
    tester.binding.pipelineOwner.semanticsOwner.performAction(semanticsId,
        SemanticsAction.moveCursorBackwardByCharacter, doNotExtendSelection);
    await tester.pumpAndSettle();

    expect(controller.selection.baseOffset, 0);
    expect(controller.selection.extentOffset, 0);

    await tester.pumpAndSettle();
    expect(
        semantics,
        includesNodeWith(
          value: 'test',
          actions: <SemanticsAction>[
            SemanticsAction.moveCursorForwardByCharacter,
            SemanticsAction.moveCursorForwardByWord,
            SemanticsAction.setSelection,
          ],
        ));

    tester.binding.pipelineOwner.semanticsOwner.performAction(semanticsId,
        SemanticsAction.moveCursorForwardByCharacter, doNotExtendSelection);
    await tester.pumpAndSettle();

    expect(controller.selection.baseOffset, 1);
    expect(controller.selection.extentOffset, 1);

    semantics.dispose();
  });

  testWidgets('can move cursor with a11y means - word', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);
    const bool doNotExtendSelection = false;

    controller.text = 'test for words';
    controller.selection =
    TextSelection.collapsed(offset: controller.text.length);

    await tester.pumpWidget(MaterialApp(
      home: EditableText(
        controller: controller,
        focusNode: focusNode,
        style: textStyle,
        cursorColor: cursorColor,
      ),
    ));

    expect(
        semantics,
        includesNodeWith(
          value: 'test for words',
          actions: <SemanticsAction>[
            SemanticsAction.moveCursorBackwardByCharacter,
            SemanticsAction.moveCursorBackwardByWord,
          ],
        ));

    final RenderEditable render = tester.allRenderObjects
        .firstWhere((RenderObject o) => o.runtimeType == RenderEditable);
    final int semanticsId = render.debugSemantics.id;

    expect(controller.selection.baseOffset, 14);
    expect(controller.selection.extentOffset, 14);

    tester.binding.pipelineOwner.semanticsOwner.performAction(semanticsId,
        SemanticsAction.moveCursorBackwardByWord, doNotExtendSelection);
    await tester.pumpAndSettle();

    expect(controller.selection.baseOffset, 9);
    expect(controller.selection.extentOffset, 9);

    expect(
        semantics,
        includesNodeWith(
          value: 'test for words',
          actions: <SemanticsAction>[
            SemanticsAction.moveCursorBackwardByCharacter,
            SemanticsAction.moveCursorForwardByCharacter,
            SemanticsAction.moveCursorBackwardByWord,
            SemanticsAction.moveCursorForwardByWord,
            SemanticsAction.setSelection,
          ],
        ));

    tester.binding.pipelineOwner.semanticsOwner.performAction(semanticsId,
        SemanticsAction.moveCursorBackwardByWord, doNotExtendSelection);
    await tester.pumpAndSettle();

    expect(controller.selection.baseOffset, 5);
    expect(controller.selection.extentOffset, 5);

    tester.binding.pipelineOwner.semanticsOwner.performAction(semanticsId,
        SemanticsAction.moveCursorBackwardByWord, doNotExtendSelection);
    await tester.pumpAndSettle();

    expect(controller.selection.baseOffset, 0);
    expect(controller.selection.extentOffset, 0);

    await tester.pumpAndSettle();
    expect(
        semantics,
        includesNodeWith(
          value: 'test for words',
          actions: <SemanticsAction>[
            SemanticsAction.moveCursorForwardByCharacter,
            SemanticsAction.moveCursorForwardByWord,
            SemanticsAction.setSelection,
          ],
        ));

    tester.binding.pipelineOwner.semanticsOwner.performAction(semanticsId,
        SemanticsAction.moveCursorForwardByWord, doNotExtendSelection);
    await tester.pumpAndSettle();

    expect(controller.selection.baseOffset, 5);
    expect(controller.selection.extentOffset, 5);

    tester.binding.pipelineOwner.semanticsOwner.performAction(semanticsId,
        SemanticsAction.moveCursorForwardByWord, doNotExtendSelection);
    await tester.pumpAndSettle();

    expect(controller.selection.baseOffset, 9);
    expect(controller.selection.extentOffset, 9);

    semantics.dispose();
  });

  testWidgets('can extend selection with a11y means - character',
      (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);
    const bool extendSelection = true;
    const bool doNotExtendSelection = false;

    controller.text = 'test';
    controller.selection =
        TextSelection.collapsed(offset: controller.text.length);

    await tester.pumpWidget(MaterialApp(
      home: EditableText(
        controller: controller,
        focusNode: focusNode,
        style: textStyle,
        cursorColor: cursorColor,
      ),
    ));

    expect(
        semantics,
        includesNodeWith(
          value: 'test',
          actions: <SemanticsAction>[
            SemanticsAction.moveCursorBackwardByCharacter,
            SemanticsAction.moveCursorBackwardByWord,
          ],
        ));

    final RenderEditable render = tester.allRenderObjects
        .firstWhere((RenderObject o) => o.runtimeType == RenderEditable);
    final int semanticsId = render.debugSemantics.id;

    expect(controller.selection.baseOffset, 4);
    expect(controller.selection.extentOffset, 4);

    tester.binding.pipelineOwner.semanticsOwner.performAction(semanticsId,
        SemanticsAction.moveCursorBackwardByCharacter, extendSelection);
    await tester.pumpAndSettle();

    expect(controller.selection.baseOffset, 4);
    expect(controller.selection.extentOffset, 3);

    expect(
        semantics,
        includesNodeWith(
          value: 'test',
          actions: <SemanticsAction>[
            SemanticsAction.moveCursorBackwardByCharacter,
            SemanticsAction.moveCursorForwardByCharacter,
            SemanticsAction.moveCursorBackwardByWord,
            SemanticsAction.moveCursorForwardByWord,
            SemanticsAction.setSelection,
          ],
        ));

    tester.binding.pipelineOwner.semanticsOwner.performAction(semanticsId,
        SemanticsAction.moveCursorBackwardByCharacter, extendSelection);
    await tester.pumpAndSettle();
    tester.binding.pipelineOwner.semanticsOwner.performAction(semanticsId,
        SemanticsAction.moveCursorBackwardByCharacter, extendSelection);
    await tester.pumpAndSettle();
    tester.binding.pipelineOwner.semanticsOwner.performAction(semanticsId,
        SemanticsAction.moveCursorBackwardByCharacter, extendSelection);
    await tester.pumpAndSettle();

    expect(controller.selection.baseOffset, 4);
    expect(controller.selection.extentOffset, 0);

    await tester.pumpAndSettle();
    expect(
        semantics,
        includesNodeWith(
          value: 'test',
          actions: <SemanticsAction>[
            SemanticsAction.moveCursorForwardByCharacter,
            SemanticsAction.moveCursorForwardByWord,
            SemanticsAction.setSelection,
          ],
        ));

    tester.binding.pipelineOwner.semanticsOwner.performAction(semanticsId,
        SemanticsAction.moveCursorForwardByCharacter, doNotExtendSelection);
    await tester.pumpAndSettle();

    expect(controller.selection.baseOffset, 1);
    expect(controller.selection.extentOffset, 1);

    tester.binding.pipelineOwner.semanticsOwner.performAction(semanticsId,
        SemanticsAction.moveCursorForwardByCharacter, extendSelection);
    await tester.pumpAndSettle();

    expect(controller.selection.baseOffset, 1);
    expect(controller.selection.extentOffset, 2);

    semantics.dispose();
  });

  testWidgets('can extend selection with a11y means - word',
          (WidgetTester tester) async {
      final SemanticsTester semantics = SemanticsTester(tester);
      const bool extendSelection = true;
      const bool doNotExtendSelection = false;

      controller.text = 'test for words';
      controller.selection =
      TextSelection.collapsed(offset: controller.text.length);

      await tester.pumpWidget(MaterialApp(
        home: EditableText(
          controller: controller,
          focusNode: focusNode,
          style: textStyle,
          cursorColor: cursorColor,
        ),
      ));

      expect(
          semantics,
          includesNodeWith(
            value: 'test for words',
            actions: <SemanticsAction>[
              SemanticsAction.moveCursorBackwardByCharacter,
              SemanticsAction.moveCursorBackwardByWord,
            ],
          ));

      final RenderEditable render = tester.allRenderObjects
          .firstWhere((RenderObject o) => o.runtimeType == RenderEditable);
      final int semanticsId = render.debugSemantics.id;

      expect(controller.selection.baseOffset, 14);
      expect(controller.selection.extentOffset, 14);

      tester.binding.pipelineOwner.semanticsOwner.performAction(semanticsId,
          SemanticsAction.moveCursorBackwardByWord, extendSelection);
      await tester.pumpAndSettle();

      expect(controller.selection.baseOffset, 14);
      expect(controller.selection.extentOffset, 9);

      expect(
          semantics,
          includesNodeWith(
            value: 'test for words',
            actions: <SemanticsAction>[
              SemanticsAction.moveCursorBackwardByCharacter,
              SemanticsAction.moveCursorForwardByCharacter,
              SemanticsAction.moveCursorBackwardByWord,
              SemanticsAction.moveCursorForwardByWord,
              SemanticsAction.setSelection,
            ],
          ));

      tester.binding.pipelineOwner.semanticsOwner.performAction(semanticsId,
          SemanticsAction.moveCursorBackwardByWord, extendSelection);
      await tester.pumpAndSettle();

      expect(controller.selection.baseOffset, 14);
      expect(controller.selection.extentOffset, 5);

      tester.binding.pipelineOwner.semanticsOwner.performAction(semanticsId,
          SemanticsAction.moveCursorBackwardByWord, extendSelection);
      await tester.pumpAndSettle();

      expect(controller.selection.baseOffset, 14);
      expect(controller.selection.extentOffset, 0);

      await tester.pumpAndSettle();
      expect(
          semantics,
          includesNodeWith(
            value: 'test for words',
            actions: <SemanticsAction>[
              SemanticsAction.moveCursorForwardByCharacter,
              SemanticsAction.moveCursorForwardByWord,
              SemanticsAction.setSelection,
            ],
          ));

      tester.binding.pipelineOwner.semanticsOwner.performAction(semanticsId,
          SemanticsAction.moveCursorForwardByWord, doNotExtendSelection);
      await tester.pumpAndSettle();

      expect(controller.selection.baseOffset, 5);
      expect(controller.selection.extentOffset, 5);

      tester.binding.pipelineOwner.semanticsOwner.performAction(semanticsId,
          SemanticsAction.moveCursorForwardByWord, extendSelection);
      await tester.pumpAndSettle();

      expect(controller.selection.baseOffset, 5);
      expect(controller.selection.extentOffset, 9);

      semantics.dispose();
  });

  testWidgets('password fields have correct semantics',
      (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    controller.text = 'super-secret-password!!1';

    await tester.pumpWidget(MaterialApp(
      home: EditableText(
        obscureText: true,
        controller: controller,
        focusNode: focusNode,
        style: textStyle,
        cursorColor: cursorColor,
      ),
    ));

    final String expectedValue = '•' * controller.text.length;

    expect(
        semantics,
        hasSemantics(
            TestSemantics(
              children: <TestSemantics>[
                TestSemantics.rootChild(
                  children: <TestSemantics>[
                    TestSemantics(
                      flags: <SemanticsFlag>[SemanticsFlag.scopesRoute],
                      children: <TestSemantics>[
                        TestSemantics(
                          flags: <SemanticsFlag>[
                            SemanticsFlag.isTextField,
                            SemanticsFlag.isObscured
                          ],
                          value: expectedValue,
                          textDirection: TextDirection.ltr,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            ignoreTransform: true,
            ignoreRect: true,
            ignoreId: true));

    semantics.dispose();
  });

  group('a11y copy/cut/paste', () {
    Future<void> _buildApp(
        MockTextSelectionControls controls, WidgetTester tester) {
      return tester.pumpWidget(MaterialApp(
        home: EditableText(
          controller: controller,
          focusNode: focusNode,
          style: textStyle,
          cursorColor: cursorColor,
          selectionControls: controls,
        ),
      ));
    }

    MockTextSelectionControls controls;

    setUp(() {
      controller.text = 'test';
      controller.selection =
          TextSelection.collapsed(offset: controller.text.length);

      controls = MockTextSelectionControls();
      when(controls.buildHandle(any, any, any)).thenReturn(Container());
      when(controls.buildToolbar(any, any, any, any))
          .thenReturn(Container());
    });

    testWidgets('are exposed', (WidgetTester tester) async {
      final SemanticsTester semantics = SemanticsTester(tester);

      when(controls.canCopy(any)).thenReturn(false);
      when(controls.canCut(any)).thenReturn(false);
      when(controls.canPaste(any)).thenReturn(false);

      await _buildApp(controls, tester);
      await tester.tap(find.byType(EditableText));
      await tester.pump();

      expect(
          semantics,
          includesNodeWith(
            value: 'test',
            actions: <SemanticsAction>[
              SemanticsAction.moveCursorBackwardByCharacter,
              SemanticsAction.moveCursorBackwardByWord,
              SemanticsAction.setSelection,
            ],
          ));

      when(controls.canCopy(any)).thenReturn(true);
      await _buildApp(controls, tester);
      expect(
          semantics,
          includesNodeWith(
            value: 'test',
            actions: <SemanticsAction>[
              SemanticsAction.moveCursorBackwardByCharacter,
              SemanticsAction.moveCursorBackwardByWord,
              SemanticsAction.setSelection,
              SemanticsAction.copy,
            ],
          ));

      when(controls.canCopy(any)).thenReturn(false);
      when(controls.canPaste(any)).thenReturn(true);
      await _buildApp(controls, tester);
      expect(
          semantics,
          includesNodeWith(
            value: 'test',
            actions: <SemanticsAction>[
              SemanticsAction.moveCursorBackwardByCharacter,
              SemanticsAction.moveCursorBackwardByWord,
              SemanticsAction.setSelection,
              SemanticsAction.paste,
            ],
          ));

      when(controls.canPaste(any)).thenReturn(false);
      when(controls.canCut(any)).thenReturn(true);
      await _buildApp(controls, tester);
      expect(
          semantics,
          includesNodeWith(
            value: 'test',
            actions: <SemanticsAction>[
              SemanticsAction.moveCursorBackwardByCharacter,
              SemanticsAction.moveCursorBackwardByWord,
              SemanticsAction.setSelection,
              SemanticsAction.cut,
            ],
          ));

      when(controls.canCopy(any)).thenReturn(true);
      when(controls.canCut(any)).thenReturn(true);
      when(controls.canPaste(any)).thenReturn(true);
      await _buildApp(controls, tester);
      expect(
          semantics,
          includesNodeWith(
            value: 'test',
            actions: <SemanticsAction>[
              SemanticsAction.moveCursorBackwardByCharacter,
              SemanticsAction.moveCursorBackwardByWord,
              SemanticsAction.setSelection,
              SemanticsAction.cut,
              SemanticsAction.copy,
              SemanticsAction.paste,
            ],
          ));

      semantics.dispose();
    });

    testWidgets('can copy/cut/paste with a11y', (WidgetTester tester) async {
      final SemanticsTester semantics = SemanticsTester(tester);

      when(controls.canCopy(any)).thenReturn(true);
      when(controls.canCut(any)).thenReturn(true);
      when(controls.canPaste(any)).thenReturn(true);
      await _buildApp(controls, tester);
      await tester.tap(find.byType(EditableText));
      await tester.pump();

      final SemanticsOwner owner = tester.binding.pipelineOwner.semanticsOwner;
      const int expectedNodeId = 4;

      expect(
          semantics,
          hasSemantics(
              TestSemantics.root(
                children: <TestSemantics>[
                  TestSemantics.rootChild(
                    id: 1,
                    children: <TestSemantics>[
                      TestSemantics(
                        id: 2,
                        flags: <SemanticsFlag>[SemanticsFlag.scopesRoute],
                        children: <TestSemantics>[
                          TestSemantics.rootChild(
                            id: expectedNodeId,
                            flags: <SemanticsFlag>[
                              SemanticsFlag.isTextField,
                              SemanticsFlag.isFocused
                            ],
                            actions: <SemanticsAction>[
                              SemanticsAction.moveCursorBackwardByCharacter,
                              SemanticsAction.moveCursorBackwardByWord,
                              SemanticsAction.setSelection,
                              SemanticsAction.copy,
                              SemanticsAction.cut,
                              SemanticsAction.paste
                            ],
                            value: 'test',
                            textSelection: TextSelection.collapsed(
                                offset: controller.text.length),
                            textDirection: TextDirection.ltr,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              ignoreRect: true,
              ignoreTransform: true));

      owner.performAction(expectedNodeId, SemanticsAction.copy);
      verify(controls.handleCopy(any)).called(1);

      owner.performAction(expectedNodeId, SemanticsAction.cut);
      verify(controls.handleCut(any)).called(1);

      owner.performAction(expectedNodeId, SemanticsAction.paste);
      verify(controls.handlePaste(any)).called(1);

      semantics.dispose();
    });
  });

  testWidgets('allows customizing text style in subclasses',
      (WidgetTester tester) async {
    controller.text = 'Hello World';

    await tester.pumpWidget(MaterialApp(
      home: CustomStyleEditableText(
        controller: controller,
        focusNode: focusNode,
        style: textStyle,
        cursorColor: cursorColor,
      ),
    ));

    // Simulate selection change via tap to show handles.
    final RenderEditable render = tester.allRenderObjects
        .firstWhere((RenderObject o) => o.runtimeType == RenderEditable);
    expect(render.text.style.fontStyle, FontStyle.italic);
  });

  testWidgets('autofocus sets cursor to the end of text',
      (WidgetTester tester) async {
    const String text = 'hello world';
    final FocusScopeNode focusScopeNode = FocusScopeNode();
    final FocusNode focusNode = FocusNode();

    controller.text = text;
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: FocusScope(
        node: focusScopeNode,
        autofocus: true,
        child: EditableText(
          controller: controller,
          focusNode: focusNode,
          autofocus: true,
          style: textStyle,
          cursorColor: cursorColor,
        ),
      ),
    ));

    expect(focusNode.hasFocus, true);
    expect(controller.selection.isCollapsed, true);
    expect(controller.selection.baseOffset, text.length);
  });
}

class MockTextSelectionControls extends Mock implements TextSelectionControls {}

class CustomStyleEditableText extends EditableText {
  CustomStyleEditableText({
    TextEditingController controller,
    Color cursorColor,
    FocusNode focusNode,
    TextStyle style,
  }) : super(
          controller: controller,
          cursorColor: cursorColor,
          focusNode: focusNode,
          style: style,
        );
  @override
  CustomStyleEditableTextState createState() =>
      CustomStyleEditableTextState();
}

class CustomStyleEditableTextState extends EditableTextState {
  @override
  TextSpan buildTextSpan() {
    return TextSpan(
      style: const TextStyle(fontStyle: FontStyle.italic),
      text: widget.controller.value.text,
    );
  }
}
