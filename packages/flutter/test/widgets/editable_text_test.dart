// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert' show jsonDecode;
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';
import '../widgets/clipboard_utils.dart';
import 'editable_text_utils.dart';
import 'semantics_tester.dart';

Matcher matchesMethodCall(String method, { dynamic args }) => _MatchesMethodCall(method, arguments: args == null ? null : wrapMatcher(args));

class _MatchesMethodCall extends Matcher {
  const _MatchesMethodCall(this.name, {this.arguments});

  final String name;
  final Matcher? arguments;

  @override
  bool matches(dynamic item, Map<dynamic, dynamic> matchState) {
    if (item is MethodCall && item.method == name) {
      return arguments?.matches(item.arguments, matchState) ?? true;
    }
    return false;
  }

  @override
  Description describe(Description description) {
    final Description newDescription = description.add('has method name: ').addDescriptionOf(name);
    if (arguments != null) {
      newDescription.add(' with arguments: ').addDescriptionOf(arguments);
    }
    return newDescription;
  }
}

// Used to set window.viewInsets since the real ui.WindowPadding has only a
// private constructor.
class _TestWindowPadding implements ui.WindowPadding {
  const _TestWindowPadding({
    required this.bottom,
  });

  @override
  final double bottom;

  @override
  double get top => 0.0;

  @override
  double get left => 0.0;

  @override
  double get right => 0.0;
}

late TextEditingController controller;
final FocusNode focusNode = FocusNode(debugLabel: 'EditableText Node');
final FocusScopeNode focusScopeNode = FocusScopeNode(debugLabel: 'EditableText Scope Node');
const TextStyle textStyle = TextStyle();
const Color cursorColor = Color.fromARGB(0xFF, 0xFF, 0x00, 0x00);

enum HandlePositionInViewport {
  leftEdge, rightEdge, within,
}

typedef _VoidFutureCallback = Future<void> Function();

void main() {
  final MockClipboard mockClipboard = MockClipboard();
  TestWidgetsFlutterBinding.ensureInitialized()
    .defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, mockClipboard.handleMethodCall);

  setUp(() async {
    debugResetSemanticsIdCounter();
    controller = TextEditingController();
    // Fill the clipboard so that the Paste option is available in the text
    // selection menu.
    await Clipboard.setData(const ClipboardData(text: 'Clipboard data'));
  });

  tearDown(() {
    controller.dispose();
  });

  // Tests that the desired keyboard action button is requested.
  //
  // More technically, when an EditableText is given a particular [action], Flutter
  // requests [serializedActionName] when attaching to the platform's input
  // system.
  Future<void> desiredKeyboardActionIsRequested({
    required WidgetTester tester,
    TextInputAction? action,
    String serializedActionName = '',
  }) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: FocusScope(
            node: focusScopeNode,
            autofocus: true,
            child: EditableText(
              backgroundCursorColor: Colors.grey,
              controller: controller,
              focusNode: focusNode,
              textInputAction: action,
              style: textStyle,
              cursorColor: cursorColor,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(EditableText));
    await tester.showKeyboard(find.byType(EditableText));
    controller.text = 'test';
    await tester.idle();
    expect(tester.testTextInput.editingState!['text'], equals('test'));
    expect(tester.testTextInput.setClientArgs!['inputAction'], equals(serializedActionName));
  }

  // Related issue: https://github.com/flutter/flutter/issues/98115
  testWidgets('ScheduleShowCaretOnScreen with no animation when the window changes metrics', (WidgetTester tester) async {
    final ScrollController scrollController = ScrollController();
    final Widget widget = MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          controller: scrollController,
          child: Column(
            children: <Widget>[
              Column(
                children: List<Widget>.generate(
                  5,
                  (_) {
                    return Container(
                      height: 1200.0,
                      color: Colors.black12,
                    );
                  },
                ),
              ),
              SizedBox(
                height: 20,
                child: EditableText(
                  controller: TextEditingController(),
                  backgroundCursorColor: Colors.grey,
                  focusNode: focusNode,
                  style: const TextStyle(),
                  cursorColor: Colors.red,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpWidget(widget);
    await tester.showKeyboard(find.byType(EditableText));
    TestWidgetsFlutterBinding.instance.window.viewInsetsTestValue = const _TestWindowPadding(bottom: 500);
    await tester.pump();

    // The offset of the scrollController should change immediately after window changes its metrics.
    final double offsetAfter = scrollController.offset;
    expect(offsetAfter, isNot(0.0));
  });

  // Regression test for https://github.com/flutter/flutter/issues/34538.
  testWidgets('RTL arabic correct caret placement after trailing whitespace', (WidgetTester tester) async {
    final TextEditingController controller = TextEditingController();
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: FocusScope(
            node: focusScopeNode,
            autofocus: true,
            child: EditableText(
              backgroundCursorColor: Colors.blue,
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
    await tester.showKeyboard(find.byType(EditableText));
    await tester.idle();

    final EditableTextState state = tester.state<EditableTextState>(find.byType(EditableText));

    // Simulates Gboard Persian input.
    state.updateEditingValue(const TextEditingValue(text: 'گ', selection: TextSelection.collapsed(offset: 1)));
    await tester.pump();
    double previousCaretXPosition = state.renderEditable.getLocalRectForCaret(state.textEditingValue.selection.base).left;

    state.updateEditingValue(const TextEditingValue(text: 'گی', selection: TextSelection.collapsed(offset: 2)));
    await tester.pump();
    double caretXPosition = state.renderEditable.getLocalRectForCaret(state.textEditingValue.selection.base).left;
    expect(caretXPosition, lessThan(previousCaretXPosition));
    previousCaretXPosition = caretXPosition;

    state.updateEditingValue(const TextEditingValue(text: 'گیگ', selection: TextSelection.collapsed(offset: 3)));
    await tester.pump();
    caretXPosition = state.renderEditable.getLocalRectForCaret(state.textEditingValue.selection.base).left;
    expect(caretXPosition, lessThan(previousCaretXPosition));
    previousCaretXPosition = caretXPosition;

    // Enter a whitespace in a RTL input field moves the caret to the left.
    state.updateEditingValue(const TextEditingValue(text: 'گیگ ', selection: TextSelection.collapsed(offset: 4)));
    await tester.pump();
    caretXPosition = state.renderEditable.getLocalRectForCaret(state.textEditingValue.selection.base).left;
    expect(caretXPosition, lessThan(previousCaretXPosition));

    expect(state.currentTextEditingValue.text, equals('گیگ '));
  }, skip: isBrowser); // https://github.com/flutter/flutter/issues/78550.

  testWidgets('has expected defaults', (WidgetTester tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: EditableText(
            controller: controller,
            backgroundCursorColor: Colors.grey,
            focusNode: focusNode,
            style: textStyle,
            cursorColor: cursorColor,
          ),
        ),
      ),
    );

    final EditableText editableText =
        tester.firstWidget(find.byType(EditableText));
    expect(editableText.maxLines, equals(1));
    expect(editableText.obscureText, isFalse);
    expect(editableText.autocorrect, isTrue);
    expect(editableText.enableSuggestions, isTrue);
    expect(editableText.enableIMEPersonalizedLearning, isTrue);
    expect(editableText.textAlign, TextAlign.start);
    expect(editableText.cursorWidth, 2.0);
    expect(editableText.cursorHeight, isNull);
    expect(editableText.textHeightBehavior, isNull);
  });

  testWidgets('text keyboard is requested when maxLines is default', (WidgetTester tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: FocusScope(
            node: focusScopeNode,
            autofocus: true,
            child: EditableText(
              controller: controller,
              backgroundCursorColor: Colors.grey,
              focusNode: focusNode,
              style: textStyle,
              cursorColor: cursorColor,
            ),
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
    expect(tester.testTextInput.editingState!['text'], equals('test'));
    expect((tester.testTextInput.setClientArgs!['inputType'] as Map<String, dynamic>)['name'], equals('TextInputType.text'));
    expect(tester.testTextInput.setClientArgs!['inputAction'], equals('TextInputAction.done'));
  });

  testWidgets('Keyboard is configured for "unspecified" action when explicitly requested', (WidgetTester tester) async {
    await desiredKeyboardActionIsRequested(
      tester: tester,
      action: TextInputAction.unspecified,
      serializedActionName: 'TextInputAction.unspecified',
    );
  });

  testWidgets('Keyboard is configured for "none" action when explicitly requested', (WidgetTester tester) async {
    await desiredKeyboardActionIsRequested(
      tester: tester,
      action: TextInputAction.none,
      serializedActionName: 'TextInputAction.none',
    );
  });

  testWidgets('Keyboard is configured for "done" action when explicitly requested', (WidgetTester tester) async {
    await desiredKeyboardActionIsRequested(
      tester: tester,
      action: TextInputAction.done,
      serializedActionName: 'TextInputAction.done',
    );
  });

  testWidgets('Keyboard is configured for "send" action when explicitly requested', (WidgetTester tester) async {
    await desiredKeyboardActionIsRequested(
      tester: tester,
      action: TextInputAction.send,
      serializedActionName: 'TextInputAction.send',
    );
  });

  testWidgets('Keyboard is configured for "go" action when explicitly requested', (WidgetTester tester) async {
    await desiredKeyboardActionIsRequested(
      tester: tester,
      action: TextInputAction.go,
      serializedActionName: 'TextInputAction.go',
    );
  });

  testWidgets('Keyboard is configured for "search" action when explicitly requested', (WidgetTester tester) async {
    await desiredKeyboardActionIsRequested(
      tester: tester,
      action: TextInputAction.search,
      serializedActionName: 'TextInputAction.search',
    );
  });

  testWidgets('Keyboard is configured for "send" action when explicitly requested', (WidgetTester tester) async {
    await desiredKeyboardActionIsRequested(
      tester: tester,
      action: TextInputAction.send,
      serializedActionName: 'TextInputAction.send',
    );
  });

  testWidgets('Keyboard is configured for "next" action when explicitly requested', (WidgetTester tester) async {
    await desiredKeyboardActionIsRequested(
      tester: tester,
      action: TextInputAction.next,
      serializedActionName: 'TextInputAction.next',
    );
  });

  testWidgets('Keyboard is configured for "previous" action when explicitly requested', (WidgetTester tester) async {
    await desiredKeyboardActionIsRequested(
      tester: tester,
      action: TextInputAction.previous,
      serializedActionName: 'TextInputAction.previous',
    );
  });

  testWidgets('Keyboard is configured for "continue" action when explicitly requested', (WidgetTester tester) async {
    await desiredKeyboardActionIsRequested(
      tester: tester,
      action: TextInputAction.continueAction,
      serializedActionName: 'TextInputAction.continueAction',
    );
  });

  testWidgets('Keyboard is configured for "join" action when explicitly requested', (WidgetTester tester) async {
    await desiredKeyboardActionIsRequested(
      tester: tester,
      action: TextInputAction.join,
      serializedActionName: 'TextInputAction.join',
    );
  });

  testWidgets('Keyboard is configured for "route" action when explicitly requested', (WidgetTester tester) async {
    await desiredKeyboardActionIsRequested(
      tester: tester,
      action: TextInputAction.route,
      serializedActionName: 'TextInputAction.route',
    );
  });

  testWidgets('Keyboard is configured for "emergencyCall" action when explicitly requested', (WidgetTester tester) async {
    await desiredKeyboardActionIsRequested(
      tester: tester,
      action: TextInputAction.emergencyCall,
      serializedActionName: 'TextInputAction.emergencyCall',
    );
  });

  testWidgets('onAppPrivateCommand does not throw', (WidgetTester tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(),
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
    await tester.showKeyboard(find.byType(EditableText));
    controller.text = 'test';
    await tester.idle();

    final ByteData? messageBytes = const JSONMessageCodec().encodeMessage(<String, dynamic>{
      'args': <dynamic>[
        -1, // The magic clint id that points to the current client.
        jsonDecode('{"action": "actionCommand", "data": {"input_context" : "abcdefg"}}'),
      ],
      'method': 'TextInputClient.performPrivateCommand',
    });

    Object? error;
    try {
      await ServicesBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/textinput',
        messageBytes,
        (ByteData? _) {},
      );
    } catch (e) {
      error = e;
    }
    expect(error, isNull);
  });

  group('Infer keyboardType from autofillHints', () {
    testWidgets(
      'infer keyboard types from autofillHints: ios',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: FocusScope(
                node: focusScopeNode,
                autofocus: true,
                child: EditableText(
                  controller: controller,
                  backgroundCursorColor: Colors.grey,
                  focusNode: focusNode,
                  style: textStyle,
                  cursorColor: cursorColor,
                  autofillHints: const <String>[AutofillHints.streetAddressLine1],
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.byType(EditableText));
        await tester.showKeyboard(find.byType(EditableText));
        controller.text = 'test';
        await tester.idle();
        expect(tester.testTextInput.editingState!['text'], equals('test'));
        expect(
          (tester.testTextInput.setClientArgs!['inputType'] as Map<String, dynamic>)['name'],
          // On web, we don't infer the keyboard type as "name". We only infer
          // on iOS and macOS.
          kIsWeb ? equals('TextInputType.address') : equals('TextInputType.name'),
        );
      },
      variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.iOS,  TargetPlatform.macOS }),
    );

    testWidgets(
      'infer keyboard types from autofillHints: non-ios',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: FocusScope(
                node: focusScopeNode,
                autofocus: true,
                child: EditableText(
                  controller: controller,
                  backgroundCursorColor: Colors.grey,
                  focusNode: focusNode,
                  style: textStyle,
                  cursorColor: cursorColor,
                  autofillHints: const <String>[AutofillHints.streetAddressLine1],
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.byType(EditableText));
        await tester.showKeyboard(find.byType(EditableText));
        controller.text = 'test';
        await tester.idle();
        expect(tester.testTextInput.editingState!['text'], equals('test'));
        expect((tester.testTextInput.setClientArgs!['inputType'] as Map<String, dynamic>)['name'], equals('TextInputType.address'));
      },
    );

    testWidgets(
      'inferred keyboard types can be overridden: ios',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: FocusScope(
                node: focusScopeNode,
                autofocus: true,
                child: EditableText(
                  controller: controller,
                  backgroundCursorColor: Colors.grey,
                  focusNode: focusNode,
                  style: textStyle,
                  cursorColor: cursorColor,
                  keyboardType: TextInputType.text,
                  autofillHints: const <String>[AutofillHints.streetAddressLine1],
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.byType(EditableText));
        await tester.showKeyboard(find.byType(EditableText));
        controller.text = 'test';
        await tester.idle();
        expect(tester.testTextInput.editingState!['text'], equals('test'));
        expect((tester.testTextInput.setClientArgs!['inputType'] as Map<String, dynamic>)['name'], equals('TextInputType.text'));
      },
      variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.iOS,  TargetPlatform.macOS }),
    );

    testWidgets(
      'inferred keyboard types can be overridden: non-ios',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: FocusScope(
                node: focusScopeNode,
                autofocus: true,
                child: EditableText(
                  controller: controller,
                  backgroundCursorColor: Colors.grey,
                  focusNode: focusNode,
                  style: textStyle,
                  cursorColor: cursorColor,
                  keyboardType: TextInputType.text,
                  autofillHints: const <String>[AutofillHints.streetAddressLine1],
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.byType(EditableText));
        await tester.showKeyboard(find.byType(EditableText));
        controller.text = 'test';
        await tester.idle();
        expect(tester.testTextInput.editingState!['text'], equals('test'));
        expect((tester.testTextInput.setClientArgs!['inputType'] as Map<String, dynamic>)['name'], equals('TextInputType.text'));
      },
    );
  });

  testWidgets('multiline keyboard is requested when set explicitly', (WidgetTester tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: FocusScope(
            node: focusScopeNode,
            autofocus: true,
            child: EditableText(
              controller: controller,
              backgroundCursorColor: Colors.grey,
              focusNode: focusNode,
              keyboardType: TextInputType.multiline,
              style: textStyle,
              cursorColor: cursorColor,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(EditableText));
    await tester.showKeyboard(find.byType(EditableText));
    controller.text = 'test';
    await tester.idle();
    expect(tester.testTextInput.editingState!['text'], equals('test'));
    expect((tester.testTextInput.setClientArgs!['inputType'] as Map<String, dynamic>)['name'], equals('TextInputType.multiline'));
    expect(tester.testTextInput.setClientArgs!['inputAction'], equals('TextInputAction.newline'));
  });

  testWidgets('EditableText sends enableInteractiveSelection to config', (WidgetTester tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: FocusScope(
            node: focusScopeNode,
            autofocus: true,
            child: EditableText(
              enableInteractiveSelection: true,
              controller: controller,
              backgroundCursorColor: Colors.grey,
              focusNode: focusNode,
              keyboardType: TextInputType.multiline,
              style: textStyle,
              cursorColor: cursorColor,
            ),
          ),
        ),
      ),
    );

    EditableTextState state = tester.state<EditableTextState>(find.byType(EditableText));
    expect(state.textInputConfiguration.enableInteractiveSelection, isTrue);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: FocusScope(
            node: focusScopeNode,
            autofocus: true,
            child: EditableText(
              enableInteractiveSelection: false,
              controller: controller,
              backgroundCursorColor: Colors.grey,
              focusNode: focusNode,
              keyboardType: TextInputType.multiline,
              style: textStyle,
              cursorColor: cursorColor,
            ),
          ),
        ),
      ),
    );

    state = tester.state<EditableTextState>(find.byType(EditableText));
    expect(state.textInputConfiguration.enableInteractiveSelection, isFalse);
  });

  testWidgets('selection persists when unfocused', (WidgetTester tester) async {
    const TextEditingValue value = TextEditingValue(
      text: 'test test',
      selection: TextSelection(affinity: TextAffinity.upstream, baseOffset: 5, extentOffset: 7),
    );
    controller.value = value;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: EditableText(
            controller: controller,
            backgroundCursorColor: Colors.grey,
            focusNode: focusNode,
            keyboardType: TextInputType.multiline,
            style: textStyle,
            cursorColor: cursorColor,
          ),
        ),
      ),
    );

    expect(controller.value, value);
    expect(focusNode.hasFocus, isFalse);

    focusNode.requestFocus();
    await tester.pump();

    expect(controller.value, value);
    expect(focusNode.hasFocus, isTrue);

    focusNode.unfocus();
    await tester.pump();

    expect(controller.value, value);
    expect(focusNode.hasFocus, isFalse);
  });

  testWidgets('EditableText does not derive selection color from DefaultSelectionStyle', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/103341.
    const TextEditingValue value = TextEditingValue(
      text: 'test test',
      selection: TextSelection(affinity: TextAffinity.upstream, baseOffset: 5, extentOffset: 7),
    );
    const Color selectionColor = Colors.orange;
    controller.value = value;
    await tester.pumpWidget(
      DefaultSelectionStyle(
        selectionColor: selectionColor,
        child: MediaQuery(
          data: const MediaQueryData(),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: EditableText(
              controller: controller,
              backgroundCursorColor: Colors.grey,
              focusNode: focusNode,
              keyboardType: TextInputType.multiline,
              style: textStyle,
              cursorColor: cursorColor,
            ),
          ),
        )
      ),
    );
    final EditableTextState state = tester.state<EditableTextState>(find.byType(EditableText));
    expect(state.renderEditable.selectionColor, null);
  });

  testWidgets('visiblePassword keyboard is requested when set explicitly', (WidgetTester tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: FocusScope(
            node: focusScopeNode,
            autofocus: true,
            child: EditableText(
              controller: controller,
              backgroundCursorColor: Colors.grey,
              focusNode: focusNode,
              keyboardType: TextInputType.visiblePassword,
              style: textStyle,
              cursorColor: cursorColor,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(EditableText));
    await tester.showKeyboard(find.byType(EditableText));
    controller.text = 'test';
    await tester.idle();
    expect(tester.testTextInput.editingState!['text'], equals('test'));
    expect((tester.testTextInput.setClientArgs!['inputType'] as Map<String, dynamic>)['name'], equals('TextInputType.visiblePassword'));
    expect(tester.testTextInput.setClientArgs!['inputAction'], equals('TextInputAction.done'));
  });

  testWidgets('enableSuggestions flag is sent to the engine properly', (WidgetTester tester) async {
    final TextEditingController controller = TextEditingController();
    const bool enableSuggestions = false;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: FocusScope(
            node: focusScopeNode,
            autofocus: true,
            child: EditableText(
              controller: controller,
              backgroundCursorColor: Colors.grey,
              focusNode: focusNode,
              enableSuggestions: enableSuggestions,
              style: textStyle,
              cursorColor: cursorColor,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(EditableText));
    await tester.showKeyboard(find.byType(EditableText));
    await tester.idle();
    expect(tester.testTextInput.setClientArgs!['enableSuggestions'], enableSuggestions);
  });

  testWidgets('enableIMEPersonalizedLearning flag is sent to the engine properly', (WidgetTester tester) async {
    final TextEditingController controller = TextEditingController();
    const bool enableIMEPersonalizedLearning = false;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: FocusScope(
            node: focusScopeNode,
            autofocus: true,
            child: EditableText(
              controller: controller,
              backgroundCursorColor: Colors.grey,
              focusNode: focusNode,
              enableIMEPersonalizedLearning: enableIMEPersonalizedLearning,
              style: textStyle,
              cursorColor: cursorColor,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(EditableText));
    await tester.showKeyboard(find.byType(EditableText));
    await tester.idle();
    expect(tester.testTextInput.setClientArgs!['enableIMEPersonalizedLearning'], enableIMEPersonalizedLearning);
  });

  group('smartDashesType and smartQuotesType', () {
    testWidgets('sent to the engine properly', (WidgetTester tester) async {
      final TextEditingController controller = TextEditingController();
      const SmartDashesType smartDashesType = SmartDashesType.disabled;
      const SmartQuotesType smartQuotesType = SmartQuotesType.disabled;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: FocusScope(
              node: focusScopeNode,
              autofocus: true,
              child: EditableText(
                controller: controller,
                backgroundCursorColor: Colors.grey,
                focusNode: focusNode,
                smartDashesType: smartDashesType,
                smartQuotesType: smartQuotesType,
                style: textStyle,
                cursorColor: cursorColor,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(EditableText));
      await tester.showKeyboard(find.byType(EditableText));
      await tester.idle();
      expect(tester.testTextInput.setClientArgs!['smartDashesType'], smartDashesType.index.toString());
      expect(tester.testTextInput.setClientArgs!['smartQuotesType'], smartQuotesType.index.toString());
    });

    testWidgets('default to true when obscureText is false', (WidgetTester tester) async {
      final TextEditingController controller = TextEditingController();
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: FocusScope(
              node: focusScopeNode,
              autofocus: true,
              child: EditableText(
                controller: controller,
                backgroundCursorColor: Colors.grey,
                focusNode: focusNode,
                style: textStyle,
                cursorColor: cursorColor,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(EditableText));
      await tester.showKeyboard(find.byType(EditableText));
      await tester.idle();
      expect(tester.testTextInput.setClientArgs!['smartDashesType'], '1');
      expect(tester.testTextInput.setClientArgs!['smartQuotesType'], '1');
    });

    testWidgets('default to false when obscureText is true', (WidgetTester tester) async {
      final TextEditingController controller = TextEditingController();
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: FocusScope(
              node: focusScopeNode,
              autofocus: true,
              child: EditableText(
                controller: controller,
                backgroundCursorColor: Colors.grey,
                focusNode: focusNode,
                style: textStyle,
                cursorColor: cursorColor,
                obscureText: true,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(EditableText));
      await tester.showKeyboard(find.byType(EditableText));
      await tester.idle();
      expect(tester.testTextInput.setClientArgs!['smartDashesType'], '0');
      expect(tester.testTextInput.setClientArgs!['smartQuotesType'], '0');
    });
  });

  testWidgets('selection overlay will update when text grow bigger', (WidgetTester tester) async {
    final TextEditingController controller = TextEditingController.fromValue(
        const TextEditingValue(
          text: 'initial value',
        ),
    );
    Future<void> pumpEditableTextWithTextStyle(TextStyle style) async {
      await tester.pumpWidget(
        MaterialApp(
          home: EditableText(
            backgroundCursorColor: Colors.grey,
            controller: controller,
            focusNode: focusNode,
            style: style,
            cursorColor: cursorColor,
            selectionControls: materialTextSelectionControls,
            showSelectionHandles: true,
          ),
        ),
      );
    }

    await pumpEditableTextWithTextStyle(const TextStyle(fontSize: 18));
    final EditableTextState state = tester.state<EditableTextState>(find.byType(EditableText));
    state.renderEditable.selectWordsInRange(
      from: Offset.zero,
      cause: SelectionChangedCause.longPress,
    );
    await tester.pumpAndSettle();
    await tester.idle();

    List<RenderBox> handles = List<RenderBox>.from(
      tester.renderObjectList<RenderBox>(
        find.descendant(
          of: find.byType(CompositedTransformFollower),
          matching: find.byType(Padding),
        ),
      ),
    );

    expect(handles[0].localToGlobal(Offset.zero), const Offset(-35.0, 5.0));
    expect(handles[1].localToGlobal(Offset.zero), const Offset(113.0, 5.0));

    await pumpEditableTextWithTextStyle(const TextStyle(fontSize: 30));
    await tester.pumpAndSettle();

    // Handles should be updated with bigger font size.
    handles = List<RenderBox>.from(
      tester.renderObjectList<RenderBox>(
        find.descendant(
          of: find.byType(CompositedTransformFollower),
          matching: find.byType(Padding),
        ),
      ),
    );
    // First handle should have the same dx but bigger dy.
    expect(handles[0].localToGlobal(Offset.zero), const Offset(-35.0, 17.0));
    expect(handles[1].localToGlobal(Offset.zero), const Offset(197.0, 17.0));
  });

  testWidgets('can update style of previous activated EditableText', (WidgetTester tester) async {
    final Key key1 = UniqueKey();
    final Key key2 = UniqueKey();
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: FocusScope(
            node: focusScopeNode,
            autofocus: true,
            child: Column(
              children: <Widget>[
                EditableText(
                  key: key1,
                  controller: TextEditingController(),
                  backgroundCursorColor: Colors.grey,
                  focusNode: focusNode,
                  style: const TextStyle(fontSize: 9),
                  cursorColor: cursorColor,
                ),
                EditableText(
                  key: key2,
                  controller: TextEditingController(),
                  backgroundCursorColor: Colors.grey,
                  focusNode: focusNode,
                  style: const TextStyle(fontSize: 9),
                  cursorColor: cursorColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(key1));
    await tester.showKeyboard(find.byKey(key1));
    controller.text = 'test';
    await tester.idle();
    RenderBox renderEditable = tester.renderObject(find.byKey(key1));
    expect(renderEditable.size.height, 9.0);
    // Taps the other EditableText to deactivate the first one.
    await tester.tap(find.byKey(key2));
    await tester.showKeyboard(find.byKey(key2));
    // Updates the style.
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: FocusScope(
            node: focusScopeNode,
            autofocus: true,
            child: Column(
              children: <Widget>[
                EditableText(
                  key: key1,
                  controller: TextEditingController(),
                  backgroundCursorColor: Colors.grey,
                  focusNode: focusNode,
                  style: const TextStyle(fontSize: 20),
                  cursorColor: cursorColor,
                ),
                EditableText(
                  key: key2,
                  controller: TextEditingController(),
                  backgroundCursorColor: Colors.grey,
                  focusNode: focusNode,
                  style: const TextStyle(fontSize: 9),
                  cursorColor: cursorColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    renderEditable = tester.renderObject(find.byKey(key1));
    expect(renderEditable.size.height, 20.0);
    expect(tester.takeException(), null);
  });

  testWidgets('Multiline keyboard with newline action is requested when maxLines = null', (WidgetTester tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: FocusScope(
            node: focusScopeNode,
            autofocus: true,
            child: EditableText(
              controller: controller,
              backgroundCursorColor: Colors.grey,
              focusNode: focusNode,
              maxLines: null,
              style: textStyle,
              cursorColor: cursorColor,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(EditableText));
    await tester.showKeyboard(find.byType(EditableText));
    controller.text = 'test';
    await tester.idle();
    expect(tester.testTextInput.editingState!['text'], equals('test'));
    expect((tester.testTextInput.setClientArgs!['inputType'] as Map<String, dynamic>)['name'], equals('TextInputType.multiline'));
    expect(tester.testTextInput.setClientArgs!['inputAction'], equals('TextInputAction.newline'));
  });

  testWidgets('Text keyboard is requested when explicitly set and maxLines = null', (WidgetTester tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: FocusScope(
            node: focusScopeNode,
            autofocus: true,
            child: EditableText(
              backgroundCursorColor: Colors.grey,
              controller: controller,
              focusNode: focusNode,
              maxLines: null,
              keyboardType: TextInputType.text,
              style: textStyle,
              cursorColor: cursorColor,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(EditableText));
    await tester.showKeyboard(find.byType(EditableText));
    controller.text = 'test';
    await tester.idle();
    expect(tester.testTextInput.editingState!['text'], equals('test'));
    expect((tester.testTextInput.setClientArgs!['inputType'] as Map<String, dynamic>)['name'], equals('TextInputType.text'));
    expect(tester.testTextInput.setClientArgs!['inputAction'], equals('TextInputAction.done'));
  });

  testWidgets('Correct keyboard is requested when set explicitly and maxLines > 1', (WidgetTester tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: FocusScope(
            node: focusScopeNode,
            autofocus: true,
            child: EditableText(
              backgroundCursorColor: Colors.grey,
              controller: controller,
              focusNode: focusNode,
              keyboardType: TextInputType.phone,
              maxLines: 3,
              style: textStyle,
              cursorColor: cursorColor,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(EditableText));
    await tester.showKeyboard(find.byType(EditableText));
    controller.text = 'test';
    await tester.idle();
    expect(tester.testTextInput.editingState!['text'], equals('test'));
    expect((tester.testTextInput.setClientArgs!['inputType'] as Map<String, dynamic>)['name'], equals('TextInputType.phone'));
    expect(tester.testTextInput.setClientArgs!['inputAction'], equals('TextInputAction.done'));
  });

  testWidgets('multiline keyboard is requested when set implicitly', (WidgetTester tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: FocusScope(
            node: focusScopeNode,
            autofocus: true,
            child: EditableText(
              backgroundCursorColor: Colors.grey,
              controller: controller,
              focusNode: focusNode,
              maxLines: 3, // Sets multiline keyboard implicitly.
              style: textStyle,
              cursorColor: cursorColor,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(EditableText));
    await tester.showKeyboard(find.byType(EditableText));
    controller.text = 'test';
    await tester.idle();
    expect(tester.testTextInput.editingState!['text'], equals('test'));
    expect((tester.testTextInput.setClientArgs!['inputType'] as Map<String, dynamic>)['name'], equals('TextInputType.multiline'));
    expect(tester.testTextInput.setClientArgs!['inputAction'], equals('TextInputAction.newline'));
  });

  testWidgets('single line inputs have correct default keyboard', (WidgetTester tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(),
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
    await tester.showKeyboard(find.byType(EditableText));
    controller.text = 'test';
    await tester.idle();
    expect(tester.testTextInput.editingState!['text'], equals('test'));
    expect((tester.testTextInput.setClientArgs!['inputType'] as Map<String, dynamic>)['name'], equals('TextInputType.text'));
    expect(tester.testTextInput.setClientArgs!['inputAction'], equals('TextInputAction.done'));
  });

  testWidgets('connection is closed when TextInputClient.onConnectionClosed message received', (WidgetTester tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(),
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
    await tester.showKeyboard(find.byType(EditableText));
    controller.text = 'test';
    await tester.idle();

    final EditableTextState state =
        tester.state<EditableTextState>(find.byType(EditableText));
    expect(tester.testTextInput.editingState!['text'], equals('test'));
    expect(state.wantKeepAlive, true);

    tester.testTextInput.log.clear();
    tester.testTextInput.closeConnection();
    await tester.idle();

    // Widget does not have focus anymore.
    expect(state.wantKeepAlive, false);
    // No method calls are sent from the framework.
    // This makes sure hide/clearClient methods are not called after connection
    // closed.
    expect(tester.testTextInput.log, isEmpty);
  });

  testWidgets('closed connection reopened when user focused', (WidgetTester tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(),
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
    await tester.showKeyboard(find.byType(EditableText));
    controller.text = 'test3';
    await tester.idle();

    final EditableTextState state =
        tester.state<EditableTextState>(find.byType(EditableText));
    expect(tester.testTextInput.editingState!['text'], equals('test3'));
    expect(state.wantKeepAlive, true);

    tester.testTextInput.log.clear();
    tester.testTextInput.closeConnection();
    await tester.pumpAndSettle();

    // Widget does not have focus anymore.
    expect(state.wantKeepAlive, false);
    // No method calls are sent from the framework.
    // This makes sure hide/clearClient methods are not called after connection
    // closed.
    expect(tester.testTextInput.log, isEmpty);

    await tester.tap(find.byType(EditableText));
    await tester.showKeyboard(find.byType(EditableText));
    await tester.pump();
    controller.text = 'test2';
    expect(tester.testTextInput.editingState!['text'], equals('test2'));
    // Widget regained the focus.
    expect(state.wantKeepAlive, true);
  });

  testWidgets('closed connection reopened when user focused on another field', (WidgetTester tester) async {
    final EditableText testNameField =
      EditableText(
        backgroundCursorColor: Colors.grey,
        controller: controller,
        focusNode: focusNode,
        maxLines: null,
        keyboardType: TextInputType.text,
        style: textStyle,
        cursorColor: cursorColor,
      );

    final EditableText testPhoneField =
      EditableText(
        backgroundCursorColor: Colors.grey,
        controller: controller,
        focusNode: focusNode,
        keyboardType: TextInputType.phone,
        maxLines: 3,
        style: textStyle,
        cursorColor: cursorColor,
      );

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: FocusScope(
            node: focusScopeNode,
            autofocus: true,
            child: ListView(
              children: <Widget>[
                testNameField,
                testPhoneField,
              ],
            ),
          ),
        ),
      ),
    );

    // Tap, enter text.
    await tester.tap(find.byWidget(testNameField));
    await tester.showKeyboard(find.byWidget(testNameField));
    controller.text = 'test';
    await tester.idle();

    expect(tester.testTextInput.editingState!['text'], equals('test'));
    final EditableTextState state =
        tester.state<EditableTextState>(find.byWidget(testNameField));
    expect(state.wantKeepAlive, true);

    tester.testTextInput.log.clear();
    tester.testTextInput.closeConnection();
    // A pump is needed to allow the focus change (unfocus) to be resolved.
    await tester.pump();

    // Widget does not have focus anymore.
    expect(state.wantKeepAlive, false);
    // No method calls are sent from the framework.
    // This makes sure hide/clearClient methods are not called after connection
    // closed.
    expect(tester.testTextInput.log, isEmpty);

    // For the next fields, tap, enter text.
    await tester.tap(find.byWidget(testPhoneField));
    await tester.showKeyboard(find.byWidget(testPhoneField));
    controller.text = '650123123';
    await tester.idle();
    expect(tester.testTextInput.editingState!['text'], equals('650123123'));
    // Widget regained the focus.
    expect(state.wantKeepAlive, true);
  });

  testWidgets(
    'kept-alive EditableText does not crash when layout is skipped',
    (WidgetTester tester) async {
      // Regression test for https://github.com/flutter/flutter/issues/84896.
      EditableText.debugDeterministicCursor = true;
      const Key key = ValueKey<String>('EditableText');
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: ListView(
              children: <Widget>[
                EditableText(
                  key: key,
                  backgroundCursorColor: Colors.grey,
                  controller: controller,
                  focusNode: focusNode,
                  autofocus: true,
                  maxLines: null,
                  keyboardType: TextInputType.text,
                  style: textStyle,
                  textAlign: TextAlign.left,
                  cursorColor: cursorColor,
                  showCursor: false,
                ),
              ],
            ),
          ),
        ),
      );

      // Wait for autofocus.
      await tester.pump();
      expect(focusNode.hasFocus, isTrue);

      // Prepend an additional item to make EditableText invisible. It's still
      // kept in the tree via the keepalive mechanism. Change the text alignment
      // and showCursor. The RenderEditable now needs to relayout and repaint.
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: ListView(
              children: <Widget>[
                const SizedBox(height: 6000),
                EditableText(
                  key: key,
                  backgroundCursorColor: Colors.grey,
                  controller: controller,
                  focusNode: focusNode,
                  autofocus: true,
                  maxLines: null,
                  keyboardType: TextInputType.text,
                  style: textStyle,
                  textAlign: TextAlign.right,
                  cursorColor: cursorColor,
                  showCursor: true,
                ),
              ],
            ),
          ),
        ),
      );

      EditableText.debugDeterministicCursor = false;
      expect(tester.takeException(), isNull);
  });

  /// Toolbar is not used in Flutter Web. Skip this check.
  ///
  /// Web is using native DOM elements (it is also used as platform input)
  /// to enable clipboard functionality of the toolbar: copy, paste, select,
  /// cut. It might also provide additional functionality depending on the
  /// browser (such as translation). Due to this, in browsers, we should not
  /// show a Flutter toolbar for the editable text elements.
  testWidgets('can show toolbar when there is text and a selection', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: EditableText(
          backgroundCursorColor: Colors.grey,
          controller: controller,
          focusNode: focusNode,
          style: textStyle,
          cursorColor: cursorColor,
          selectionControls: materialTextSelectionControls,
        ),
      ),
    );

    final EditableTextState state =
        tester.state<EditableTextState>(find.byType(EditableText));

    // Can't show the toolbar when there's no focus.
    expect(state.showToolbar(), false);
    await tester.pumpAndSettle();
    expect(find.text('Paste'), findsNothing);

    // Can show the toolbar when focused even though there's no text.
    state.renderEditable.selectWordsInRange(
      from: Offset.zero,
      cause: SelectionChangedCause.tap,
    );
    await tester.pump();
    // On web, we don't let Flutter show the toolbar.
    expect(state.showToolbar(), kIsWeb ? isFalse : isTrue);
    await tester.pumpAndSettle();
    expect(find.text('Paste'), kIsWeb ? findsNothing : findsOneWidget);

    // Hide the menu again.
    state.hideToolbar();
    await tester.pump();
    expect(find.text('Paste'), findsNothing);

    // Can show the menu with text and a selection.
    controller.text = 'blah';
    await tester.pump();
    // On web, we don't let Flutter show the toolbar.
    expect(state.showToolbar(), kIsWeb ? isFalse : isTrue);
    await tester.pumpAndSettle();
    expect(find.text('Paste'), kIsWeb ? findsNothing : findsOneWidget);
  });

  testWidgets('can hide toolbar with DismissIntent', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: EditableText(
          backgroundCursorColor: Colors.grey,
          controller: controller,
          focusNode: focusNode,
          style: textStyle,
          cursorColor: cursorColor,
          selectionControls: materialTextSelectionControls,
        ),
      ),
    );

    final EditableTextState state =
      tester.state<EditableTextState>(find.byType(EditableText));

    // Show the toolbar
    state.renderEditable.selectWordsInRange(
      from: Offset.zero,
      cause: SelectionChangedCause.tap,
    );
    await tester.pump();

    // On web, we don't let Flutter show the toolbar.
    expect(state.showToolbar(), kIsWeb ? isFalse : isTrue);
    await tester.pumpAndSettle();
    expect(find.text('Paste'), kIsWeb ? findsNothing : findsOneWidget);

    // Hide the menu using the DismissIntent.
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(find.text('Paste'), findsNothing);
  });

  testWidgets('toolbar hidden on mobile when orientation changes', (WidgetTester tester) async {
    addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

    await tester.pumpWidget(
      MaterialApp(
        home: EditableText(
          backgroundCursorColor: Colors.grey,
          controller: controller,
          focusNode: focusNode,
          style: textStyle,
          cursorColor: cursorColor,
          selectionControls: materialTextSelectionControls,
        ),
      ),
    );

    final EditableTextState state =
      tester.state<EditableTextState>(find.byType(EditableText));

    // Show the toolbar
    state.renderEditable.selectWordsInRange(
      from: Offset.zero,
      cause: SelectionChangedCause.tap,
    );
    await tester.pump();

    expect(state.showToolbar(), true);
    await tester.pumpAndSettle();
    expect(find.text('Paste'), findsOneWidget);

    // Hide the menu by changing orientation.
    tester.binding.window.physicalSizeTestValue = const Size(1800.0, 2400.0);
    await tester.pumpAndSettle();
    expect(find.text('Paste'), findsNothing);

    // Handles should be hidden as well on Android
    expect(
      find.descendant(
        of: find.byType(CompositedTransformFollower),
        matching: find.byType(Padding),
      ),
      defaultTargetPlatform == TargetPlatform.android ? findsNothing : findsOneWidget,
    );

    // On web, we don't show the Flutter toolbar and instead rely on the browser
    // toolbar. Until we change that, this test should remain skipped.
  }, skip: kIsWeb, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.iOS, TargetPlatform.android })); // [intended]

  testWidgets('Paste is shown only when there is something to paste', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: EditableText(
          backgroundCursorColor: Colors.grey,
          controller: controller,
          focusNode: focusNode,
          style: textStyle,
          cursorColor: cursorColor,
          selectionControls: materialTextSelectionControls,
        ),
      ),
    );

    final EditableTextState state =
        tester.state<EditableTextState>(find.byType(EditableText));

    // Make sure the clipboard has a valid string on it.
    await Clipboard.setData(const ClipboardData(text: 'Clipboard data'));

    // Show the toolbar.
    state.renderEditable.selectWordsInRange(
      from: Offset.zero,
      cause: SelectionChangedCause.tap,
    );
    await tester.pump();

    // The Paste button is shown (except on web, which doesn't show the Flutter
    // toolbar).
    expect(state.showToolbar(), kIsWeb ? isFalse : isTrue);
    await tester.pumpAndSettle();
    expect(find.text('Paste'), kIsWeb ? findsNothing : findsOneWidget);

    // Hide the menu again.
    state.hideToolbar();
    await tester.pump();
    expect(find.text('Paste'), findsNothing);

    // Clear the clipboard
    await Clipboard.setData(const ClipboardData(text: ''));

    // Show the toolbar again.
    expect(state.showToolbar(), kIsWeb ? isFalse : isTrue);
    await tester.pumpAndSettle();

    // Paste is not shown.
    await tester.pumpAndSettle();
    expect(find.text('Paste'), findsNothing);
  });

  testWidgets('Copy selection does not collapse selection on desktop and iOS', (WidgetTester tester) async {
    final TextEditingController localController = TextEditingController(text: 'Hello world');
    await tester.pumpWidget(
      MaterialApp(
        home: EditableText(
          backgroundCursorColor: Colors.grey,
          controller: localController,
          focusNode: focusNode,
          style: textStyle,
          cursorColor: cursorColor,
          selectionControls: materialTextSelectionControls,
        ),
      ),
    );

    final EditableTextState state =
    tester.state<EditableTextState>(find.byType(EditableText));

    // Show the toolbar.
    state.renderEditable.selectWordsInRange(
      from: Offset.zero,
      cause: SelectionChangedCause.tap,
    );
    await tester.pump();

    final TextSelection copySelectionRange = localController.selection;

    state.showToolbar();
    await tester.pumpAndSettle();

    expect(find.text('Copy'), findsOneWidget);

    await tester.tap(find.text('Copy'));
    await tester.pumpAndSettle();
    expect(copySelectionRange, localController.selection);
    expect(find.text('Copy'), findsNothing);
  }, skip: kIsWeb, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.iOS, TargetPlatform.macOS, TargetPlatform.linux, TargetPlatform.windows })); // [intended]

  testWidgets('Copy selection collapses selection and hides the toolbar on Android and Fuchsia', (WidgetTester tester) async {
    final TextEditingController localController = TextEditingController(text: 'Hello world');
    await tester.pumpWidget(
      MaterialApp(
        home: EditableText(
          backgroundCursorColor: Colors.grey,
          controller: localController,
          focusNode: focusNode,
          style: textStyle,
          cursorColor: cursorColor,
          selectionControls: materialTextSelectionControls,
        ),
      ),
    );

    final EditableTextState state =
    tester.state<EditableTextState>(find.byType(EditableText));

    // Show the toolbar.
    state.renderEditable.selectWordsInRange(
      from: Offset.zero,
      cause: SelectionChangedCause.tap,
    );
    await tester.pump();

    final TextSelection copySelectionRange = localController.selection;

    state.showToolbar();
    await tester.pumpAndSettle();

    expect(find.text('Copy'), findsOneWidget);

    await tester.tap(find.text('Copy'));
    await tester.pumpAndSettle();
    expect(localController.selection, TextSelection.collapsed(offset: copySelectionRange.extentOffset));
    expect(find.text('Copy'), findsNothing);
  }, skip: kIsWeb, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.android, TargetPlatform.fuchsia })); // [intended]

  testWidgets('can show the toolbar after clearing all text', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/35998.
    await tester.pumpWidget(
      MaterialApp(
        home: EditableText(
          backgroundCursorColor: Colors.grey,
          controller: controller,
          focusNode: focusNode,
          style: textStyle,
          cursorColor: cursorColor,
          selectionControls: materialTextSelectionControls,
        ),
      ),
    );

    final EditableTextState state =
        tester.state<EditableTextState>(find.byType(EditableText));

    // Add text and an empty selection.
    controller.text = 'blah';
    await tester.pump();
    state.renderEditable.selectWordsInRange(
      from: Offset.zero,
      cause: SelectionChangedCause.tap,
    );
    await tester.pump();

    // Clear the text and selection.
    expect(find.text('Paste'), findsNothing);
    state.updateEditingValue(TextEditingValue.empty);
    await tester.pump();

    // Should be able to show the toolbar.
    // On web, we don't let Flutter show the toolbar.
    expect(state.showToolbar(), kIsWeb ? isFalse : isTrue);
    await tester.pumpAndSettle();
    expect(find.text('Paste'), kIsWeb ? findsNothing : findsOneWidget);
  });

  testWidgets('can dynamically disable options in toolbar', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: EditableText(
          backgroundCursorColor: Colors.grey,
          controller: TextEditingController(text: 'blah blah'),
          focusNode: focusNode,
          toolbarOptions: const ToolbarOptions(
            copy: true,
            selectAll: true,
          ),
          style: textStyle,
          cursorColor: cursorColor,
          selectionControls: materialTextSelectionControls,
        ),
      ),
    );

    final EditableTextState state =
    tester.state<EditableTextState>(find.byType(EditableText));

    // Select something. Doesn't really matter what.
    state.renderEditable.selectWordsInRange(
      from: Offset.zero,
      cause: SelectionChangedCause.tap,
    );
    await tester.pump();
    // On web, we don't let Flutter show the toolbar.
    expect(state.showToolbar(), kIsWeb ? isFalse : isTrue);
    await tester.pump();
    expect(find.text('Select all'), kIsWeb ? findsNothing : findsOneWidget);
    expect(find.text('Copy'), kIsWeb ? findsNothing : findsOneWidget);
    expect(find.text('Paste'), findsNothing);
    expect(find.text('Cut'), findsNothing);
  });

  testWidgets('can dynamically disable select all option in toolbar - cupertino', (WidgetTester tester) async {
    // Regression test: https://github.com/flutter/flutter/issues/40711
    await tester.pumpWidget(
      MaterialApp(
        home: EditableText(
          backgroundCursorColor: Colors.grey,
          controller: TextEditingController(text: 'blah blah'),
          focusNode: focusNode,
          toolbarOptions: const ToolbarOptions(),
          style: textStyle,
          cursorColor: cursorColor,
          selectionControls: cupertinoTextSelectionControls,
        ),
      ),
    );

    final EditableTextState state =
      tester.state<EditableTextState>(find.byType(EditableText));
    await tester.tap(find.byType(EditableText));
    await tester.pump();
    // On web, we don't let Flutter show the toolbar.
    expect(state.showToolbar(), kIsWeb ? isFalse : isTrue);
    await tester.pump();
    expect(find.text('Select All'), findsNothing);
    expect(find.text('Copy'), findsNothing);
    expect(find.text('Paste'), findsNothing);
    expect(find.text('Cut'), findsNothing);
  });

  testWidgets('can dynamically disable select all option in toolbar - material', (WidgetTester tester) async {
    // Regression test: https://github.com/flutter/flutter/issues/40711
    await tester.pumpWidget(
      MaterialApp(
        home: EditableText(
          backgroundCursorColor: Colors.grey,
          controller: TextEditingController(text: 'blah blah'),
          focusNode: focusNode,
          toolbarOptions: const ToolbarOptions(
            copy: true,
          ),
          style: textStyle,
          cursorColor: cursorColor,
          selectionControls: materialTextSelectionControls,
        ),
      ),
    );

    final EditableTextState state =
      tester.state<EditableTextState>(find.byType(EditableText));

    // Select something. Doesn't really matter what.
    state.renderEditable.selectWordsInRange(
      from: Offset.zero,
      cause: SelectionChangedCause.tap,
    );
    await tester.pump();
    // On web, we don't let Flutter show the toolbar.
    expect(state.showToolbar(),  kIsWeb ? isFalse : isTrue);
    await tester.pump();
    expect(find.text('Select all'), findsNothing);
    expect(find.text('Copy'),  kIsWeb ? findsNothing : findsOneWidget);
    expect(find.text('Paste'), findsNothing);
    expect(find.text('Cut'), findsNothing);
  });

  testWidgets('cut and paste are disabled in read only mode even if explicitly set', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: EditableText(
          backgroundCursorColor: Colors.grey,
          controller: TextEditingController(text: 'blah blah'),
          focusNode: focusNode,
          readOnly: true,
          toolbarOptions: const ToolbarOptions(
            copy: true,
            cut: true,
            paste: true,
            selectAll: true,
          ),
          style: textStyle,
          cursorColor: cursorColor,
          selectionControls: materialTextSelectionControls,
        ),
      ),
    );

    final EditableTextState state =
    tester.state<EditableTextState>(find.byType(EditableText));

    // Select something. Doesn't really matter what.
    state.renderEditable.selectWordsInRange(
      from: Offset.zero,
      cause: SelectionChangedCause.tap,
    );
    await tester.pump();
    // On web, we don't let Flutter show the toolbar.
    expect(state.showToolbar(), kIsWeb ? isFalse : isTrue);
    await tester.pump();
    expect(find.text('Select all'), kIsWeb ? findsNothing : findsOneWidget);
    expect(find.text('Copy'), kIsWeb ? findsNothing : findsOneWidget);
    expect(find.text('Paste'), findsNothing);
    expect(find.text('Cut'), findsNothing);
  });

  testWidgets('cut and copy are disabled in obscured mode even if explicitly set', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: EditableText(
          backgroundCursorColor: Colors.grey,
          controller: TextEditingController(text: 'blah blah'),
          focusNode: focusNode,
          obscureText: true,
          toolbarOptions: const ToolbarOptions(
            copy: true,
            cut: true,
            paste: true,
            selectAll: true,
          ),
          style: textStyle,
          cursorColor: cursorColor,
          selectionControls: materialTextSelectionControls,
        ),
      ),
    );

    final EditableTextState state =
    tester.state<EditableTextState>(find.byType(EditableText));
    await tester.tap(find.byType(EditableText));
    await tester.pump();
    // Select something, but not the whole thing.
    state.renderEditable.selectWord(cause: SelectionChangedCause.tap);
    await tester.pump();
    expect(state.selectAllEnabled, isTrue);
    expect(state.pasteEnabled, isTrue);
    expect(state.cutEnabled, isFalse);
    expect(state.copyEnabled, isFalse);

    // On web, we don't let Flutter show the toolbar.
    expect(state.showToolbar(), kIsWeb ? isFalse : isTrue);
    await tester.pump();
    expect(find.text('Select all'), kIsWeb ? findsNothing : findsOneWidget);
    expect(find.text('Copy'), findsNothing);
    expect(find.text('Paste'), kIsWeb ? findsNothing : findsOneWidget);
    expect(find.text('Cut'), findsNothing);
  });

  testWidgets('cut and copy do nothing in obscured mode even if explicitly called', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: EditableText(
          backgroundCursorColor: Colors.grey,
          controller: TextEditingController(text: 'blah blah'),
          focusNode: focusNode,
          obscureText: true,
          style: textStyle,
          cursorColor: cursorColor,
          selectionControls: materialTextSelectionControls,
        ),
      ),
    );

    final EditableTextState state =
    tester.state<EditableTextState>(find.byType(EditableText));
    expect(state.selectAllEnabled, isTrue);
    expect(state.pasteEnabled, isTrue);
    expect(state.cutEnabled, isFalse);
    expect(state.copyEnabled, isFalse);

    // Select all.
    state.selectAll(SelectionChangedCause.toolbar);
    await tester.pump();
    await Clipboard.setData(const ClipboardData(text: ''));
    state.cutSelection(SelectionChangedCause.toolbar);
    ClipboardData? data = await Clipboard.getData('text/plain');
    expect(data, isNotNull);
    expect(data!.text, isEmpty);

    state.selectAll(SelectionChangedCause.toolbar);
    await tester.pump();
    await Clipboard.setData(const ClipboardData(text: ''));
    state.copySelection(SelectionChangedCause.toolbar);
    data = await Clipboard.getData('text/plain');
    expect(data, isNotNull);
    expect(data!.text, isEmpty);
  });

  testWidgets('select all does nothing if obscured and read-only, even if explicitly called', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: EditableText(
          backgroundCursorColor: Colors.grey,
          controller: TextEditingController(text: 'blah blah'),
          focusNode: focusNode,
          obscureText: true,
          readOnly: true,
          style: textStyle,
          cursorColor: cursorColor,
          selectionControls: materialTextSelectionControls,
        ),
      ),
    );

    final EditableTextState state =
    tester.state<EditableTextState>(find.byType(EditableText));

    // Select all.
    state.selectAll(SelectionChangedCause.toolbar);
    expect(state.selectAllEnabled, isFalse);
    expect(state.textEditingValue.selection.isCollapsed, isTrue);
  });

  testWidgets('Handles the read-only flag correctly', (WidgetTester tester) async {
    final TextEditingController controller =
        TextEditingController(text: 'Lorem ipsum dolor sit amet');
    await tester.pumpWidget(
      MaterialApp(
        home: EditableText(
          readOnly: true,
          controller: controller,
          backgroundCursorColor: Colors.grey,
          focusNode: focusNode,
          style: textStyle,
          cursorColor: cursorColor,
        ),
      ),
    );

    // Interact with the field to establish the input connection.
    final Offset topLeft = tester.getTopLeft(find.byType(EditableText));
    await tester.tapAt(topLeft + const Offset(0.0, 5.0));
    await tester.pump();

    controller.selection = const TextSelection(baseOffset: 0, extentOffset: 5);
    await tester.pump();

    if (kIsWeb) {
      // On the web, a regular connection to the platform should've been made
      // with the `readOnly` flag set to true.
      expect(tester.testTextInput.hasAnyClients, isTrue);
      expect(tester.testTextInput.setClientArgs!['readOnly'], isTrue);
      expect(
        tester.testTextInput.editingState!['text'],
        'Lorem ipsum dolor sit amet',
      );
      expect(tester.testTextInput.editingState!['selectionBase'], 0);
      expect(tester.testTextInput.editingState!['selectionExtent'], 5);
    } else {
      // On non-web platforms, a read-only field doesn't need a connection with
      // the platform.
      expect(tester.testTextInput.hasAnyClients, isFalse);
    }
  });

  testWidgets('Does not accept updates when read-only', (WidgetTester tester) async {
    final TextEditingController controller =
        TextEditingController(text: 'Lorem ipsum dolor sit amet');
    await tester.pumpWidget(
      MaterialApp(
        home: EditableText(
          readOnly: true,
          controller: controller,
          backgroundCursorColor: Colors.grey,
          focusNode: focusNode,
          style: textStyle,
          cursorColor: cursorColor,
        ),
      ),
    );

    // Interact with the field to establish the input connection.
    final Offset topLeft = tester.getTopLeft(find.byType(EditableText));
    await tester.tapAt(topLeft + const Offset(0.0, 5.0));
    await tester.pump();

    expect(tester.testTextInput.hasAnyClients, kIsWeb ? isTrue : isFalse);
    if (kIsWeb) {
      // On the web, the input connection exists, but text updates should be
      // ignored.
      tester.testTextInput.updateEditingValue(const TextEditingValue(
        text: 'Foo bar',
        selection: TextSelection(baseOffset: 0, extentOffset: 3),
        composing: TextRange(start: 3, end: 4),
      ));
      // Only selection should change.
      expect(
        controller.value,
        const TextEditingValue(
          text: 'Lorem ipsum dolor sit amet',
          selection: TextSelection(baseOffset: 0, extentOffset: 3),
        ),
      );
    }
  });

  testWidgets('Read-only fields do not format text', (WidgetTester tester) async {
    late SelectionChangedCause selectionCause;

    final TextEditingController controller =
        TextEditingController(text: 'Lorem ipsum dolor sit amet');

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
          onSelectionChanged: (TextSelection selection, SelectionChangedCause? cause) {
            selectionCause = cause!;
          },
        ),
      ),
    );

    // Interact with the field to establish the input connection.
    final Offset topLeft = tester.getTopLeft(find.byType(EditableText));
    await tester.tapAt(topLeft + const Offset(0.0, 5.0));
    await tester.pump();

    expect(tester.testTextInput.hasAnyClients, kIsWeb ? isTrue : isFalse);
    if (kIsWeb) {
      tester.testTextInput.updateEditingValue(const TextEditingValue(
        text: 'Foo bar',
        selection: TextSelection(baseOffset: 0, extentOffset: 3),
      ));
      // On web, the only way a text field can be updated from the engine is if
      // a keyboard is used.
      expect(selectionCause, SelectionChangedCause.keyboard);
    }
  });

  testWidgets('Selection changes during Scribble interaction should have the scribble cause', (WidgetTester tester) async {
    late SelectionChangedCause selectionCause;

    final TextEditingController controller =
        TextEditingController(text: 'Lorem ipsum dolor sit amet');

    await tester.pumpWidget(
      MaterialApp(
        home: EditableText(
          controller: controller,
          backgroundCursorColor: Colors.grey,
          focusNode: focusNode,
          style: textStyle,
          cursorColor: cursorColor,
          selectionControls: materialTextSelectionControls,
          onSelectionChanged: (TextSelection selection, SelectionChangedCause? cause) {
            if (cause != null) {
              selectionCause = cause;
            }
          },
        ),
      ),
    );

    await tester.showKeyboard(find.byType(EditableText));

    // A normal selection update from the framework has 'keyboard' as the cause.
    tester.testTextInput.updateEditingValue(TextEditingValue(
      text: controller.text,
      selection: const TextSelection(baseOffset: 2, extentOffset: 3),
    ));
    await tester.pumpAndSettle();

    expect(selectionCause, SelectionChangedCause.keyboard);

    // A selection update during a scribble interaction has 'scribble' as the cause.
    await tester.testTextInput.startScribbleInteraction();
    tester.testTextInput.updateEditingValue(TextEditingValue(
      text: controller.text,
      selection: const TextSelection(baseOffset: 3, extentOffset: 4),
    ));
    await tester.pumpAndSettle();

    expect(selectionCause, SelectionChangedCause.scribble);
  }, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.iOS }));

  testWidgets('Requests focus and changes the selection when onScribbleFocus is called', (WidgetTester tester) async {
    final TextEditingController controller =
        TextEditingController(text: 'Lorem ipsum dolor sit amet');
    late SelectionChangedCause selectionCause;

    await tester.pumpWidget(
      MaterialApp(
        home: EditableText(
          controller: controller,
          backgroundCursorColor: Colors.grey,
          focusNode: focusNode,
          style: textStyle,
          cursorColor: cursorColor,
          selectionControls: materialTextSelectionControls,
          onSelectionChanged: (TextSelection selection, SelectionChangedCause? cause) {
            if (cause != null) {
              selectionCause = cause;
            }
          },
        ),
      ),
    );

    await tester.testTextInput.scribbleFocusElement(TextInput.scribbleClients.keys.first, Offset.zero);

    expect(focusNode.hasFocus, true);
    expect(selectionCause, SelectionChangedCause.scribble);

    // On web, we should rely on the browser's implementation of Scribble, so the selection changed cause
    // will never be SelectionChangedCause.scribble.
  }, skip: kIsWeb, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.iOS })); // [intended]

  testWidgets('Declares itself for Scribble interaction if the bounds overlap the scribble rect and the widget is touchable', (WidgetTester tester) async {
    final TextEditingController controller =
        TextEditingController(text: 'Lorem ipsum dolor sit amet');

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
    final TextEditingController controller =
        TextEditingController(text: 'Lorem ipsum dolor sit amet');

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
    final TextEditingController controller =
        TextEditingController(text: 'Lorem ipsum dolor sit amet');

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

  testWidgets('Sends "updateConfig" when read-only flag is flipped', (WidgetTester tester) async {
    bool readOnly = true;
    late StateSetter setState;
    final TextEditingController controller = TextEditingController(text: 'Lorem ipsum dolor sit amet');

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(builder: (BuildContext context, StateSetter stateSetter) {
          setState = stateSetter;
          return EditableText(
            readOnly: readOnly,
            controller: controller,
            backgroundCursorColor: Colors.grey,
            focusNode: focusNode,
            style: textStyle,
            cursorColor: cursorColor,
          );
        }),
      ),
    );

    // Interact with the field to establish the input connection.
    final Offset topLeft = tester.getTopLeft(find.byType(EditableText));
    await tester.tapAt(topLeft + const Offset(0.0, 5.0));
    await tester.pump();

    expect(tester.testTextInput.hasAnyClients, kIsWeb ? isTrue : isFalse);
    if (kIsWeb) {
      expect(tester.testTextInput.setClientArgs!['readOnly'], isTrue);
    }

    setState(() { readOnly = false; });
    await tester.pump();

    expect(tester.testTextInput.hasAnyClients, isTrue);
    expect(tester.testTextInput.setClientArgs!['readOnly'], isFalse);
  });

  testWidgets('Fires onChanged when text changes via TextSelectionOverlay', (WidgetTester tester) async {
    late String changedValue;
    final Widget widget = MaterialApp(
      home: EditableText(
        backgroundCursorColor: Colors.grey,
        controller: TextEditingController(),
        focusNode: FocusNode(),
        style: Typography.material2018().black.subtitle1!,
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
    Clipboard.setData(const ClipboardData(text: clipboardContent));

    // Long-press to bring up the text editing controls.
    final Finder textFinder = find.byType(EditableText);
    await tester.longPress(textFinder);
    tester.state<EditableTextState>(textFinder).showToolbar();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Paste'));
    await tester.pump();

    expect(changedValue, clipboardContent);

    // On web, we don't show the Flutter toolbar and instead rely on the browser
    // toolbar. Until we change that, this test should remain skipped.
  }, skip: kIsWeb); // [intended]

  // The variants to test in the focus handling test.
  final ValueVariant<TextInputAction> focusVariants = ValueVariant<
      TextInputAction>(
    TextInputAction.values.toSet(),
  );

  testWidgets('Handles focus correctly when action is invoked', (WidgetTester tester) async {
    // The expectations for each of the types of TextInputAction.
    const Map<TextInputAction, bool> actionShouldLoseFocus = <TextInputAction, bool>{
      TextInputAction.none: false,
      TextInputAction.unspecified: false,
      TextInputAction.done: true,
      TextInputAction.go: true,
      TextInputAction.search: true,
      TextInputAction.send: true,
      TextInputAction.continueAction: false,
      TextInputAction.join: false,
      TextInputAction.route: false,
      TextInputAction.emergencyCall: false,
      TextInputAction.newline: true,
      TextInputAction.next: true,
      TextInputAction.previous: true,
    };

    final TextInputAction action = focusVariants.currentValue!;
    expect(actionShouldLoseFocus.containsKey(action), isTrue);

    Future<void> ensureCorrectFocusHandlingForAction(
        TextInputAction action, {
          required bool shouldLoseFocus,
          bool shouldFocusNext = false,
          bool shouldFocusPrevious = false,
        }) async {
      final FocusNode focusNode = FocusNode();
      final GlobalKey previousKey = GlobalKey();
      final GlobalKey nextKey = GlobalKey();

      final Widget widget = MaterialApp(
        home: Column(
          children: <Widget>[
            TextButton(
              child: Text('Previous Widget', key: previousKey),
              onPressed: () {},
            ),
            EditableText(
              backgroundCursorColor: Colors.grey,
              controller: TextEditingController(),
              focusNode: focusNode,
              style: Typography.material2018().black.subtitle1!,
              cursorColor: Colors.blue,
              selectionControls: materialTextSelectionControls,
              keyboardType: TextInputType.text,
              autofocus: true,
            ),
            TextButton(
              child: Text('Next Widget', key: nextKey),
              onPressed: () {},
            ),
          ],
        ),
      );
      await tester.pumpWidget(widget);

      assert(focusNode.hasFocus);

      await tester.testTextInput.receiveAction(action);
      await tester.pump();

      expect(Focus.of(nextKey.currentContext!).hasFocus, equals(shouldFocusNext));
      expect(Focus.of(previousKey.currentContext!).hasFocus, equals(shouldFocusPrevious));
      expect(focusNode.hasFocus, equals(!shouldLoseFocus));
    }

    try {
      await ensureCorrectFocusHandlingForAction(
        action,
        shouldLoseFocus: actionShouldLoseFocus[action]!,
        shouldFocusNext: action == TextInputAction.next,
        shouldFocusPrevious: action == TextInputAction.previous,
      );
    } on PlatformException {
      // on Android, continueAction isn't supported.
      expect(action, equals(TextInputAction.continueAction));
    }
  }, variant: focusVariants);

  testWidgets('Does not lose focus by default when "done" action is pressed and onEditingComplete is provided', (WidgetTester tester) async {
    final FocusNode focusNode = FocusNode();

    final Widget widget = MaterialApp(
      home: EditableText(
        backgroundCursorColor: Colors.grey,
        controller: TextEditingController(),
        focusNode: focusNode,
        style: Typography.material2018().black.subtitle1!,
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
    final Finder textFinder = find.byType(EditableText);
    await tester.tap(textFinder);
    await tester.pump();

    assert(focusNode.hasFocus);

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    // Still has focus even though "done" was pressed because onEditingComplete
    // was provided and it overrides the default behavior.
    expect(focusNode.hasFocus, true);
  });

  testWidgets('When "done" is pressed callbacks are invoked: onEditingComplete > onSubmitted', (WidgetTester tester) async {
    final FocusNode focusNode = FocusNode();

    bool onEditingCompleteCalled = false;
    bool onSubmittedCalled = false;

    final Widget widget = MaterialApp(
      home: EditableText(
        backgroundCursorColor: Colors.grey,
        controller: TextEditingController(),
        focusNode: focusNode,
        style: Typography.material2018().black.subtitle1!,
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
    final Finder textFinder = find.byType(EditableText);
    await tester.tap(textFinder);
    await tester.pump();

    assert(focusNode.hasFocus);

    // The execution path starting with receiveAction() will trigger the
    // onEditingComplete and onSubmission callbacks.
    await tester.testTextInput.receiveAction(TextInputAction.done);

    // The expectations we care about are up above in the onEditingComplete
    // and onSubmission callbacks.
  });

  testWidgets('When "next" is pressed callbacks are invoked: onEditingComplete > onSubmitted', (WidgetTester tester) async {
    final FocusNode focusNode = FocusNode();

    bool onEditingCompleteCalled = false;
    bool onSubmittedCalled = false;

    final Widget widget = MaterialApp(
      home: EditableText(
        backgroundCursorColor: Colors.grey,
        controller: TextEditingController(),
        focusNode: focusNode,
        style: Typography.material2018().black.subtitle1!,
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
    final Finder textFinder = find.byType(EditableText);
    await tester.tap(textFinder);
    await tester.pump();

    assert(focusNode.hasFocus);

    // The execution path starting with receiveAction() will trigger the
    // onEditingComplete and onSubmission callbacks.
    await tester.testTextInput.receiveAction(TextInputAction.done);

    // The expectations we care about are up above in the onEditingComplete
    // and onSubmission callbacks.
  });

  testWidgets('When "newline" action is called on a Editable text with maxLines == 1 callbacks are invoked: onEditingComplete > onSubmitted', (WidgetTester tester) async {
    final FocusNode focusNode = FocusNode();

    bool onEditingCompleteCalled = false;
    bool onSubmittedCalled = false;

    final Widget widget = MaterialApp(
      home: EditableText(
        backgroundCursorColor: Colors.grey,
        controller: TextEditingController(),
        focusNode: focusNode,
        style: Typography.material2018().black.subtitle1!,
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
    final Finder textFinder = find.byType(EditableText);
    await tester.tap(textFinder);
    await tester.pump();

    assert(focusNode.hasFocus);

    // The execution path starting with receiveAction() will trigger the
    // onEditingComplete and onSubmission callbacks.
    await tester.testTextInput.receiveAction(TextInputAction.newline);
    // The expectations we care about are up above in the onEditingComplete
    // and onSubmission callbacks.
  });

  testWidgets('When "newline" action is called on a Editable text with maxLines != 1, onEditingComplete and onSubmitted callbacks are not invoked.', (WidgetTester tester) async {
    final FocusNode focusNode = FocusNode();

    bool onEditingCompleteCalled = false;
    bool onSubmittedCalled = false;

    final Widget widget = MaterialApp(
      home: EditableText(
        backgroundCursorColor: Colors.grey,
        controller: TextEditingController(),
        focusNode: focusNode,
        style: Typography.material2018().black.subtitle1!,
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
    final Finder textFinder = find.byType(EditableText);
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

  testWidgets(
    'finalizeEditing should reset the input connection when shouldUnfocus is true but the unfocus is cancelled',
    (WidgetTester tester) async {
      // Regression test for https://github.com/flutter/flutter/issues/84240 .
      Widget widget = MaterialApp(
        home: EditableText(
          backgroundCursorColor: Colors.grey,
          style: Typography.material2018().black.subtitle1!,
          cursorColor: Colors.blue,
          focusNode: focusNode,
          controller: controller,
          onSubmitted: (String value) {},
        ),
      );
      await tester.pumpWidget(widget);
      focusNode.requestFocus();
      await tester.pump();

      assert(focusNode.hasFocus);
      tester.testTextInput.log.clear();

      // This should unfocus the field. Don't restart the input.
      await tester.testTextInput.receiveAction(TextInputAction.done);
      expect(tester.testTextInput.log, isNot(containsAllInOrder(<Matcher>[
        matchesMethodCall('TextInput.clearClient'),
        matchesMethodCall('TextInput.setClient'),
      ])));

      widget = MaterialApp(
        home: EditableText(
          backgroundCursorColor: Colors.grey,
          style: Typography.material2018().black.subtitle1!,
          cursorColor: Colors.blue,
          focusNode: focusNode,
          controller: controller,
          onSubmitted: (String value) {
            focusNode.requestFocus();
          },
        ),
      );
      await tester.pumpWidget(widget);

      focusNode.requestFocus();
      await tester.pump();

      assert(focusNode.hasFocus);
      tester.testTextInput.log.clear();

      // This will attempt to unfocus the field but the onSubmitted callback
      // will cancel that. Restart the input connection in this case.
      await tester.testTextInput.receiveAction(TextInputAction.done);
      expect(tester.testTextInput.log, containsAllInOrder(<Matcher>[
        matchesMethodCall('TextInput.clearClient'),
        matchesMethodCall('TextInput.setClient'),
      ]));

      tester.testTextInput.log.clear();
      // TextInputAction.unspecified does not unfocus the input field by default.
      await tester.testTextInput.receiveAction(TextInputAction.unspecified);
      expect(tester.testTextInput.log, isNot(containsAllInOrder(<Matcher>[
        matchesMethodCall('TextInput.clearClient'),
        matchesMethodCall('TextInput.setClient'),
      ])));
  });

  testWidgets(
    'requesting focus in the onSubmitted callback should keep the onscreen keyboard visible',
    (WidgetTester tester) async {
      // Regression test for https://github.com/flutter/flutter/issues/95154 .
      final Widget widget = MaterialApp(
        home: EditableText(
          backgroundCursorColor: Colors.grey,
          style: Typography.material2018().black.subtitle1!,
          cursorColor: Colors.blue,
          focusNode: focusNode,
          controller: controller,
          onSubmitted: (String value) {
            focusNode.requestFocus();
          },
        ),
      );
      await tester.pumpWidget(widget);

      focusNode.requestFocus();
      await tester.pump();

      assert(focusNode.hasFocus);
      tester.testTextInput.log.clear();

      // This will attempt to unfocus the field but the onSubmitted callback
      // will cancel that. Restart the input connection in this case.
      await tester.testTextInput.receiveAction(TextInputAction.done);
      expect(tester.testTextInput.log, containsAllInOrder(<Matcher>[
        matchesMethodCall('TextInput.clearClient'),
        matchesMethodCall('TextInput.setClient'),
        matchesMethodCall('TextInput.show'),
      ]));

      tester.testTextInput.log.clear();
      // TextInputAction.unspecified does not unfocus the input field by default.
      await tester.testTextInput.receiveAction(TextInputAction.unspecified);
      expect(tester.testTextInput.log, isNot(containsAllInOrder(<Matcher>[
        matchesMethodCall('TextInput.clearClient'),
        matchesMethodCall('TextInput.setClient'),
        matchesMethodCall('TextInput.show'),
      ])));
  });

  testWidgets(
    'iOS autocorrection rectangle should appear on demand and dismiss when the text changes or when focus is lost',
    (WidgetTester tester) async {
      const Color rectColor = Color(0xFFFF0000);

      void verifyAutocorrectionRectVisibility({ required bool expectVisible }) {
        PaintPattern evaluate() {
          if (expectVisible) {
            return paints..something(((Symbol method, List<dynamic> arguments) {
              if (method != #drawRect) {
                return false;
              }
              final Paint paint = arguments[1] as Paint;
              return paint.color == rectColor;
            }));
          } else {
            return paints..everything(((Symbol method, List<dynamic> arguments) {
              if (method != #drawRect) {
                return true;
              }
              final Paint paint = arguments[1] as Paint;
              if (paint.color != rectColor) {
                return true;
              }
              throw 'Expected: autocorrection rect not visible, found: ${arguments[0]}';
            }));
          }
        }

        expect(findRenderEditable(tester), evaluate());
      }

      final FocusNode focusNode = FocusNode();
      final TextEditingController controller = TextEditingController(text: 'ABCDEFG');

      final Widget widget = MaterialApp(
        home: EditableText(
          backgroundCursorColor: Colors.grey,
          controller: controller,
          focusNode: focusNode,
          style: Typography.material2018().black.subtitle1!,
          cursorColor: Colors.blue,
          autocorrectionTextRectColor: rectColor,
          showCursor: false,
          onEditingComplete: () { },
        ),
      );

      await tester.pumpWidget(widget);

      await tester.tap(find.byType(EditableText));
      await tester.pump();
      final EditableTextState state = tester.state<EditableTextState>(find.byType(EditableText));

      assert(focusNode.hasFocus);

      // The prompt rect should be invisible initially.
      verifyAutocorrectionRectVisibility(expectVisible: false);

      state.showAutocorrectionPromptRect(0, 1);
      await tester.pump();

      // Show prompt rect when told to.
      verifyAutocorrectionRectVisibility(expectVisible: true);

      await tester.enterText(find.byType(EditableText), '12345');
      await tester.pump();
      verifyAutocorrectionRectVisibility(expectVisible: false);

      state.showAutocorrectionPromptRect(0, 1);
      await tester.pump();

      verifyAutocorrectionRectVisibility(expectVisible: true);

      // Unfocus, prompt rect should go away.
      focusNode.unfocus();
      await tester.pumpAndSettle();

      verifyAutocorrectionRectVisibility(expectVisible: false);
    },
  );

  testWidgets('Changing controller updates EditableText', (WidgetTester tester) async {
    final TextEditingController controller1 =
        TextEditingController(text: 'Wibble');
    final TextEditingController controller2 =
        TextEditingController(text: 'Wobble');
    TextEditingController currentController = controller1;
    late StateSetter setState;

    final FocusNode focusNode = FocusNode(debugLabel: 'EditableText Focus Node');
    Widget builder() {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setter) {
          setState = setter;
          return MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(),
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Center(
                  child: Material(
                    child: EditableText(
                      backgroundCursorColor: Colors.grey,
                      controller: currentController,
                      focusNode: focusNode,
                      style: Typography.material2018()
                          .black
                          .subtitle1!,
                      cursorColor: Colors.blue,
                      selectionControls: materialTextSelectionControls,
                      keyboardType: TextInputType.text,
                      onChanged: (String value) { },
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    await tester.pumpWidget(builder());
    await tester.pump(); // An extra pump to allow focus request to go through.

    final List<MethodCall> log = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.textInput, (MethodCall methodCall) async {
      log.add(methodCall);
      return null;
    });

    await tester.showKeyboard(find.byType(EditableText));

    // Verify TextInput.setEditingState and TextInput.setEditableSizeAndTransform are
    // both fired with updated text when controller is replaced.
    setState(() {
      currentController = controller2;
    });
    await tester.pump();

    expect(
      log.lastWhere((MethodCall m) => m.method == 'TextInput.setEditingState'),
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
      ),
    );
    expect(
      log.lastWhere((MethodCall m) => m.method == 'TextInput.setEditableSizeAndTransform'),
      isMethodCall(
        'TextInput.setEditableSizeAndTransform',
        arguments: <String, dynamic>{
          'width': 800,
          'height': 14,
          'transform': Matrix4.translationValues(0.0, 293.0, 0.0).storage.toList(),
        },
      ),
    );
  });

  testWidgets('EditableText identifies as text field (w/ focus) in semantics', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(),
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

    expect(semantics, includesNodeWith(flags: <SemanticsFlag>[SemanticsFlag.isTextField]));

    await tester.tap(find.byType(EditableText));
    await tester.idle();
    await tester.pump();

    expect(
      semantics,
      includesNodeWith(flags: <SemanticsFlag>[
        SemanticsFlag.isTextField,
        SemanticsFlag.isFocused,
      ]),
    );

    semantics.dispose();
  });

  testWidgets('EditableText sets multi-line flag in semantics', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(),
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

    expect(
      semantics,
      includesNodeWith(flags: <SemanticsFlag>[SemanticsFlag.isTextField]),
    );

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(),
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
              maxLines: 3,
            ),
          ),
        ),
      ),
    );

    expect(
      semantics,
      includesNodeWith(flags: <SemanticsFlag>[
        SemanticsFlag.isTextField,
        SemanticsFlag.isMultiline,
      ]),
    );

    semantics.dispose();
  });

  testWidgets('EditableText includes text as value in semantics', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    const String value1 = 'EditableText content';

    controller.text = value1;

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: FocusScope(
            node: focusScopeNode,
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

    expect(
      semantics,
      includesNodeWith(
        flags: <SemanticsFlag>[SemanticsFlag.isTextField],
        value: value1,
      ),
    );

    const String value2 = 'Changed the EditableText content';
    controller.text = value2;
    await tester.idle();
    await tester.pump();

    expect(
      semantics,
      includesNodeWith(
        flags: <SemanticsFlag>[SemanticsFlag.isTextField],
        value: value2,
      ),
    );

    semantics.dispose();
  });

  testWidgets('exposes correct cursor movement semantics', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    controller.text = 'test';

    await tester.pumpWidget(MaterialApp(
      home: EditableText(
        backgroundCursorColor: Colors.grey,
        controller: controller,
        focusNode: focusNode,
        style: textStyle,
        cursorColor: cursorColor,
      ),
    ));

    focusNode.requestFocus();
    await tester.pump();

    expect(
      semantics,
      includesNodeWith(
        value: 'test',
      ),
    );

    controller.selection =
        TextSelection.collapsed(offset:controller.text.length);
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
          SemanticsAction.setText,
        ],
      ),
    );

    controller.selection =
        TextSelection.collapsed(offset:controller.text.length - 2);
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
          SemanticsAction.setText,
        ],
      ),
    );

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
          SemanticsAction.setText,
        ],
      ),
    );

    semantics.dispose();
  });

  testWidgets('can move cursor with a11y means - character', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);
    const bool doNotExtendSelection = false;

    controller.text = 'test';
    controller.selection =
        TextSelection.collapsed(offset:controller.text.length);

    await tester.pumpWidget(MaterialApp(
      home: EditableText(
        backgroundCursorColor: Colors.grey,
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
      ),
    );

    final RenderEditable render = tester.allRenderObjects.whereType<RenderEditable>().first;
    final int semanticsId = render.debugSemantics!.id;

    expect(controller.selection.baseOffset, 4);
    expect(controller.selection.extentOffset, 4);

    tester.binding.pipelineOwner.semanticsOwner!.performAction(
      semanticsId,
      SemanticsAction.moveCursorBackwardByCharacter,
      doNotExtendSelection,
    );
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
        ],
      ),
    );

    tester.binding.pipelineOwner.semanticsOwner!.performAction(
      semanticsId,
      SemanticsAction.moveCursorBackwardByCharacter,
      doNotExtendSelection,
    );
    await tester.pumpAndSettle();
    tester.binding.pipelineOwner.semanticsOwner!.performAction(
      semanticsId,
      SemanticsAction.moveCursorBackwardByCharacter,
      doNotExtendSelection,
    );
    await tester.pumpAndSettle();
    tester.binding.pipelineOwner.semanticsOwner!.performAction(
      semanticsId,
      SemanticsAction.moveCursorBackwardByCharacter,
      doNotExtendSelection,
    );
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
        ],
      ),
    );

    tester.binding.pipelineOwner.semanticsOwner!.performAction(
      semanticsId,
      SemanticsAction.moveCursorForwardByCharacter,
      doNotExtendSelection,
    );
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
    TextSelection.collapsed(offset:controller.text.length);

    await tester.pumpWidget(MaterialApp(
      home: EditableText(
        backgroundCursorColor: Colors.grey,
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
      ),
    );

    final RenderEditable render = tester.allRenderObjects.whereType<RenderEditable>().first;
    final int semanticsId = render.debugSemantics!.id;

    expect(controller.selection.baseOffset, 14);
    expect(controller.selection.extentOffset, 14);

    tester.binding.pipelineOwner.semanticsOwner!.performAction(
      semanticsId,
      SemanticsAction.moveCursorBackwardByWord,
      doNotExtendSelection,
    );
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
        ],
      ),
    );

    tester.binding.pipelineOwner.semanticsOwner!.performAction(
      semanticsId,
      SemanticsAction.moveCursorBackwardByWord,
      doNotExtendSelection,
    );
    await tester.pumpAndSettle();

    expect(controller.selection.baseOffset, 5);
    expect(controller.selection.extentOffset, 5);

    tester.binding.pipelineOwner.semanticsOwner!.performAction(
      semanticsId,
      SemanticsAction.moveCursorBackwardByWord,
      doNotExtendSelection,
    );
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
        ],
      ),
    );

    tester.binding.pipelineOwner.semanticsOwner!.performAction(
      semanticsId,
      SemanticsAction.moveCursorForwardByWord,
      doNotExtendSelection,
    );
    await tester.pumpAndSettle();

    expect(controller.selection.baseOffset, 5);
    expect(controller.selection.extentOffset, 5);

    tester.binding.pipelineOwner.semanticsOwner!.performAction(
      semanticsId,
      SemanticsAction.moveCursorForwardByWord,
      doNotExtendSelection,
    );
    await tester.pumpAndSettle();

    expect(controller.selection.baseOffset, 9);
    expect(controller.selection.extentOffset, 9);

    semantics.dispose();
  });

  testWidgets('can extend selection with a11y means - character', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);
    const bool extendSelection = true;
    const bool doNotExtendSelection = false;

    controller.text = 'test';
    controller.selection =
        TextSelection.collapsed(offset:controller.text.length);

    await tester.pumpWidget(MaterialApp(
      home: EditableText(
        backgroundCursorColor: Colors.grey,
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
      ),
    );

    final RenderEditable render = tester.allRenderObjects.whereType<RenderEditable>().first;
    final int semanticsId = render.debugSemantics!.id;

    expect(controller.selection.baseOffset, 4);
    expect(controller.selection.extentOffset, 4);

    tester.binding.pipelineOwner.semanticsOwner!.performAction(
      semanticsId,
      SemanticsAction.moveCursorBackwardByCharacter,
      extendSelection,
    );
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
        ],
      ),
    );

    tester.binding.pipelineOwner.semanticsOwner!.performAction(
      semanticsId,
      SemanticsAction.moveCursorBackwardByCharacter,
      extendSelection,
    );
    await tester.pumpAndSettle();
    tester.binding.pipelineOwner.semanticsOwner!.performAction(
      semanticsId,
      SemanticsAction.moveCursorBackwardByCharacter,
      extendSelection,
    );
    await tester.pumpAndSettle();
    tester.binding.pipelineOwner.semanticsOwner!.performAction(
      semanticsId,
      SemanticsAction.moveCursorBackwardByCharacter,
      extendSelection,
    );
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
        ],
      ),
    );

    tester.binding.pipelineOwner.semanticsOwner!.performAction(
      semanticsId,
      SemanticsAction.moveCursorForwardByCharacter,
      doNotExtendSelection,
    );
    await tester.pumpAndSettle();

    expect(controller.selection.baseOffset, 1);
    expect(controller.selection.extentOffset, 1);

    tester.binding.pipelineOwner.semanticsOwner!.performAction(
      semanticsId,
      SemanticsAction.moveCursorForwardByCharacter,
      extendSelection,
    );
    await tester.pumpAndSettle();

    expect(controller.selection.baseOffset, 1);
    expect(controller.selection.extentOffset, 2);

    semantics.dispose();
  });

  testWidgets('can extend selection with a11y means - word', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);
    const bool extendSelection = true;
    const bool doNotExtendSelection = false;

    controller.text = 'test for words';
    controller.selection =
    TextSelection.collapsed(offset:controller.text.length);

    await tester.pumpWidget(MaterialApp(
      home: EditableText(
        backgroundCursorColor: Colors.grey,
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
      ),
    );

    final RenderEditable render = tester.allRenderObjects.whereType<RenderEditable>().first;
    final int semanticsId = render.debugSemantics!.id;

    expect(controller.selection.baseOffset, 14);
    expect(controller.selection.extentOffset, 14);

    tester.binding.pipelineOwner.semanticsOwner!.performAction(
      semanticsId,
      SemanticsAction.moveCursorBackwardByWord,
      extendSelection,
    );
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
        ],
      ),
    );

    tester.binding.pipelineOwner.semanticsOwner!.performAction(
      semanticsId,
      SemanticsAction.moveCursorBackwardByWord,
      extendSelection,
    );
    await tester.pumpAndSettle();

    expect(controller.selection.baseOffset, 14);
    expect(controller.selection.extentOffset, 5);

    tester.binding.pipelineOwner.semanticsOwner!.performAction(
      semanticsId,
      SemanticsAction.moveCursorBackwardByWord,
      extendSelection,
    );
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
        ],
      ),
    );

    tester.binding.pipelineOwner.semanticsOwner!.performAction(
      semanticsId,
      SemanticsAction.moveCursorForwardByWord,
      doNotExtendSelection,
    );
    await tester.pumpAndSettle();

    expect(controller.selection.baseOffset, 5);
    expect(controller.selection.extentOffset, 5);

    tester.binding.pipelineOwner.semanticsOwner!.performAction(
      semanticsId,
      SemanticsAction.moveCursorForwardByWord,
      extendSelection,
    );
    await tester.pumpAndSettle();

    expect(controller.selection.baseOffset, 5);
    expect(controller.selection.extentOffset, 9);

    semantics.dispose();
  });

  testWidgets('password fields have correct semantics', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    controller.text = 'super-secret-password!!1';

    await tester.pumpWidget(MaterialApp(
      home: EditableText(
        backgroundCursorColor: Colors.grey,
        obscureText: true,
        controller: controller,
        focusNode: focusNode,
        style: textStyle,
        cursorColor: cursorColor,
      ),
    ));

    final String expectedValue = '•' *controller.text.length;

    expect(
      semantics,
      hasSemantics(
        TestSemantics(
          children: <TestSemantics>[
            TestSemantics.rootChild(
              children: <TestSemantics>[
                TestSemantics(
                  children: <TestSemantics>[
                    TestSemantics(
                      flags: <SemanticsFlag>[SemanticsFlag.scopesRoute],
                      children: <TestSemantics>[
                        TestSemantics(
                          flags: <SemanticsFlag>[
                            SemanticsFlag.isTextField,
                            SemanticsFlag.isObscured,
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
          ],
        ),
        ignoreTransform: true,
        ignoreRect: true,
        ignoreId: true,
      ),
    );

    semantics.dispose();
  });

  testWidgets('password fields become obscured with the right semantics when set', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    const String originalText = 'super-secret-password!!1';
    controller.text = originalText;

    await tester.pumpWidget(MaterialApp(
      home: EditableText(
        backgroundCursorColor: Colors.grey,
        controller: controller,
        focusNode: focusNode,
        style: textStyle,
        cursorColor: cursorColor,
      ),
    ));

    final String expectedValue = '•' * originalText.length;

    expect(
      semantics,
      hasSemantics(
        TestSemantics(
          children: <TestSemantics>[
            TestSemantics.rootChild(
              children: <TestSemantics>[
                TestSemantics(
                  children:<TestSemantics>[
                    TestSemantics(
                      flags: <SemanticsFlag>[SemanticsFlag.scopesRoute],
                      children: <TestSemantics>[
                        TestSemantics(
                          flags: <SemanticsFlag>[
                            SemanticsFlag.isTextField,
                          ],
                          value: originalText,
                          textDirection: TextDirection.ltr,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        ignoreTransform: true,
        ignoreRect: true,
        ignoreId: true,
      ),
    );

    focusNode.requestFocus();

    // Now change it to make it obscure text.
    await tester.pumpWidget(MaterialApp(
      home: EditableText(
        backgroundCursorColor: Colors.grey,
        controller: controller,
        obscureText: true,
        focusNode: focusNode,
        style: textStyle,
        cursorColor: cursorColor,
      ),
    ));

    expect((findRenderEditable(tester).text! as TextSpan).text, expectedValue);

    expect(
      semantics,
      hasSemantics(
        TestSemantics(
          children: <TestSemantics>[
            TestSemantics.rootChild(
              children: <TestSemantics>[
                TestSemantics(
                  children:<TestSemantics>[
                    TestSemantics(
                      flags: <SemanticsFlag>[SemanticsFlag.scopesRoute],
                      children: <TestSemantics>[
                        TestSemantics(
                          flags: <SemanticsFlag>[
                            SemanticsFlag.isTextField,
                            SemanticsFlag.isObscured,
                            SemanticsFlag.isFocused,
                          ],
                          actions: <SemanticsAction>[
                            SemanticsAction.moveCursorBackwardByCharacter,
                            SemanticsAction.setSelection,
                            SemanticsAction.setText,
                            SemanticsAction.moveCursorBackwardByWord,
                          ],
                          value: expectedValue,
                          textDirection: TextDirection.ltr,
                          textSelection: const TextSelection.collapsed(offset: 24),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        ignoreTransform: true,
        ignoreRect: true,
        ignoreId: true,
      ),
    );

    semantics.dispose();
  });

  testWidgets('password fields can have their obscuring character customized', (WidgetTester tester) async {
    const String originalText = 'super-secret-password!!1';
    controller.text = originalText;

    const String obscuringCharacter = '#';
    await tester.pumpWidget(MaterialApp(
      home: EditableText(
        backgroundCursorColor: Colors.grey,
        controller: controller,
        obscuringCharacter: obscuringCharacter,
        obscureText: true,
        focusNode: focusNode,
        style: textStyle,
        cursorColor: cursorColor,
      ),
    ));

    final String expectedValue = obscuringCharacter * originalText.length;
    expect((findRenderEditable(tester).text! as TextSpan).text, expectedValue);
  });

  testWidgets('password briefly shows last character when entered on mobile', (WidgetTester tester) async {
    final bool debugDeterministicCursor = EditableText.debugDeterministicCursor;
    EditableText.debugDeterministicCursor = false;
    addTearDown(() {
      EditableText.debugDeterministicCursor = debugDeterministicCursor;
    });

    await tester.pumpWidget(MaterialApp(
      home: EditableText(
        backgroundCursorColor: Colors.grey,
        controller: controller,
        obscureText: true,
        focusNode: focusNode,
        style: textStyle,
        cursorColor: cursorColor,
      ),
    ));

    await tester.enterText(find.byType(EditableText), 'AA');
    await tester.pump();
    await tester.enterText(find.byType(EditableText), 'AAA');
    await tester.pump();

    expect((findRenderEditable(tester).text! as TextSpan).text, '••A');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    expect((findRenderEditable(tester).text! as TextSpan).text, '•••');
  });

  group('a11y copy/cut/paste', () {
    Future<void> buildApp(MockTextSelectionControls controls, WidgetTester tester) {
      return tester.pumpWidget(MaterialApp(
        home: EditableText(
          backgroundCursorColor: Colors.grey,
          controller: controller,
          focusNode: focusNode,
          style: textStyle,
          cursorColor: cursorColor,
          selectionControls: controls,
        ),
      ));
    }

    late MockTextSelectionControls controls;

    setUp(() {
      controller.text = 'test';
      controller.selection =
          TextSelection.collapsed(offset:controller.text.length);

      controls = MockTextSelectionControls();
    });

    testWidgets('are exposed', (WidgetTester tester) async {
      final SemanticsTester semantics = SemanticsTester(tester);
      addTearDown(semantics.dispose);

      controls.testCanCopy = false;
      controls.testCanCut = false;
      controls.testCanPaste = false;

      await buildApp(controls, tester);
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
            SemanticsAction.setText,
          ],
        ),
      );

      controls.testCanCopy = true;
      await buildApp(controls, tester);
      expect(
        semantics,
        includesNodeWith(
          value: 'test',
          actions: <SemanticsAction>[
            SemanticsAction.moveCursorBackwardByCharacter,
            SemanticsAction.moveCursorBackwardByWord,
            SemanticsAction.setSelection,
            SemanticsAction.setText,
            SemanticsAction.copy,
          ],
        ),
      );

      controls.testCanCopy = false;
      controls.testCanPaste = true;
      await buildApp(controls, tester);
      await tester.pumpAndSettle();
      expect(
        semantics,
        includesNodeWith(
          value: 'test',
          actions: <SemanticsAction>[
            SemanticsAction.moveCursorBackwardByCharacter,
            SemanticsAction.moveCursorBackwardByWord,
            SemanticsAction.setSelection,
            SemanticsAction.setText,
            SemanticsAction.paste,
          ],
        ),
      );

      controls.testCanPaste = false;
      controls.testCanCut = true;
      await buildApp(controls, tester);
      expect(
        semantics,
        includesNodeWith(
          value: 'test',
          actions: <SemanticsAction>[
            SemanticsAction.moveCursorBackwardByCharacter,
            SemanticsAction.moveCursorBackwardByWord,
            SemanticsAction.setSelection,
            SemanticsAction.setText,
            SemanticsAction.cut,
          ],
        ),
      );

      controls.testCanCopy = true;
      controls.testCanCut = true;
      controls.testCanPaste = true;
      await buildApp(controls, tester);
      expect(
        semantics,
        includesNodeWith(
          value: 'test',
          actions: <SemanticsAction>[
            SemanticsAction.moveCursorBackwardByCharacter,
            SemanticsAction.moveCursorBackwardByWord,
            SemanticsAction.setSelection,
            SemanticsAction.setText,
            SemanticsAction.cut,
            SemanticsAction.copy,
            SemanticsAction.paste,
          ],
        ),
      );
    });

    testWidgets('can copy/cut/paste with a11y', (WidgetTester tester) async {
      final SemanticsTester semantics = SemanticsTester(tester);

      controls.testCanCopy = true;
      controls.testCanCut = true;
      controls.testCanPaste = true;
      await buildApp(controls, tester);
      await tester.tap(find.byType(EditableText));
      await tester.pump();

      final SemanticsOwner owner = tester.binding.pipelineOwner.semanticsOwner!;
      const int expectedNodeId = 5;

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
                    children: <TestSemantics>[
                      TestSemantics(
                        id: 3,
                        flags: <SemanticsFlag>[SemanticsFlag.scopesRoute],
                        children: <TestSemantics>[
                          TestSemantics.rootChild(
                            id: expectedNodeId,
                            flags: <SemanticsFlag>[
                              SemanticsFlag.isTextField,
                              SemanticsFlag.isFocused,
                            ],
                            actions: <SemanticsAction>[
                              SemanticsAction.moveCursorBackwardByCharacter,
                              SemanticsAction.moveCursorBackwardByWord,
                              SemanticsAction.setSelection,
                              SemanticsAction.setText,
                              SemanticsAction.copy,
                              SemanticsAction.cut,
                              SemanticsAction.paste,
                            ],
                            value: 'test',
                            textSelection: TextSelection.collapsed(offset: controller.text.length),
                            textDirection: TextDirection.ltr,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          ignoreRect: true,
          ignoreTransform: true,
        ),
      );

      owner.performAction(expectedNodeId, SemanticsAction.copy);
      expect(controls.copyCount, 1);

      owner.performAction(expectedNodeId, SemanticsAction.cut);
      expect(controls.cutCount, 1);

      owner.performAction(expectedNodeId, SemanticsAction.paste);
      expect(controls.pasteCount, 1);

      semantics.dispose();
    });

    // Regression test for b/201218542.
    testWidgets('copying with a11y works even when toolbar is hidden', (WidgetTester tester) async {
      Future<void> testByControls(TextSelectionControls controls) async {
        final SemanticsTester semantics = SemanticsTester(tester);
        final TextEditingController controller = TextEditingController(text: 'ABCDEFG');

        await tester.pumpWidget(MaterialApp(
          home: EditableText(
            backgroundCursorColor: Colors.grey,
            controller: controller,
            focusNode: focusNode,
            style: textStyle,
            cursorColor: cursorColor,
            selectionControls: controls,
          ),
        ));
        await tester.tap(find.byType(EditableText));
        await tester.pump();

        final SemanticsOwner owner = tester.binding.pipelineOwner.semanticsOwner!;
        const int expectedNodeId = 5;

        expect(controller.value.selection.isCollapsed, isTrue);

        controller.selection = TextSelection(
          baseOffset: 0,
          extentOffset: controller.value.text.length,
        );
        await tester.pump();

        expect(find.text('Copy'), findsNothing);

        owner.performAction(expectedNodeId, SemanticsAction.copy);
        expect(tester.takeException(), isNull);
        expect(
          (await Clipboard.getData(Clipboard.kTextPlain))!.text,
          equals('ABCDEFG'),
        );

        semantics.dispose();
      }
      await testByControls(materialTextSelectionControls);
      await testByControls(cupertinoTextSelectionControls);
    });
  });

  testWidgets('can set text with a11y', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);
    await tester.pumpWidget(MaterialApp(
      home: EditableText(
        backgroundCursorColor: Colors.grey,
        controller: controller,
        focusNode: focusNode,
        style: textStyle,
        cursorColor: cursorColor,
      ),
    ));
    await tester.tap(find.byType(EditableText));
    await tester.pump();

    final SemanticsOwner owner = tester.binding.pipelineOwner.semanticsOwner!;
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
                  children: <TestSemantics>[
                    TestSemantics(
                      id: 3,
                      flags: <SemanticsFlag>[SemanticsFlag.scopesRoute],
                      children: <TestSemantics>[
                        TestSemantics.rootChild(
                          id: expectedNodeId,
                          flags: <SemanticsFlag>[
                            SemanticsFlag.isTextField,
                            SemanticsFlag.isFocused,
                          ],
                          actions: <SemanticsAction>[
                            SemanticsAction.setSelection,
                            SemanticsAction.setText,
                          ],
                          textSelection: TextSelection.collapsed(offset: controller.text.length),
                          textDirection: TextDirection.ltr,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        ignoreRect: true,
        ignoreTransform: true,
      ),
    );

    expect(controller.text, '');
    owner.performAction(expectedNodeId, SemanticsAction.setText, 'how are you');
    expect(controller.text, 'how are you');

    semantics.dispose();
  });

  testWidgets('allows customizing text style in subclasses', (WidgetTester tester) async {
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
    final RenderEditable render = tester.allRenderObjects.whereType<RenderEditable>().first;
    expect(render.text!.style!.fontStyle, FontStyle.italic);
  });

  testWidgets('Formatters are skipped if text has not changed', (WidgetTester tester) async {
    int called = 0;
    final TextInputFormatter formatter = TextInputFormatter.withFunction((TextEditingValue oldValue, TextEditingValue newValue) {
      called += 1;
      return newValue;
    });
    final TextEditingController controller = TextEditingController();
    final MediaQuery mediaQuery = MediaQuery(
      data: const MediaQueryData(),
      child: EditableText(
        controller: controller,
        backgroundCursorColor: Colors.red,
        cursorColor: Colors.red,
        focusNode: FocusNode(),
        style: textStyle,
        inputFormatters: <TextInputFormatter>[
          formatter,
        ],
        textDirection: TextDirection.ltr,
      ),
    );
    await tester.pumpWidget(mediaQuery);
    final EditableTextState state = tester.firstState(find.byType(EditableText));
    state.updateEditingValue(const TextEditingValue(
      text: 'a',
    ));
    expect(called, 1);
    // same value.
    state.updateEditingValue(const TextEditingValue(
      text: 'a',
    ));
    expect(called, 1);
    // same value with different selection.
    state.updateEditingValue(const TextEditingValue(
      text: 'a',
      selection: TextSelection.collapsed(offset: 1),
    ));
    // different value.
    state.updateEditingValue(const TextEditingValue(
      text: 'b',
    ));
    expect(called, 2);
  });

  testWidgets('default keyboardAppearance is respected', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/22212.

    final List<MethodCall> log = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.textInput, (MethodCall methodCall) async {
      log.add(methodCall);
      return null;
    });

    final TextEditingController controller = TextEditingController();
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: EditableText(
            controller: controller,
            focusNode: FocusNode(),
            style: Typography.material2018().black.subtitle1!,
            cursorColor: Colors.blue,
            backgroundCursorColor: Colors.grey,
          ),
        ),
      ),
    );

    await tester.showKeyboard(find.byType(EditableText));
    final MethodCall setClient = log.first;
    expect(setClient.method, 'TextInput.setClient');
    expect(((setClient.arguments as Iterable<dynamic>).last as Map<String, dynamic>)['keyboardAppearance'], 'Brightness.light');
  });

  testWidgets('location of widget is sent on show keyboard', (WidgetTester tester) async {
    final List<MethodCall> log = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.textInput, (MethodCall methodCall) async {
      log.add(methodCall);
      return null;
    });

    final TextEditingController controller = TextEditingController();
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: EditableText(
            controller: controller,
            focusNode: FocusNode(),
            style: Typography.material2018().black.subtitle1!,
            cursorColor: Colors.blue,
            backgroundCursorColor: Colors.grey,
          ),
        ),
      ),
    );

    await tester.showKeyboard(find.byType(EditableText));
    final MethodCall methodCall = log.firstWhere((MethodCall m) => m.method == 'TextInput.setEditableSizeAndTransform');
    expect(
      methodCall,
      isMethodCall('TextInput.setEditableSizeAndTransform', arguments: <String, dynamic>{
        'width': 800,
        'height': 600,
        'transform': Matrix4.identity().storage.toList(),
      }),
    );
  });

  testWidgets('transform and size is reset when text connection opens', (WidgetTester tester) async {
    final List<MethodCall> log = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.textInput, (MethodCall methodCall) async {
      log.add(methodCall);
      return null;
    });

    final TextEditingController controller1 = TextEditingController();
    final TextEditingController controller2 = TextEditingController();
    controller1.text = 'Text1';
    controller2.text = 'Text2';

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children:  <Widget>[
              EditableText(
                key: ValueKey<String>(controller1.text),
                controller: controller1,
                focusNode: FocusNode(),
                style: Typography.material2018().black.subtitle1!,
                cursorColor: Colors.blue,
                backgroundCursorColor: Colors.grey,
              ),
              const SizedBox(height: 200.0),
              EditableText(
                key: ValueKey<String>(controller2.text),
                controller: controller2,
                focusNode: FocusNode(),
                style: Typography.material2018().black.subtitle1!,
                cursorColor: Colors.blue,
                backgroundCursorColor: Colors.grey,
                minLines: 10,
                maxLines: 20,
              ),
              const SizedBox(height: 100.0),
            ],
          ),
        ),
      ),
    );

    await tester.showKeyboard(find.byKey(ValueKey<String>(controller1.text)));
    final MethodCall methodCall = log.firstWhere((MethodCall m) => m.method == 'TextInput.setEditableSizeAndTransform');
    expect(
      methodCall,
      isMethodCall('TextInput.setEditableSizeAndTransform', arguments: <String, dynamic>{
        'width': 800,
        'height': 14,
        'transform': Matrix4.identity().storage.toList(),
      }),
    );

    log.clear();

    // Move to the next editable text.
    await tester.showKeyboard(find.byKey(ValueKey<String>(controller2.text)));
    final MethodCall methodCall2 = log.firstWhere((MethodCall m) => m.method == 'TextInput.setEditableSizeAndTransform');
    expect(
      methodCall2,
      isMethodCall('TextInput.setEditableSizeAndTransform', arguments: <String, dynamic>{
        'width': 800,
        'height': 140.0,
        'transform': <double>[1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 214.0, 0.0, 1.0],
      }),
    );

    log.clear();

    // Move back to the first editable text.
    await tester.showKeyboard(find.byKey(ValueKey<String>(controller1.text)));
    final MethodCall methodCall3 = log.firstWhere((MethodCall m) => m.method == 'TextInput.setEditableSizeAndTransform');
    expect(
      methodCall3,
      isMethodCall('TextInput.setEditableSizeAndTransform', arguments: <String, dynamic>{
        'width': 800,
        'height': 14,
        'transform': Matrix4.identity().storage.toList(),
      }),
    );
  });

  testWidgets('size and transform are sent when they change', (WidgetTester tester) async {
    final List<MethodCall> log = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.textInput, (MethodCall methodCall) async {
      log.add(methodCall);
      return null;
    });

    const Offset offset = Offset(10.0, 20.0);
    const Key transformButtonKey = Key('transformButton');
    await tester.pumpWidget(
      const TransformedEditableText(
        offset: offset,
        transformButtonKey: transformButtonKey,
      ),
    );

    await tester.showKeyboard(find.byType(EditableText));
    MethodCall methodCall = log.firstWhere((MethodCall m) => m.method == 'TextInput.setEditableSizeAndTransform');
    expect(
      methodCall,
      isMethodCall('TextInput.setEditableSizeAndTransform', arguments: <String, dynamic>{
        'width': 800,
        'height': 14,
        'transform': Matrix4.identity().storage.toList(),
      }),
    );

    log.clear();
    await tester.tap(find.byKey(transformButtonKey));
    await tester.pumpAndSettle();

    // There should be a new platform message updating the transform.
    methodCall = log.firstWhere((MethodCall m) => m.method == 'TextInput.setEditableSizeAndTransform');
    expect(
      methodCall,
      isMethodCall('TextInput.setEditableSizeAndTransform', arguments: <String, dynamic>{
        'width': 800,
        'height': 14,
        'transform': Matrix4.translationValues(offset.dx, offset.dy, 0.0).storage.toList(),
      }),
    );
  });

  testWidgets('selection rects are sent when they change', (WidgetTester tester) async {
    final List<MethodCall> log = <MethodCall>[];
    SystemChannels.textInput.setMockMethodCallHandler((MethodCall methodCall) async {
      log.add(methodCall);
    });

    final TextEditingController controller = TextEditingController();
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
                focusNode: FocusNode(),
                style: Typography.material2018().black.subtitle1!,
                cursorColor: Colors.blue,
                backgroundCursorColor: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.showKeyboard(find.byKey(ValueKey<String>(controller.text)));

    // There should be a new platform message updating the selection rects.
    final MethodCall methodCall = log.firstWhere((MethodCall m) => m.method == 'TextInput.setSelectionRects');
    expect(methodCall.method, 'TextInput.setSelectionRects');
    expect((methodCall.arguments as List<dynamic>).length, 5);

    // On web, we should rely on the browser's implementation of Scribble, so we will not send selection rects.
  }, skip: kIsWeb, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.iOS })); // [intended]

  testWidgets('selection rects are not sent if scribbleEnabled is false', (WidgetTester tester) async {
    final List<MethodCall> log = <MethodCall>[];
    SystemChannels.textInput.setMockMethodCallHandler((MethodCall methodCall) async {
      log.add(methodCall);
    });

    final TextEditingController controller = TextEditingController();
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
                focusNode: FocusNode(),
                style: Typography.material2018().black.subtitle1!,
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

  testWidgets('text styling info is sent on show keyboard', (WidgetTester tester) async {
    final List<MethodCall> log = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.textInput, (MethodCall methodCall) async {
      log.add(methodCall);
      return null;
    });

    final TextEditingController controller = TextEditingController();
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(),
        child: EditableText(
          textDirection: TextDirection.rtl,
          controller: controller,
          focusNode: FocusNode(),
          style: const TextStyle(
            fontSize: 20.0,
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w600,
          ),
          cursorColor: Colors.blue,
          backgroundCursorColor: Colors.grey,
        ),
      ),
    );

    await tester.showKeyboard(find.byType(EditableText));
    final MethodCall setStyle = log.firstWhere((MethodCall m) => m.method == 'TextInput.setStyle');
    expect(
      setStyle,
      isMethodCall('TextInput.setStyle', arguments: <String, dynamic>{
        'fontSize': 20.0,
        'fontFamily': 'Roboto',
        'fontWeightIndex': 5,
        'textAlignIndex': 4,
        'textDirectionIndex': 0,
      }),
    );
  });

  testWidgets('text styling info is sent on style update', (WidgetTester tester) async {
    final GlobalKey<EditableTextState> editableTextKey = GlobalKey<EditableTextState>();
    late StateSetter setState;
    const TextStyle textStyle1 = TextStyle(
      fontSize: 20.0,
      fontFamily: 'RobotoMono',
      fontWeight: FontWeight.w600,
    );
    const TextStyle textStyle2 = TextStyle(
      fontSize: 20.0,
      fontFamily: 'Raleway',
      fontWeight: FontWeight.w700,
    );
    TextStyle currentTextStyle = textStyle1;

    Widget builder() {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setter) {
          setState = setter;
          return MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(),
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Center(
                  child: Material(
                    child: EditableText(
                      backgroundCursorColor: Colors.grey,
                      key: editableTextKey,
                      controller: controller,
                      focusNode: FocusNode(),
                      style: currentTextStyle,
                      cursorColor: Colors.blue,
                      selectionControls: materialTextSelectionControls,
                      keyboardType: TextInputType.text,
                      onChanged: (String value) {},
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    await tester.pumpWidget(builder());
    await tester.showKeyboard(find.byType(EditableText));

    final List<MethodCall> log = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.textInput, (MethodCall methodCall) async {
      log.add(methodCall);
      return null;
    });
    setState(() {
      currentTextStyle = textStyle2;
    });
    await tester.pump();

    // Updated styling information should be sent via TextInput.setStyle method.
    final MethodCall setStyle = log.firstWhere((MethodCall m) => m.method == 'TextInput.setStyle');
    expect(
      setStyle,
      isMethodCall('TextInput.setStyle', arguments: <String, dynamic>{
        'fontSize': 20.0,
        'fontFamily': 'Raleway',
        'fontWeightIndex': 6,
        'textAlignIndex': 4,
        'textDirectionIndex': 1,
      }),
    );
  });

  group('setCaretRect', () {
    Widget builder() {
      return MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: Material(
                child: EditableText(
                  backgroundCursorColor: Colors.grey,
                  controller: controller,
                  focusNode: FocusNode(),
                  style: textStyle,
                  cursorColor: Colors.blue,
                  selectionControls: materialTextSelectionControls,
                  keyboardType: TextInputType.text,
                  onChanged: (String value) {},
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets(
      'called with proper coordinates',
      (WidgetTester tester) async {
        controller.value = TextEditingValue(text: 'a' * 50);
        await tester.pumpWidget(builder());
        await tester.showKeyboard(find.byType(EditableText));

        expect(tester.testTextInput.log, contains(
          matchesMethodCall(
            'TextInput.setCaretRect',
            args: allOf(
              // No composing text so the width should not be too wide because
              // it's empty.
              containsPair('x', equals(700)),
              containsPair('y', equals(0)),
              containsPair('width', equals(2)),
              containsPair('height', equals(14)),
            ),
          ),
        ));

        tester.testTextInput.log.clear();

        controller.value = TextEditingValue(
          text: 'a' * 50,
          selection: const TextSelection(baseOffset: 0, extentOffset: 0),
        );
        await tester.pump();

        expect(tester.testTextInput.log, contains(
          matchesMethodCall(
            'TextInput.setCaretRect',
            // Now the composing range is not empty.
            args: allOf(
              containsPair('x', equals(0)),
              containsPair('y', equals(0)),
            ),
          ),
        ));
      },
    );

    testWidgets(
      'only send updates when necessary',
      (WidgetTester tester) async {
        controller.value = TextEditingValue(text: 'a' * 100);
        await tester.pumpWidget(builder());
        await tester.showKeyboard(find.byType(EditableText));

        expect(tester.testTextInput.log, contains(matchesMethodCall('TextInput.setCaretRect')));

        tester.testTextInput.log.clear();

        // Should not send updates every frame.
        await tester.pump();

        expect(tester.testTextInput.log, isNot(contains(matchesMethodCall('TextInput.setCaretRect'))));
      },
    );

    testWidgets(
      'not sent with selection',
      (WidgetTester tester) async {
        controller.value = TextEditingValue(
          text: 'a' * 100,
          selection: const TextSelection(baseOffset: 0, extentOffset: 10),
        );
        await tester.pumpWidget(builder());
        await tester.showKeyboard(find.byType(EditableText));

        expect(tester.testTextInput.log, isNot(contains(matchesMethodCall('TextInput.setCaretRect'))));
      },
    );
  });

  group('setMarkedTextRect', () {
    Widget builder() {
      return MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: Material(
                child: EditableText(
                  backgroundCursorColor: Colors.grey,
                  controller: controller,
                  focusNode: FocusNode(),
                  style: textStyle,
                  cursorColor: Colors.blue,
                  selectionControls: materialTextSelectionControls,
                  keyboardType: TextInputType.text,
                  onChanged: (String value) {},
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets(
      'called when the composing range changes',
      (WidgetTester tester) async {
        controller.value = TextEditingValue(text: 'a' * 100);
        await tester.pumpWidget(builder());
        await tester.showKeyboard(find.byType(EditableText));

        expect(tester.testTextInput.log, contains(
          matchesMethodCall(
            'TextInput.setMarkedTextRect',
            args: allOf(
              // No composing text so the width should not be too wide because
              // it's empty.
              containsPair('width', lessThanOrEqualTo(5)),
              containsPair('x', lessThanOrEqualTo(1)),
            ),
          ),
        ));

        tester.testTextInput.log.clear();

        controller.value = TextEditingValue(text: 'a' * 100, composing: const TextRange(start: 0, end: 10));
        await tester.pump();

        expect(tester.testTextInput.log, contains(
          matchesMethodCall(
            'TextInput.setMarkedTextRect',
            // Now the composing range is not empty.
            args: containsPair('width', greaterThanOrEqualTo(10)),
          ),
        ));
      },
    );

    testWidgets(
      'only send updates when necessary',
      (WidgetTester tester) async {
        controller.value = TextEditingValue(text: 'a' * 100, composing: const TextRange(start: 0, end: 10));
        await tester.pumpWidget(builder());
        await tester.showKeyboard(find.byType(EditableText));

        expect(tester.testTextInput.log, contains(matchesMethodCall('TextInput.setMarkedTextRect')));

        tester.testTextInput.log.clear();

        // Should not send updates every frame.
        await tester.pump();

        expect(tester.testTextInput.log, isNot(contains(matchesMethodCall('TextInput.setMarkedTextRect'))));
      },
    );

    testWidgets(
      'zero matrix paint transform',
      (WidgetTester tester) async {
        controller.value = TextEditingValue(text: 'a' * 100, composing: const TextRange(start: 0, end: 10));
        // Use a FittedBox with an zero-sized child to set the paint transform
        // to the zero matrix.
        await tester.pumpWidget(FittedBox(child: SizedBox.fromSize(size: Size.zero, child: builder())));
        await tester.showKeyboard(find.byType(EditableText));
        expect(tester.testTextInput.log, contains(matchesMethodCall(
          'TextInput.setMarkedTextRect',
          args: allOf(
            containsPair('width', isNotNaN),
            containsPair('height', isNotNaN),
            containsPair('x', isNotNaN),
            containsPair('y', isNotNaN),
          ),
        )));
      },
    );
  });


  testWidgets('custom keyboardAppearance is respected', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/22212.

    final List<MethodCall> log = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.textInput, (MethodCall methodCall) async {
      log.add(methodCall);
      return null;
    });

    final TextEditingController controller = TextEditingController();
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: EditableText(
            controller: controller,
            focusNode: FocusNode(),
            style: Typography.material2018().black.subtitle1!,
            cursorColor: Colors.blue,
            backgroundCursorColor: Colors.grey,
            keyboardAppearance: Brightness.dark,
          ),
        ),
      ),
    );

    await tester.showKeyboard(find.byType(EditableText));
    final MethodCall setClient = log.first;
    expect(setClient.method, 'TextInput.setClient');
    expect(((setClient.arguments as Iterable<dynamic>).last as Map<String, dynamic>)['keyboardAppearance'], 'Brightness.dark');
  });

  testWidgets('Composing text is underlined and underline is cleared when losing focus', (WidgetTester tester) async {
    final TextEditingController controller = TextEditingController.fromValue(
      const TextEditingValue(
        text: 'text composing text',
        selection: TextSelection.collapsed(offset: 14),
        composing: TextRange(start: 5, end: 14),
      ),
    );
    final FocusNode focusNode = FocusNode(debugLabel: 'Test Focus Node');

    await tester.pumpWidget(MaterialApp( // So we can show overlays.
      home: EditableText(
        autofocus: true,
        backgroundCursorColor: Colors.grey,
        controller: controller,
        focusNode: focusNode,
        style: textStyle,
        cursorColor: cursorColor,
        selectionControls: materialTextSelectionControls,
        keyboardType: TextInputType.text,
        onEditingComplete: () {
          // This prevents the default focus change behavior on submission.
        },
      ),
    ));

    assert(focusNode.hasFocus);
    // Autofocus has a one frame delay.
    await tester.pump();

    final RenderEditable renderEditable = findRenderEditable(tester);
    // The actual text span is split into 3 parts with the middle part underlined.
    expect((renderEditable.text! as TextSpan).children!.length, 3);
    final TextSpan textSpan = (renderEditable.text! as TextSpan).children![1] as TextSpan;
    expect(textSpan.text, 'composing');
    expect(textSpan.style!.decoration, TextDecoration.underline);

    focusNode.unfocus();
    // Drain microtasks.
    await tester.idle();
    await tester.pump();

    expect((renderEditable.text! as TextSpan).children, isNull);
    // Everything's just formated the same way now.
    expect((renderEditable.text! as TextSpan).text, 'text composing text');
    expect(renderEditable.text!.style!.decoration, isNull);
  });

  testWidgets('text selection toolbar visibility', (WidgetTester tester) async {
    const String testText = 'hello \n world \n this \n is \n text';
    final TextEditingController controller = TextEditingController(text: testText);

    await tester.pumpWidget(MaterialApp(
      home: Align(
        alignment: Alignment.topLeft,
        child: Container(
          height: 50,
          color: Colors.white,
          child: EditableText(
            showSelectionHandles: true,
            controller: controller,
            focusNode: FocusNode(),
            style: Typography.material2018().black.subtitle1!,
            cursorColor: Colors.blue,
            backgroundCursorColor: Colors.grey,
            selectionControls: materialTextSelectionControls,
            keyboardType: TextInputType.text,
            selectionColor: Colors.lightBlueAccent,
            maxLines: 3,
          ),
        ),
      ),
    ));

    final EditableTextState state =
      tester.state<EditableTextState>(find.byType(EditableText));
    final RenderEditable renderEditable = state.renderEditable;
    final Scrollable scrollable = tester.widget<Scrollable>(find.byType(Scrollable));

    // Select the first word. And show the toolbar.
    await tester.tapAt(const Offset(20, 10));
    renderEditable.selectWord(cause: SelectionChangedCause.longPress);
    expect(state.showToolbar(), true);
    await tester.pumpAndSettle();

    // Find the toolbar fade transition while the toolbar is still visible.
    final List<FadeTransition> transitionsBefore = find.descendant(
      of: find.byWidgetPredicate((Widget w) => '${w.runtimeType}' == '_SelectionToolbarOverlay'),
      matching: find.byType(FadeTransition),
    ).evaluate().map((Element e) => e.widget).cast<FadeTransition>().toList();

    expect(transitionsBefore.length, 1);

    final FadeTransition toolbarBefore = transitionsBefore[0];

    expect(toolbarBefore.opacity.value, 1.0);

    // Scroll until the selection is no longer within view.
    scrollable.controller!.jumpTo(50.0);
    await tester.pumpAndSettle();

    // Find the toolbar fade transition after the toolbar has been hidden.
    final List<FadeTransition> transitionsAfter = find.descendant(
      of: find.byWidgetPredicate((Widget w) => '${w.runtimeType}' == '_SelectionToolbarOverlay'),
      matching: find.byType(FadeTransition),
    ).evaluate().map((Element e) => e.widget).cast<FadeTransition>().toList();

    expect(transitionsAfter.length, 1);

    final FadeTransition toolbarAfter = transitionsAfter[0];

    expect(toolbarAfter.opacity.value, 0.0);

    // On web, we don't show the Flutter toolbar and instead rely on the browser
    // toolbar. Until we change that, this test should remain skipped.
  }, skip: kIsWeb); // [intended]

  testWidgets('text selection handle visibility', (WidgetTester tester) async {
    // Text with two separate words to select.
    const String testText = 'XXXXX          XXXXX';
    final TextEditingController controller = TextEditingController(text: testText);

    await tester.pumpWidget(MaterialApp(
      home: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 100,
          child: EditableText(
            showSelectionHandles: true,
            controller: controller,
            focusNode: FocusNode(),
            style: Typography.material2018().black.subtitle1!,
            cursorColor: Colors.blue,
            backgroundCursorColor: Colors.grey,
            selectionControls: materialTextSelectionControls,
            keyboardType: TextInputType.text,
          ),
        ),
      ),
    ));

    final EditableTextState state =
      tester.state<EditableTextState>(find.byType(EditableText));
    final RenderEditable renderEditable = state.renderEditable;
    final Scrollable scrollable = tester.widget<Scrollable>(find.byType(Scrollable));

    bool expectedLeftVisibleBefore = false;
    bool expectedRightVisibleBefore = false;

    Future<void> verifyVisibility(
      HandlePositionInViewport leftPosition,
      bool expectedLeftVisible,
      HandlePositionInViewport rightPosition,
      bool expectedRightVisible,
    ) async {
      await tester.pump();

      // Check the signal from RenderEditable about whether they're within the
      // viewport.

      expect(renderEditable.selectionStartInViewport.value, equals(expectedLeftVisible));
      expect(renderEditable.selectionEndInViewport.value, equals(expectedRightVisible));

      // Check that the animations are functional and going in the right
      // direction.

      final List<FadeTransition> transitions = find.descendant(
        of: find.byWidgetPredicate((Widget w) => '${w.runtimeType}' == '_SelectionHandleOverlay'),
        matching: find.byType(FadeTransition),
      ).evaluate().map((Element e) => e.widget).cast<FadeTransition>().toList();
      expect(transitions.length, 2);
      final FadeTransition left = transitions[0];
      final FadeTransition right = transitions[1];

      if (expectedLeftVisibleBefore) {
        expect(left.opacity.value, equals(1.0));
      }
      if (expectedRightVisibleBefore) {
        expect(right.opacity.value, equals(1.0));
      }

      await tester.pump(SelectionOverlay.fadeDuration ~/ 2);

      if (expectedLeftVisible != expectedLeftVisibleBefore) {
        expect(left.opacity.value, equals(0.5));
      }
      if (expectedRightVisible != expectedRightVisibleBefore) {
        expect(right.opacity.value, equals(0.5));
      }

      await tester.pump(SelectionOverlay.fadeDuration ~/ 2);

      if (expectedLeftVisible) {
        expect(left.opacity.value, equals(1.0));
      }
      if (expectedRightVisible) {
        expect(right.opacity.value, equals(1.0));
      }

      expectedLeftVisibleBefore = expectedLeftVisible;
      expectedRightVisibleBefore = expectedRightVisible;

      // Check that the handles' positions are correct.

      final List<RenderBox> handles = List<RenderBox>.from(
        tester.renderObjectList<RenderBox>(
          find.descendant(
            of: find.byType(CompositedTransformFollower),
            matching: find.byType(Padding),
          ),
        ),
      );

      final Size viewport = renderEditable.size;

      void testPosition(double pos, HandlePositionInViewport expected) {
        switch (expected) {
          case HandlePositionInViewport.leftEdge:
            expect(
              pos,
              inExclusiveRange(
                0 - kMinInteractiveDimension,
                0 + kMinInteractiveDimension,
              ),
            );
            break;
          case HandlePositionInViewport.rightEdge:
            expect(
              pos,
              inExclusiveRange(
                viewport.width - kMinInteractiveDimension,
                viewport.width + kMinInteractiveDimension,
              ),
            );
            break;
          case HandlePositionInViewport.within:
            expect(
              pos,
              inExclusiveRange(
                0 - kMinInteractiveDimension,
                viewport.width + kMinInteractiveDimension,
              ),
            );
            break;
        }
      }
      expect(state.selectionOverlay!.handlesAreVisible, isTrue);
      testPosition(handles[0].localToGlobal(Offset.zero).dx, leftPosition);
      testPosition(handles[1].localToGlobal(Offset.zero).dx, rightPosition);
    }

    // Select the first word. Both handles should be visible.
    await tester.tapAt(const Offset(20, 10));
    renderEditable.selectWord(cause: SelectionChangedCause.longPress);
    await tester.pump();
    await verifyVisibility(HandlePositionInViewport.leftEdge, true, HandlePositionInViewport.within, true);

    // Drag the text slightly so the first word is partially visible. Only the
    // right handle should be visible.
    scrollable.controller!.jumpTo(20.0);
    await verifyVisibility(HandlePositionInViewport.leftEdge, false, HandlePositionInViewport.within, true);

    // Drag the text all the way to the left so the first word is not visible at
    // all (and the second word is fully visible). Both handles should be
    // invisible now.
    scrollable.controller!.jumpTo(200.0);
    await verifyVisibility(HandlePositionInViewport.leftEdge, false, HandlePositionInViewport.leftEdge, false);

    // Tap to unselect.
    await tester.tap(find.byType(EditableText));
    await tester.pump();

    // Now that the second word has been dragged fully into view, select it.
    await tester.tapAt(const Offset(80, 10));
    renderEditable.selectWord(cause: SelectionChangedCause.longPress);
    await tester.pump();
    await verifyVisibility(HandlePositionInViewport.within, true, HandlePositionInViewport.within, true);

    // Drag the text slightly to the right. Only the left handle should be
    // visible.
    scrollable.controller!.jumpTo(150);
    await verifyVisibility(HandlePositionInViewport.within, true, HandlePositionInViewport.rightEdge, false);

    // Drag the text all the way to the right, so the second word is not visible
    // at all. Again, both handles should be invisible.
    scrollable.controller!.jumpTo(0);
    await verifyVisibility(HandlePositionInViewport.rightEdge, false, HandlePositionInViewport.rightEdge, false);

    // On web, we don't show the Flutter toolbar and instead rely on the browser
    // toolbar. Until we change that, this test should remain skipped.
  }, skip: kIsWeb); // [intended]

  testWidgets('text selection handle visibility RTL', (WidgetTester tester) async {
    // Text with two separate words to select.
    const String testText = 'XXXXX          XXXXX';
    final TextEditingController controller = TextEditingController(text: testText);

    await tester.pumpWidget(MaterialApp(
      home: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 100,
          child: EditableText(
            controller: controller,
            showSelectionHandles: true,
            focusNode: FocusNode(),
            style: Typography.material2018().black.subtitle1!,
            cursorColor: Colors.blue,
            backgroundCursorColor: Colors.grey,
            selectionControls: materialTextSelectionControls,
            keyboardType: TextInputType.text,
            textAlign: TextAlign.right,
          ),
        ),
      ),
    ));

    final EditableTextState state =
        tester.state<EditableTextState>(find.byType(EditableText));

    // Select the first word. Both handles should be visible.
    await tester.tapAt(const Offset(20, 10));
    state.renderEditable.selectWord(cause: SelectionChangedCause.longPress);
    await tester.pump();
    final List<RenderBox> handles = List<RenderBox>.from(
      tester.renderObjectList<RenderBox>(
        find.descendant(
          of: find.byType(CompositedTransformFollower),
          matching: find.byType(Padding),
        ),
      ),
    );
    expect(
      handles[0].localToGlobal(Offset.zero).dx,
      inExclusiveRange(
        -kMinInteractiveDimension,
        kMinInteractiveDimension,
      ),
    );
    expect(
      handles[1].localToGlobal(Offset.zero).dx,
      inExclusiveRange(
        70.0 - kMinInteractiveDimension,
        70.0 + kMinInteractiveDimension,
      ),
    );
    expect(state.selectionOverlay!.handlesAreVisible, isTrue);
    expect(controller.selection.base.offset, 0);
    expect(controller.selection.extent.offset, 5);

    // On web, we don't show the Flutter toolbar and instead rely on the browser
    // toolbar. Until we change that, this test should remain skipped.
  }, skip: kIsWeb); // [intended]

  const String testText = 'Now is the time for\n' // 20
      'all good people\n'                         // 20 + 16 => 36
      'to come to the aid\n'                      // 36 + 19 => 55
      'of their country.';                        // 55 + 17 => 72

  Future<void> sendKeys(
      WidgetTester tester,
      List<LogicalKeyboardKey> keys, {
        bool shift = false,
        bool wordModifier = false,
        bool lineModifier = false,
        bool shortcutModifier = false,
        required TargetPlatform targetPlatform,
      }) async {
    final String targetPlatformString = targetPlatform.toString();
    final String platform = targetPlatformString.substring(targetPlatformString.indexOf('.') + 1).toLowerCase();
    if (shift) {
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft, platform: platform);
    }
    if (shortcutModifier) {
      await tester.sendKeyDownEvent(
        platform == 'macos' || platform == 'ios' ? LogicalKeyboardKey.metaLeft : LogicalKeyboardKey.controlLeft,
        platform: platform,
      );
    }
    if (wordModifier) {
      await tester.sendKeyDownEvent(
        platform == 'macos' || platform == 'ios' ? LogicalKeyboardKey.altLeft : LogicalKeyboardKey.controlLeft,
        platform: platform,
      );
    }
    if (lineModifier) {
      await tester.sendKeyDownEvent(
        platform == 'macos' || platform == 'ios' ? LogicalKeyboardKey.metaLeft : LogicalKeyboardKey.altLeft,
        platform: platform,
      );
    }
    for (final LogicalKeyboardKey key in keys) {
      await tester.sendKeyEvent(key, platform: platform);
      await tester.pump();
    }
    if (lineModifier) {
      await tester.sendKeyUpEvent(
        platform == 'macos' || platform == 'ios' ? LogicalKeyboardKey.metaLeft : LogicalKeyboardKey.altLeft,
        platform: platform,
      );
    }
    if (wordModifier) {
      await tester.sendKeyUpEvent(
        platform == 'macos' || platform == 'ios' ? LogicalKeyboardKey.altLeft : LogicalKeyboardKey.controlLeft,
        platform: platform,
      );
    }
    if (shortcutModifier) {
      await tester.sendKeyUpEvent(
        platform == 'macos' || platform == 'ios' ? LogicalKeyboardKey.metaLeft : LogicalKeyboardKey.controlLeft,
        platform: platform,
      );
    }
    if (shift) {
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft, platform: platform);
    }
    if (shift || wordModifier || lineModifier) {
      await tester.pump();
    }
  }

  Future<void> testTextEditing(WidgetTester tester, {required TargetPlatform targetPlatform}) async {
    final String targetPlatformString = targetPlatform.toString();
    final String platform = targetPlatformString.substring(targetPlatformString.indexOf('.') + 1).toLowerCase();
    final TextEditingController controller = TextEditingController(text: testText);
    controller.selection = const TextSelection(
      baseOffset: 0,
      extentOffset: 0,
      affinity: TextAffinity.upstream,
    );
    late TextSelection selection;
    late SelectionChangedCause cause;
    await tester.pumpWidget(MaterialApp(
      home: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 400,
          child: EditableText(
            maxLines: 10,
            controller: controller,
            showSelectionHandles: true,
            autofocus: true,
            focusNode: FocusNode(),
            style: Typography.material2018().black.subtitle1!,
            cursorColor: Colors.blue,
            backgroundCursorColor: Colors.grey,
            selectionControls: materialTextSelectionControls,
            keyboardType: TextInputType.text,
            textAlign: TextAlign.right,
            onSelectionChanged: (TextSelection newSelection, SelectionChangedCause? newCause) {
              selection = newSelection;
              cause = newCause!;
            },
          ),
        ),
      ),
    ));

    await tester.pump(); // Wait for autofocus to take effect.

    // Select a few characters using shift right arrow
    await sendKeys(
      tester,
      <LogicalKeyboardKey>[
        LogicalKeyboardKey.arrowRight,
        LogicalKeyboardKey.arrowRight,
        LogicalKeyboardKey.arrowRight,
      ],
      shift: true,
      targetPlatform: defaultTargetPlatform,
    );

    expect(cause, equals(SelectionChangedCause.keyboard), reason: 'on $platform');
    expect(
      selection,
      equals(
        const TextSelection(
          baseOffset: 0,
          extentOffset: 3,
          affinity: TextAffinity.upstream,
        ),
      ),
      reason: 'on $platform',
    );

    // Select fewer characters using shift left arrow
    await sendKeys(
      tester,
      <LogicalKeyboardKey>[
        LogicalKeyboardKey.arrowLeft,
        LogicalKeyboardKey.arrowLeft,
        LogicalKeyboardKey.arrowLeft,
      ],
      shift: true,
      targetPlatform: defaultTargetPlatform,
    );

    expect(
      selection,
      equals(
        const TextSelection(
          baseOffset: 0,
          extentOffset: 0,
        ),
      ),
      reason: 'on $platform',
    );

    // Try to select before the first character, nothing should change.
    await sendKeys(
      tester,
      <LogicalKeyboardKey>[
        LogicalKeyboardKey.arrowLeft,
      ],
      shift: true,
      targetPlatform: defaultTargetPlatform,
    );

    expect(
      selection,
      equals(
        const TextSelection(
          baseOffset: 0,
          extentOffset: 0,
        ),
      ),
      reason: 'on $platform',
    );

    // Select the first two words.
    await sendKeys(
      tester,
      <LogicalKeyboardKey>[
        LogicalKeyboardKey.arrowRight,
        LogicalKeyboardKey.arrowRight,
      ],
      shift: true,
      wordModifier: true,
      targetPlatform: defaultTargetPlatform,
    );

    expect(
      selection,
      equals(
        const TextSelection(
          baseOffset: 0,
          extentOffset: 6,
          affinity: TextAffinity.upstream,
        ),
      ),
      reason: 'on $platform',
    );

    // Unselect the second word.
    await sendKeys(
      tester,
      <LogicalKeyboardKey>[
        LogicalKeyboardKey.arrowLeft,
      ],
      shift: true,
      wordModifier: true,
      targetPlatform: defaultTargetPlatform,
    );

    expect(
      selection,
      equals(
        const TextSelection(
          baseOffset: 0,
          extentOffset: 4,
          affinity: TextAffinity.upstream,
        ),
      ),
      reason: 'on $platform',
    );

    // Select the next line.
    await sendKeys(
      tester,
      <LogicalKeyboardKey>[
        LogicalKeyboardKey.arrowDown,
      ],
      shift: true,
      targetPlatform: defaultTargetPlatform,
    );

    expect(
      selection,
      equals(
        const TextSelection(
          baseOffset: 0,
          extentOffset: 20,
          affinity: TextAffinity.upstream,
        ),
      ),
      reason: 'on $platform',
    );

    await sendKeys(
      tester,
      <LogicalKeyboardKey>[
        LogicalKeyboardKey.arrowRight,
      ],
      targetPlatform: defaultTargetPlatform,
    );

    expect(
      selection,
      equals(
        const TextSelection(
          baseOffset: 20,
          extentOffset: 20,
        ),
      ),
      reason: 'on $platform',
    );

    // Select the next line.
    await sendKeys(
      tester,
      <LogicalKeyboardKey>[
        LogicalKeyboardKey.arrowDown,
      ],
      shift: true,
      targetPlatform: defaultTargetPlatform,
    );

    expect(
      selection,
      equals(
        const TextSelection(
          baseOffset: 20,
          extentOffset: 39,
        ),
      ),
      reason: 'on $platform',
    );

    // Select to the end of the string by going down.
    await sendKeys(
      tester,
      <LogicalKeyboardKey>[
        LogicalKeyboardKey.arrowDown,
        LogicalKeyboardKey.arrowDown,
        LogicalKeyboardKey.arrowDown,
        LogicalKeyboardKey.arrowDown,
      ],
      shift: true,
      targetPlatform: defaultTargetPlatform,
    );

    expect(
      selection,
      equals(
        const TextSelection(
          baseOffset: 20,
          extentOffset: testText.length,
        ),
      ),
      reason: 'on $platform',
    );

    // Go back up one line to set selection up to part of the last line.
    await sendKeys(
      tester,
      <LogicalKeyboardKey>[
        LogicalKeyboardKey.arrowUp,
      ],
      shift: true,
      targetPlatform: defaultTargetPlatform,
    );

    expect(
      selection,
      equals(
        const TextSelection(
          baseOffset: 20,
          extentOffset: 39,
        ),
      ),
      reason: 'on $platform',
    );

    // Select to the end of the selection.
    await sendKeys(
      tester,
      <LogicalKeyboardKey>[
        LogicalKeyboardKey.arrowRight,
      ],
      lineModifier: true,
      shift: true,
      targetPlatform: defaultTargetPlatform,
    );

    expect(
      selection,
      equals(
        const TextSelection(
          baseOffset: 20,
          extentOffset: 54,
          affinity: TextAffinity.upstream,
        ),
      ),
      reason: 'on $platform',
    );

    await sendKeys(
      tester,
      <LogicalKeyboardKey>[
        LogicalKeyboardKey.arrowLeft,
      ],
      lineModifier: true,
      shift: true,
      targetPlatform: defaultTargetPlatform,
    );

    switch (defaultTargetPlatform) {
      // These platforms extend by line.
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        expect(
          selection,
          equals(
            const TextSelection(
              baseOffset: 20,
              extentOffset: 36,
              affinity: TextAffinity.upstream,
            ),
          ),
          reason: 'on $platform',
        );
        break;

      // Mac and iOS expand by line.
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        expect(
          selection,
          equals(
            const TextSelection(
              baseOffset: 20,
              extentOffset: 54,
              affinity: TextAffinity.upstream,
            ),
          ),
          reason: 'on $platform',
        );
        break;
    }

    // Select All
    await sendKeys(
      tester,
      <LogicalKeyboardKey>[
        LogicalKeyboardKey.keyA,
      ],
      shortcutModifier: true,
      targetPlatform: defaultTargetPlatform,
    );

    expect(
      selection,
      equals(
        const TextSelection(
          baseOffset: 0,
          extentOffset: testText.length,
          affinity: TextAffinity.upstream,
        ),
      ),
      reason: 'on $platform',
    );

    // Jump to beginning of selection.
    await sendKeys(
      tester,
      <LogicalKeyboardKey>[
        LogicalKeyboardKey.arrowLeft,
      ],
      targetPlatform: defaultTargetPlatform,
    );

    expect(
      selection,
      equals(
        const TextSelection(
          baseOffset: 0,
          extentOffset: 0,
        ),
      ),
      reason: 'on $platform',
    );

    // Jump to end.
    await sendKeys(
      tester,
      <LogicalKeyboardKey>[
        LogicalKeyboardKey.arrowDown,
      ],
      lineModifier: true,
      targetPlatform: defaultTargetPlatform,
    );

    expect(
      selection,
      equals(
        const TextSelection.collapsed(
          offset: testText.length,
          affinity: TextAffinity.upstream,
        ),
      ),
      reason: 'on $platform',
    );
    expect(controller.text, equals(testText), reason: 'on $platform');

    // Jump to start.
    await sendKeys(
      tester,
      <LogicalKeyboardKey>[
        LogicalKeyboardKey.arrowUp,
      ],
      lineModifier: true,
      targetPlatform: defaultTargetPlatform,
    );

    expect(
      selection,
      equals(
        const TextSelection.collapsed(
          offset: 0,
        ),
      ),
      reason: 'on $platform',
    );
    expect(controller.text, equals(testText), reason: 'on $platform');

    // Move forward a few letters
    await sendKeys(
      tester,
      <LogicalKeyboardKey>[
        LogicalKeyboardKey.arrowRight,
        LogicalKeyboardKey.arrowRight,
        LogicalKeyboardKey.arrowRight,
      ],
      targetPlatform: defaultTargetPlatform,
    );

    expect(
      selection,
      equals(
        const TextSelection.collapsed(
          offset: 3,
        ),
      ),
      reason: 'on $platform',
    );

    // Select to end.
    await sendKeys(
      tester,
      <LogicalKeyboardKey>[
        LogicalKeyboardKey.arrowDown,
      ],
      shift: true,
      lineModifier: true,
      targetPlatform: defaultTargetPlatform,
    );

    expect(
      selection,
      equals(
        const TextSelection(
          baseOffset: 3,
          extentOffset: testText.length,
        ),
      ),
      reason: 'on $platform',
    );

    // Select to start, which extends the selection.
    await sendKeys(
      tester,
      <LogicalKeyboardKey>[
        LogicalKeyboardKey.arrowUp,
      ],
      shift: true,
      lineModifier: true,
      targetPlatform: defaultTargetPlatform,
    );

    expect(
      selection,
      equals(
        const TextSelection(
          baseOffset: 3,
          extentOffset: 0,
          affinity: TextAffinity.upstream,
        ),
      ),
      reason: 'on $platform',
    );

    // Move to start again.
    await sendKeys(
      tester,
      <LogicalKeyboardKey>[
        LogicalKeyboardKey.arrowUp,
      ],
      targetPlatform: defaultTargetPlatform,
    );

    expect(
      selection,
      equals(
        const TextSelection.collapsed(
          offset: 0,
        ),
      ),
      reason: 'on $platform',
    );

    // Jump forward three words.
    await sendKeys(
      tester,
      <LogicalKeyboardKey>[
        LogicalKeyboardKey.arrowRight,
        LogicalKeyboardKey.arrowRight,
        LogicalKeyboardKey.arrowRight,
      ],
      wordModifier: true,
      targetPlatform: defaultTargetPlatform,
    );

    expect(
      selection,
      equals(
        const TextSelection(
          baseOffset: 10,
          extentOffset: 10,
        ),
      ),
      reason: 'on $platform',
    );

    // Select some characters backward.
    await sendKeys(
      tester,
      <LogicalKeyboardKey>[
        LogicalKeyboardKey.arrowLeft,
        LogicalKeyboardKey.arrowLeft,
        LogicalKeyboardKey.arrowLeft,
      ],
      shift: true,
      targetPlatform: defaultTargetPlatform,
    );

    expect(
      selection,
      equals(
        const TextSelection(
          baseOffset: 10,
          extentOffset: 7,
          affinity: TextAffinity.upstream,
        ),
      ),
      reason: 'on $platform',
    );

    // Select a word backward.
    await sendKeys(
      tester,
      <LogicalKeyboardKey>[
        LogicalKeyboardKey.arrowLeft,
      ],
      shift: true,
      wordModifier: true,
      targetPlatform: defaultTargetPlatform,
    );

    expect(
      selection,
      equals(
        const TextSelection(
          baseOffset: 10,
          extentOffset: 4,
          affinity: TextAffinity.upstream,
        ),
      ),
      reason: 'on $platform',
    );
    expect(controller.text, equals(testText), reason: 'on $platform');

    // Cut
    await sendKeys(
      tester,
      <LogicalKeyboardKey>[
        LogicalKeyboardKey.keyX,
      ],
      shortcutModifier: true,
      targetPlatform: defaultTargetPlatform,
    );

    expect(
      selection,
      equals(
        const TextSelection(
          baseOffset: 4,
          extentOffset: 4,
        ),
      ),
      reason: 'on $platform',
    );
    expect(
      controller.text,
      equals(
        'Now  time for\n'
        'all good people\n'
        'to come to the aid\n'
        'of their country.',
      ),
      reason: 'on $platform',
    );
    expect(
      (await Clipboard.getData(Clipboard.kTextPlain))!.text,
      equals('is the'),
      reason: 'on $platform',
    );

    // Paste
    await sendKeys(
      tester,
      <LogicalKeyboardKey>[
        LogicalKeyboardKey.keyV,
      ],
      shortcutModifier: true,
      targetPlatform: defaultTargetPlatform,
    );

    expect(
      selection,
      equals(
        const TextSelection(
          baseOffset: 10,
          extentOffset: 10,
        ),
      ),
      reason: 'on $platform',
    );
    expect(controller.text, equals(testText), reason: 'on $platform');

    // Copy All
    await sendKeys(
      tester,
      <LogicalKeyboardKey>[
        LogicalKeyboardKey.keyA,
        LogicalKeyboardKey.keyC,
      ],
      shortcutModifier: true,
      targetPlatform: defaultTargetPlatform,
    );

    expect(
      selection,
      equals(
        const TextSelection(
          baseOffset: 0,
          extentOffset: testText.length,
          affinity: TextAffinity.upstream,
        ),
      ),
      reason: 'on $platform',
    );
    expect(controller.text, equals(testText), reason: 'on $platform');
    expect((await Clipboard.getData(Clipboard.kTextPlain))!.text, equals(testText));

    // Delete
    await sendKeys(
      tester,
      <LogicalKeyboardKey>[
        LogicalKeyboardKey.delete,
      ],
      targetPlatform: defaultTargetPlatform,
    );
    expect(
      selection,
      equals(
        const TextSelection(
          baseOffset: 0,
          extentOffset: 0,
        ),
      ),
      reason: 'on $platform',
    );
    expect(controller.text, isEmpty, reason: 'on $platform');

    controller.text = 'abc';
    controller.selection = const TextSelection(baseOffset: 2, extentOffset: 2);

    // Backspace
    await sendKeys(
      tester,
      <LogicalKeyboardKey>[
        LogicalKeyboardKey.backspace,
      ],
      targetPlatform: defaultTargetPlatform,
    );
    expect(
      selection,
      equals(
        const TextSelection(
          baseOffset: 1,
          extentOffset: 1,
        ),
      ),
      reason: 'on $platform',
    );
    expect(controller.text, 'ac', reason: 'on $platform');

    // Shift-backspace (same as backspace)
    await sendKeys(
      tester,
      <LogicalKeyboardKey>[
        LogicalKeyboardKey.backspace,
      ],
      shift: true,
      targetPlatform: defaultTargetPlatform,
    );
    expect(
      selection,
      equals(
        const TextSelection(
          baseOffset: 0,
          extentOffset: 0,
        ),
      ),
      reason: 'on $platform',
    );
    expect(controller.text, 'c', reason: 'on $platform');
  }

  testWidgets('keyboard text selection works (RawKeyEvent)', (WidgetTester tester) async {
    debugKeyEventSimulatorTransitModeOverride = KeyDataTransitMode.rawKeyData;

    await testTextEditing(tester, targetPlatform: defaultTargetPlatform);

    debugKeyEventSimulatorTransitModeOverride = null;

    // On web, using keyboard for selection is handled by the browser.
  }, variant: TargetPlatformVariant.all(), skip: kIsWeb); // [intended]

  testWidgets('keyboard text selection works (ui.KeyData then RawKeyEvent)', (WidgetTester tester) async {
    debugKeyEventSimulatorTransitModeOverride = KeyDataTransitMode.keyDataThenRawKeyData;

    await testTextEditing(tester, targetPlatform: defaultTargetPlatform);

    debugKeyEventSimulatorTransitModeOverride = null;

    // On web, using keyboard for selection is handled by the browser.
  }, variant: TargetPlatformVariant.all(), skip: kIsWeb); // [intended]

  testWidgets(
    'keyboard shortcuts respect read-only',
    (WidgetTester tester) async {
      final String platform = defaultTargetPlatform.name.toLowerCase();
      final TextEditingController controller = TextEditingController(text: testText);
      controller.selection = const TextSelection(
        baseOffset: 0,
        extentOffset: testText.length ~/2,
        affinity: TextAffinity.upstream,
      );
      TextSelection? selection;
      await tester.pumpWidget(MaterialApp(
        home: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 400,
            child: EditableText(
              readOnly: true,
              controller: controller,
              autofocus: true,
              focusNode: FocusNode(),
              style: Typography.material2018().black.subtitle1!,
              cursorColor: Colors.blue,
              backgroundCursorColor: Colors.grey,
              selectionControls: materialTextSelectionControls,
              keyboardType: TextInputType.text,
              textAlign: TextAlign.right,
              onSelectionChanged: (TextSelection newSelection, SelectionChangedCause? newCause) {
                selection = newSelection;
              },
            ),
          ),
        ),
      ));

      await tester.pump(); // Wait for autofocus to take effect.

      const String clipboardContent = 'read-only';
      await Clipboard.setData(const ClipboardData(text: clipboardContent));

      // Paste
      await sendKeys(
        tester,
        <LogicalKeyboardKey>[
          LogicalKeyboardKey.keyV,
        ],
        shortcutModifier: true,
        targetPlatform: defaultTargetPlatform,
      );

      expect(selection, isNull, reason: 'on $platform');
      expect(controller.text, equals(testText), reason: 'on $platform');

      // Select All
      await sendKeys(
        tester,
        <LogicalKeyboardKey>[
          LogicalKeyboardKey.keyA,
        ],
        shortcutModifier: true,
        targetPlatform: defaultTargetPlatform,
      );

      expect(
        selection,
        equals(
          const TextSelection(
            baseOffset: 0,
            extentOffset: testText.length,
            affinity: TextAffinity.upstream,
          ),
        ),
        reason: 'on $platform',
      );
      expect(controller.text, equals(testText), reason: 'on $platform');

      // Cut
      await sendKeys(
        tester,
        <LogicalKeyboardKey>[
          LogicalKeyboardKey.keyX,
        ],
        shortcutModifier: true,
        targetPlatform: defaultTargetPlatform,
      );

      expect(
        selection,
        equals(
          const TextSelection(
            baseOffset: 0,
            extentOffset: testText.length,
            affinity: TextAffinity.upstream,
          ),
        ),
        reason: 'on $platform',
      );
      expect(controller.text, equals(testText), reason: 'on $platform');
      expect(
        (await Clipboard.getData(Clipboard.kTextPlain))!.text,
        equals(clipboardContent),
        reason: 'on $platform',
      );

      // Copy
      await sendKeys(
        tester,
        <LogicalKeyboardKey>[
          LogicalKeyboardKey.keyC,
        ],
        shortcutModifier: true,
        targetPlatform: defaultTargetPlatform,
      );

      expect(
        selection,
        equals(
          const TextSelection(
            baseOffset: 0,
            extentOffset: testText.length,
            affinity: TextAffinity.upstream,
          ),
        ),
        reason: 'on $platform',
      );
      expect(controller.text, equals(testText), reason: 'on $platform');
      expect(
        (await Clipboard.getData(Clipboard.kTextPlain))!.text,
        equals(testText),
        reason: 'on $platform',
      );

      // Delete
      await sendKeys(
        tester,
        <LogicalKeyboardKey>[
          LogicalKeyboardKey.delete,
        ],
        targetPlatform: defaultTargetPlatform,
      );
      expect(
        selection,
        equals(
          const TextSelection(
            baseOffset: 0,
            extentOffset: testText.length,
            affinity: TextAffinity.upstream,
          ),
        ),
        reason: 'on $platform',
      );
      expect(controller.text, equals(testText), reason: 'on $platform');

      // Backspace
      await sendKeys(
        tester,
        <LogicalKeyboardKey>[
          LogicalKeyboardKey.backspace,
        ],
        targetPlatform: defaultTargetPlatform,
      );
      expect(
        selection,
        equals(
          const TextSelection(
            baseOffset: 0,
            extentOffset: testText.length,
            affinity: TextAffinity.upstream,
          ),
        ),
        reason: 'on $platform',
      );
      expect(controller.text, equals(testText), reason: 'on $platform');
    },
    // On web, using keyboard for selection is handled by the browser.
    skip: kIsWeb, // [intended]
    variant: TargetPlatformVariant.all(),
  );

  testWidgets('home/end keys', (WidgetTester tester) async {
    final String targetPlatformString = defaultTargetPlatform.toString();
    final String platform = targetPlatformString.substring(targetPlatformString.indexOf('.') + 1).toLowerCase();
    final TextEditingController controller = TextEditingController(text: testText);
    controller.selection = const TextSelection(
      baseOffset: 0,
      extentOffset: 0,
      affinity: TextAffinity.upstream,
    );
    late TextSelection selection;
    late SelectionChangedCause cause;
    await tester.pumpWidget(MaterialApp(
      home: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 400,
          child: EditableText(
            maxLines: 10,
            controller: controller,
            showSelectionHandles: true,
            autofocus: true,
            focusNode: FocusNode(),
            style: Typography.material2018().black.subtitle1!,
            cursorColor: Colors.blue,
            backgroundCursorColor: Colors.grey,
            selectionControls: materialTextSelectionControls,
            keyboardType: TextInputType.text,
            textAlign: TextAlign.right,
            onSelectionChanged: (TextSelection newSelection, SelectionChangedCause? newCause) {
              selection = newSelection;
              cause = newCause!;
            },
          ),
        ),
      ),
    ));

    await tester.pump(); // Wait for autofocus to take effect.

    // Move near the middle of the document.
    await sendKeys(
      tester,
      <LogicalKeyboardKey>[
        LogicalKeyboardKey.arrowDown,
        LogicalKeyboardKey.arrowRight,
        LogicalKeyboardKey.arrowRight,
        LogicalKeyboardKey.arrowRight,
      ],
      targetPlatform: defaultTargetPlatform,
    );

    expect(cause, equals(SelectionChangedCause.keyboard), reason: 'on $platform');
    expect(
      selection,
      equals(
        const TextSelection.collapsed(
          offset: 23,
        ),
      ),
      reason: 'on $platform',
    );

    await sendKeys(
      tester,
      <LogicalKeyboardKey>[
        LogicalKeyboardKey.home,
      ],
      targetPlatform: defaultTargetPlatform,
    );

    switch (defaultTargetPlatform) {
      // These platforms don't move the selection with home/end at all.
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.fuchsia:
      case TargetPlatform.macOS:
        expect(
          selection,
          equals(
            const TextSelection.collapsed(
              offset: 23,
            ),
          ),
          reason: 'on $platform',
        );
        break;

      // These platforms go to the line start/end.
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        expect(
          selection,
          equals(
            const TextSelection.collapsed(
              offset: 20,
            ),
          ),
          reason: 'on $platform',
        );
        break;
    }

    expect(controller.text, equals(testText), reason: 'on $platform');

    await sendKeys(
      tester,
      <LogicalKeyboardKey>[
        LogicalKeyboardKey.end,
      ],
      targetPlatform: defaultTargetPlatform,
    );

    switch (defaultTargetPlatform) {
      // These platforms don't move the selection with home/end at all.
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.fuchsia:
      case TargetPlatform.macOS:
        expect(
          selection,
          equals(
            const TextSelection.collapsed(
              offset: 23,
            ),
          ),
          reason: 'on $platform',
        );
        break;

      // These platforms go to the line start/end.
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        expect(
          selection,
          equals(
            const TextSelection.collapsed(
              offset: 35,
              affinity: TextAffinity.upstream,
            ),
          ),
          reason: 'on $platform',
        );
        break;
    }
    expect(controller.text, equals(testText), reason: 'on $platform');
  },
    skip: kIsWeb, // [intended] on web these keys are handled by the browser.
    variant: TargetPlatformVariant.all(),
  );

  testWidgets('home keys and wordwraps', (WidgetTester tester) async {
    final String targetPlatformString = defaultTargetPlatform.toString();
    final String platform = targetPlatformString.substring(targetPlatformString.indexOf('.') + 1).toLowerCase();
    const String testText = 'Now is the time for all good people to come to the aid of their country. Now is the time for all good people to come to the aid of their country.';
    final TextEditingController controller = TextEditingController(text: testText);
    controller.selection = const TextSelection(
      baseOffset: 0,
      extentOffset: 0,
      affinity: TextAffinity.upstream,
    );
    late TextSelection selection;
    late SelectionChangedCause cause;
    await tester.pumpWidget(MaterialApp(
      home: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 400,
          child: EditableText(
            maxLines: 10,
            controller: controller,
            showSelectionHandles: true,
            autofocus: true,
            focusNode: FocusNode(),
            style: Typography.material2018().black.subtitle1!,
            cursorColor: Colors.blue,
            backgroundCursorColor: Colors.grey,
            selectionControls: materialTextSelectionControls,
            keyboardType: TextInputType.text,
            textAlign: TextAlign.right,
            onSelectionChanged: (TextSelection newSelection, SelectionChangedCause? newCause) {
              selection = newSelection;
              cause = newCause!;
            },
          ),
        ),
      ),
    ));

    await tester.pump(); // Wait for autofocus to take effect.

    // Move near the middle of the document.
    await sendKeys(
      tester,
      <LogicalKeyboardKey>[
        LogicalKeyboardKey.arrowDown,
        LogicalKeyboardKey.arrowRight,
        LogicalKeyboardKey.arrowRight,
        LogicalKeyboardKey.arrowRight,
      ],
      targetPlatform: defaultTargetPlatform,
    );

    expect(cause, equals(SelectionChangedCause.keyboard), reason: 'on $platform');
    expect(
      selection,
      equals(
        const TextSelection.collapsed(
          offset: 32,
        ),
      ),
      reason: 'on $platform',
    );

    await sendKeys(
      tester,
      <LogicalKeyboardKey>[
        LogicalKeyboardKey.home,
      ],
      targetPlatform: defaultTargetPlatform,
    );

    switch (defaultTargetPlatform) {
      // These platforms don't move the selection with home/end at all.
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.fuchsia:
      case TargetPlatform.macOS:
        expect(
          selection,
          equals(
            const TextSelection.collapsed(
              offset: 32,
            ),
          ),
          reason: 'on $platform',
        );
        break;

      // These platforms go to the line start/end.
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        expect(
          selection,
          equals(
            const TextSelection.collapsed(
              offset: 29,
            ),
          ),
          reason: 'on $platform',
        );
        break;
    }

    expect(controller.text, equals(testText), reason: 'on $platform');

    await sendKeys(
      tester,
      <LogicalKeyboardKey>[
        LogicalKeyboardKey.home,
      ],
      targetPlatform: defaultTargetPlatform,
    );

    switch (defaultTargetPlatform) {
      // These platforms don't move the selection with home/end at all still.
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.fuchsia:
      case TargetPlatform.macOS:
        expect(
          selection,
          equals(
            const TextSelection.collapsed(
              offset: 32,
            ),
          ),
          reason: 'on $platform',
        );
        break;

      // Linux does nothing at a wordwrap with subsequent presses.
      case TargetPlatform.linux:
        expect(
          selection,
          equals(
            const TextSelection.collapsed(
              offset: 29,
            ),
          ),
          reason: 'on $platform',
        );
        break;

      // Windows jumps to the previous wordwrapped line.
      case TargetPlatform.windows:
        expect(
          selection,
          equals(
            const TextSelection.collapsed(
              offset: 0,
            ),
          ),
          reason: 'on $platform',
        );
        break;
    }
  },
    skip: kIsWeb, // [intended] on web these keys are handled by the browser.
    variant: TargetPlatformVariant.all(),
  );

  testWidgets('end keys and wordwraps', (WidgetTester tester) async {
    final String targetPlatformString = defaultTargetPlatform.toString();
    final String platform = targetPlatformString.substring(targetPlatformString.indexOf('.') + 1).toLowerCase();
    const String testText = 'Now is the time for all good people to come to the aid of their country. Now is the time for all good people to come to the aid of their country.';
    final TextEditingController controller = TextEditingController(text: testText);
    controller.selection = const TextSelection(
      baseOffset: 0,
      extentOffset: 0,
      affinity: TextAffinity.upstream,
    );
    late TextSelection selection;
    late SelectionChangedCause cause;
    await tester.pumpWidget(MaterialApp(
      home: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 400,
          child: EditableText(
            maxLines: 10,
            controller: controller,
            showSelectionHandles: true,
            autofocus: true,
            focusNode: FocusNode(),
            style: Typography.material2018().black.subtitle1!,
            cursorColor: Colors.blue,
            backgroundCursorColor: Colors.grey,
            selectionControls: materialTextSelectionControls,
            keyboardType: TextInputType.text,
            textAlign: TextAlign.right,
            onSelectionChanged: (TextSelection newSelection, SelectionChangedCause? newCause) {
              selection = newSelection;
              cause = newCause!;
            },
          ),
        ),
      ),
    ));

    await tester.pump(); // Wait for autofocus to take effect.

    // Move near the middle of the document.
    await sendKeys(
      tester,
      <LogicalKeyboardKey>[
        LogicalKeyboardKey.arrowDown,
        LogicalKeyboardKey.arrowRight,
        LogicalKeyboardKey.arrowRight,
        LogicalKeyboardKey.arrowRight,
      ],
      targetPlatform: defaultTargetPlatform,
    );

    expect(cause, equals(SelectionChangedCause.keyboard), reason: 'on $platform');
    expect(
      selection,
      equals(
        const TextSelection.collapsed(
          offset: 32,
        ),
      ),
      reason: 'on $platform',
    );

    await sendKeys(
      tester,
      <LogicalKeyboardKey>[
        LogicalKeyboardKey.end,
      ],
      targetPlatform: defaultTargetPlatform,
    );

    switch (defaultTargetPlatform) {
      // These platforms don't move the selection with home/end at all.
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.fuchsia:
      case TargetPlatform.macOS:
        expect(
          selection,
          equals(
            const TextSelection.collapsed(
              offset: 32,
            ),
          ),
          reason: 'on $platform',
        );
        break;

      // These platforms go to the line start/end.
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        expect(
          selection,
          equals(
            const TextSelection.collapsed(
              offset: 58,
              affinity: TextAffinity.upstream,
            ),
          ),
          reason: 'on $platform',
        );
        break;
    }
    expect(controller.text, equals(testText), reason: 'on $platform');

    await sendKeys(
      tester,
      <LogicalKeyboardKey>[
        LogicalKeyboardKey.end,
      ],
      targetPlatform: defaultTargetPlatform,
    );

    switch (defaultTargetPlatform) {
      // These platforms don't move the selection with home/end at all still.
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.fuchsia:
      case TargetPlatform.macOS:
        expect(
          selection,
          equals(
            const TextSelection.collapsed(
              offset: 32,
            ),
          ),
          reason: 'on $platform',
        );
        break;

      // Linux does nothing at a wordwrap with subsequent presses.
      case TargetPlatform.linux:
        expect(
          selection,
          equals(
            const TextSelection.collapsed(
              offset: 58,
              affinity: TextAffinity.upstream,
            ),
          ),
          reason: 'on $platform',
        );
        break;

      // Windows jumps to the next wordwrapped line.
      case TargetPlatform.windows:
        expect(
          selection,
          equals(
            const TextSelection.collapsed(
              offset: 84,
              affinity: TextAffinity.upstream,
            ),
          ),
          reason: 'on $platform',
        );
        break;
    }
  },
    skip: kIsWeb, // [intended] on web these keys are handled by the browser.
    variant: TargetPlatformVariant.all(),
  );

  testWidgets('shift + home/end keys', (WidgetTester tester) async {
    final String targetPlatformString = defaultTargetPlatform.toString();
    final String platform = targetPlatformString.substring(targetPlatformString.indexOf('.') + 1).toLowerCase();
    final TextEditingController controller = TextEditingController(text: testText);
    controller.selection = const TextSelection(
      baseOffset: 0,
      extentOffset: 0,
      affinity: TextAffinity.upstream,
    );
    late TextSelection selection;
    late SelectionChangedCause cause;
    await tester.pumpWidget(MaterialApp(
      home: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 400,
          child: EditableText(
            maxLines: 10,
            controller: controller,
            showSelectionHandles: true,
            autofocus: true,
            focusNode: FocusNode(),
            style: Typography.material2018().black.subtitle1!,
            cursorColor: Colors.blue,
            backgroundCursorColor: Colors.grey,
            selectionControls: materialTextSelectionControls,
            keyboardType: TextInputType.text,
            textAlign: TextAlign.right,
            onSelectionChanged: (TextSelection newSelection, SelectionChangedCause? newCause) {
              selection = newSelection;
              cause = newCause!;
            },
          ),
        ),
      ),
    ));

    await tester.pump();

    // Move near the middle of the document.
    await sendKeys(
      tester,
      <LogicalKeyboardKey>[
        LogicalKeyboardKey.arrowDown,
        LogicalKeyboardKey.arrowRight,
        LogicalKeyboardKey.arrowRight,
        LogicalKeyboardKey.arrowRight,
      ],
      targetPlatform: defaultTargetPlatform,
    );

    expect(cause, equals(SelectionChangedCause.keyboard), reason: 'on $platform');
    expect(
      selection,
      equals(
        const TextSelection.collapsed(
          offset: 23,
        ),
      ),
      reason: 'on $platform',
    );

    await sendKeys(
      tester,
      <LogicalKeyboardKey>[
        LogicalKeyboardKey.home,
      ],
      shift: true,
      targetPlatform: defaultTargetPlatform,
    );

    expect(controller.text, equals(testText), reason: 'on $platform');
    final TextSelection selectionAfterHome = selection;

    // Move back to position 23.
    controller.selection = const TextSelection.collapsed(
      offset: 23,
    );
    await tester.pump();

    await sendKeys(
      tester,
      <LogicalKeyboardKey>[
        LogicalKeyboardKey.end,
      ],
      shift: true,
      targetPlatform: defaultTargetPlatform,
    );

    expect(controller.text, equals(testText), reason: 'on $platform');
    final TextSelection selectionAfterEnd = selection;

    switch (defaultTargetPlatform) {
      // These platforms don't handle shift + home/end at all.
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        expect(
          selectionAfterHome,
          equals(
            const TextSelection(
              baseOffset: 23,
              extentOffset: 23,
            ),
          ),
          reason: 'on $platform',
        );
        expect(
          selectionAfterEnd,
          equals(
            const TextSelection(
              baseOffset: 23,
              extentOffset: 23,
            ),
          ),
          reason: 'on $platform',
        );
        break;

      // Linux extends to the line start/end.
      case TargetPlatform.linux:
        expect(
          selectionAfterHome,
          equals(
            const TextSelection(
              baseOffset: 23,
              extentOffset: 20,
            ),
          ),
          reason: 'on $platform',
        );
        expect(
          selectionAfterEnd,
          equals(
            const TextSelection(
              baseOffset: 23,
              extentOffset: 35,
              affinity: TextAffinity.upstream,
            ),
          ),
          reason: 'on $platform',
        );
        break;

      // Windows expands to the line start/end.
      case TargetPlatform.windows:
        expect(
          selectionAfterHome,
          equals(
            const TextSelection(
              baseOffset: 23,
              extentOffset: 20,
            ),
          ),
          reason: 'on $platform',
        );
        expect(
          selectionAfterEnd,
          equals(
            const TextSelection(
              baseOffset: 23,
              extentOffset: 35,
            ),
          ),
          reason: 'on $platform',
        );
        break;

      // Mac and iOS go to the start/end of the document.
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        expect(
          selectionAfterHome,
          equals(
            const TextSelection(
              baseOffset: 23,
              extentOffset: 0,
              affinity: TextAffinity.upstream,
            ),
          ),
          reason: 'on $platform',
        );
        expect(
          selectionAfterEnd,
          equals(
            const TextSelection(
              baseOffset: 23,
              extentOffset: 72,
            ),
          ),
          reason: 'on $platform',
        );
        break;
    }
  },
    skip: kIsWeb, // [intended] on web these keys are handled by the browser.
    variant: TargetPlatformVariant.all(),
  );

  testWidgets('shift + home/end keys (Windows only)', (WidgetTester tester) async {
    final TextEditingController controller = TextEditingController(text: testText);
    controller.selection = const TextSelection(
      baseOffset: 0,
      extentOffset: 0,
      affinity: TextAffinity.upstream,
    );
    await tester.pumpWidget(MaterialApp(
      home: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 400,
          child: EditableText(
            maxLines: 10,
            controller: controller,
            showSelectionHandles: true,
            autofocus: true,
            focusNode: FocusNode(),
            style: Typography.material2018().black.subtitle1!,
            cursorColor: Colors.blue,
            backgroundCursorColor: Colors.grey,
            selectionControls: materialTextSelectionControls,
            keyboardType: TextInputType.text,
            textAlign: TextAlign.right,
          ),
        ),
      ),
    ));

    await tester.pump();

    // Move the selection away from the start so it can invert.
    await sendKeys(
      tester,
      <LogicalKeyboardKey>[
        LogicalKeyboardKey.arrowRight,
        LogicalKeyboardKey.arrowRight,
        LogicalKeyboardKey.arrowRight,
        LogicalKeyboardKey.arrowRight,
      ],
      targetPlatform: defaultTargetPlatform,
    );
    await tester.pump();
    expect(
      controller.selection,
      equals(const TextSelection.collapsed(
        offset: 4,
      )),
    );

    // Press shift + end and extend the selection to the end of the line.
    await sendKeys(
      tester,
      <LogicalKeyboardKey>[
        LogicalKeyboardKey.end,
      ],
      shift: true,
      targetPlatform: defaultTargetPlatform,
    );
    await tester.pump();
    expect(
      controller.selection,
      equals(const TextSelection(
        baseOffset: 4,
        extentOffset: 19,
        affinity: TextAffinity.upstream,
      )),
    );

    // Press shift + home and the selection inverts and extends to the start, it
    // does not collapse and stop at the inversion.
    await sendKeys(
      tester,
      <LogicalKeyboardKey>[
        LogicalKeyboardKey.home,
      ],
      shift: true,
      targetPlatform: defaultTargetPlatform,
    );
    await tester.pump();
    expect(
      controller.selection,
      equals(const TextSelection(
        baseOffset: 4,
        extentOffset: 0,
      )),
    );

    // Press shift + end again and the selection inverts and extends to the end,
    // again it does not stop at the inversion.
    await sendKeys(
      tester,
      <LogicalKeyboardKey>[
        LogicalKeyboardKey.end,
      ],
      shift: true,
      targetPlatform: defaultTargetPlatform,
    );
    await tester.pump();
    expect(
      controller.selection,
      equals(const TextSelection(
        baseOffset: 4,
        extentOffset: 19,
      )),
    );
  },
    skip: kIsWeb, // [intended] on web these keys are handled by the browser.
    variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.windows })
  );

  testWidgets('home/end keys scrolling (Mac only)', (WidgetTester tester) async {
    const String testText = 'Now is the time for all good people to come to the aid of their country. Now is the time for all good people to come to the aid of their country.';
    final TextEditingController controller = TextEditingController(text: testText);
    controller.selection = const TextSelection(
      baseOffset: 0,
      extentOffset: 0,
      affinity: TextAffinity.upstream,
    );
    await tester.pumpWidget(MaterialApp(
      home: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 400,
          child: EditableText(
            maxLines: 10,
            controller: controller,
            showSelectionHandles: true,
            autofocus: true,
            focusNode: FocusNode(),
            style: Typography.material2018().black.subtitle1!,
            cursorColor: Colors.blue,
            backgroundCursorColor: Colors.grey,
            selectionControls: materialTextSelectionControls,
            keyboardType: TextInputType.text,
            textAlign: TextAlign.right,
          ),
        ),
      ),
    ));

    await tester.pump(); // Wait for autofocus to take effect.

    final Scrollable scrollable = tester.widget<Scrollable>(find.byType(Scrollable));

    expect(scrollable.controller!.offset, 0.0);

    // Scroll to the end of the document with the end key.
    await sendKeys(
      tester,
      <LogicalKeyboardKey>[
        LogicalKeyboardKey.end,
      ],
      targetPlatform: defaultTargetPlatform,
    );
    final double maxScrollExtent = scrollable.controller!.position.maxScrollExtent;
    expect(scrollable.controller!.offset, maxScrollExtent);

    // Scroll back to the beginning of the document with the home key.
    await sendKeys(
      tester,
      <LogicalKeyboardKey>[
        LogicalKeyboardKey.home,
      ],
      targetPlatform: defaultTargetPlatform,
    );
    expect(scrollable.controller!.offset, 0.0);
  },
    skip: kIsWeb, // [intended] on web these keys are handled by the browser.
    variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.macOS })
  );

  testWidgets('shift + home keys and wordwraps', (WidgetTester tester) async {
    final String targetPlatformString = defaultTargetPlatform.toString();
    final String platform = targetPlatformString.substring(targetPlatformString.indexOf('.') + 1).toLowerCase();
    const String testText = 'Now is the time for all good people to come to the aid of their country. Now is the time for all good people to come to the aid of their country.';
    final TextEditingController controller = TextEditingController(text: testText);
    controller.selection = const TextSelection(
      baseOffset: 0,
      extentOffset: 0,
      affinity: TextAffinity.upstream,
    );
    late TextSelection selection;
    late SelectionChangedCause cause;
    await tester.pumpWidget(MaterialApp(
      home: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 400,
          child: EditableText(
            maxLines: 10,
            controller: controller,
            showSelectionHandles: true,
            autofocus: true,
            focusNode: FocusNode(),
            style: Typography.material2018().black.subtitle1!,
            cursorColor: Colors.blue,
            backgroundCursorColor: Colors.grey,
            selectionControls: materialTextSelectionControls,
            keyboardType: TextInputType.text,
            textAlign: TextAlign.right,
            onSelectionChanged: (TextSelection newSelection, SelectionChangedCause? newCause) {
              selection = newSelection;
              cause = newCause!;
            },
          ),
        ),
      ),
    ));

    await tester.pump(); // Wait for autofocus to take effect.

    // Move near the middle of the document.
    await sendKeys(
      tester,
      <LogicalKeyboardKey>[
        LogicalKeyboardKey.arrowDown,
        LogicalKeyboardKey.arrowRight,
        LogicalKeyboardKey.arrowRight,
        LogicalKeyboardKey.arrowRight,
      ],
      targetPlatform: defaultTargetPlatform,
    );

    expect(cause, equals(SelectionChangedCause.keyboard), reason: 'on $platform');
    expect(
      selection,
      equals(
        const TextSelection.collapsed(
          offset: 32,
        ),
      ),
      reason: 'on $platform',
    );

    await sendKeys(
      tester,
      <LogicalKeyboardKey>[
        LogicalKeyboardKey.home,
      ],
      shift: true,
      targetPlatform: defaultTargetPlatform,
    );

    switch (defaultTargetPlatform) {
      // These platforms don't move the selection with shift + home/end at all.
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        expect(
          selection,
          equals(
            const TextSelection.collapsed(
              offset: 32,
            ),
          ),
          reason: 'on $platform',
        );
        break;

      // Mac and iOS select to the start of the document.
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        expect(
          selection,
          equals(
            const TextSelection(
              baseOffset: 32,
              extentOffset: 0,
            ),
          ),
          reason: 'on $platform',
        );
        break;

      // These platforms select to the line start.
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        expect(
          selection,
          equals(
            const TextSelection(
              baseOffset: 32,
              extentOffset: 29,
            ),
          ),
          reason: 'on $platform',
        );
        break;
    }

    expect(controller.text, equals(testText), reason: 'on $platform');

    await sendKeys(
      tester,
      <LogicalKeyboardKey>[
        LogicalKeyboardKey.home,
      ],
      shift: true,
      targetPlatform: defaultTargetPlatform,
    );

    switch (defaultTargetPlatform) {
      // These platforms don't move the selection with home/end at all still.
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        expect(
          selection,
          equals(
            const TextSelection.collapsed(
              offset: 32,
            ),
          ),
          reason: 'on $platform',
        );
        break;

      // Mac and iOS select to the start of the document.
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        expect(
          selection,
          equals(
            const TextSelection(
              baseOffset: 32,
              extentOffset: 0,
            ),
          ),
          reason: 'on $platform',
        );
        break;

      // Linux does nothing at a wordwrap with subsequent presses.
      case TargetPlatform.linux:
        expect(
          selection,
          equals(
            const TextSelection(
              baseOffset: 32,
              extentOffset: 29,
            ),
          ),
          reason: 'on $platform',
        );
        break;

      // Windows jumps to the previous wordwrapped line.
      case TargetPlatform.windows:
        expect(
          selection,
          equals(
            const TextSelection(
              baseOffset: 32,
              extentOffset: 0,
            ),
          ),
          reason: 'on $platform',
        );
        break;
    }
  },
    skip: kIsWeb, // [intended] on web these keys are handled by the browser.
    variant: TargetPlatformVariant.all(),
  );

  testWidgets('shift + end keys and wordwraps', (WidgetTester tester) async {
    final String targetPlatformString = defaultTargetPlatform.toString();
    final String platform = targetPlatformString.substring(targetPlatformString.indexOf('.') + 1).toLowerCase();
    const String testText = 'Now is the time for all good people to come to the aid of their country. Now is the time for all good people to come to the aid of their country.';
    final TextEditingController controller = TextEditingController(text: testText);
    controller.selection = const TextSelection(
      baseOffset: 0,
      extentOffset: 0,
      affinity: TextAffinity.upstream,
    );
    late TextSelection selection;
    late SelectionChangedCause cause;
    await tester.pumpWidget(MaterialApp(
      home: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 400,
          child: EditableText(
            maxLines: 10,
            controller: controller,
            showSelectionHandles: true,
            autofocus: true,
            focusNode: FocusNode(),
            style: Typography.material2018().black.subtitle1!,
            cursorColor: Colors.blue,
            backgroundCursorColor: Colors.grey,
            selectionControls: materialTextSelectionControls,
            keyboardType: TextInputType.text,
            textAlign: TextAlign.right,
            onSelectionChanged: (TextSelection newSelection, SelectionChangedCause? newCause) {
              selection = newSelection;
              cause = newCause!;
            },
          ),
        ),
      ),
    ));

    await tester.pump(); // Wait for autofocus to take effect.

    // Move near the middle of the document.
    await sendKeys(
      tester,
      <LogicalKeyboardKey>[
        LogicalKeyboardKey.arrowDown,
        LogicalKeyboardKey.arrowRight,
        LogicalKeyboardKey.arrowRight,
        LogicalKeyboardKey.arrowRight,
      ],
      targetPlatform: defaultTargetPlatform,
    );

    expect(cause, equals(SelectionChangedCause.keyboard), reason: 'on $platform');
    expect(
      selection,
      equals(
        const TextSelection.collapsed(
          offset: 32,
        ),
      ),
      reason: 'on $platform',
    );

    await sendKeys(
      tester,
      <LogicalKeyboardKey>[
        LogicalKeyboardKey.end,
      ],
      shift: true,
      targetPlatform: defaultTargetPlatform,
    );

    switch (defaultTargetPlatform) {
      // These platforms don't move the selection with home/end at all.
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        expect(
          selection,
          equals(
            const TextSelection.collapsed(
              offset: 32,
            ),
          ),
          reason: 'on $platform',
        );
        break;

      // Mac and iOS select to the end of the document.
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        expect(
          selection,
          equals(
            const TextSelection(
              baseOffset: 32,
              extentOffset: 145,
            ),
          ),
          reason: 'on $platform',
        );
        break;

      // These platforms select to the line end.
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        expect(
          selection,
          equals(
            const TextSelection(
              baseOffset: 32,
              extentOffset: 58,
              affinity: TextAffinity.upstream,
            ),
          ),
          reason: 'on $platform',
        );
        break;
    }
    expect(controller.text, equals(testText), reason: 'on $platform');

    await sendKeys(
      tester,
      <LogicalKeyboardKey>[
        LogicalKeyboardKey.end,
      ],
      shift: true,
      targetPlatform: defaultTargetPlatform,
    );

    switch (defaultTargetPlatform) {
      // These platforms don't move the selection with home/end at all still.
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        expect(
          selection,
          equals(
            const TextSelection.collapsed(
              offset: 32,
            ),
          ),
          reason: 'on $platform',
        );
        break;

      // Mac and iOS stay at the end of the document.
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        expect(
          selection,
          equals(
            const TextSelection(
              baseOffset: 32,
              extentOffset: 145,
            ),
          ),
          reason: 'on $platform',
        );
        break;

      // Linux does nothing at a wordwrap with subsequent presses.
      case TargetPlatform.linux:
        expect(
          selection,
          equals(
            const TextSelection(
              baseOffset: 32,
              extentOffset: 58,
              affinity: TextAffinity.upstream,
            ),
          ),
          reason: 'on $platform',
        );
        break;

      // Windows jumps to the previous wordwrapped line.
      case TargetPlatform.windows:
        expect(
          selection,
          equals(
            const TextSelection(
              baseOffset: 32,
              extentOffset: 84,
              affinity: TextAffinity.upstream,
            ),
          ),
          reason: 'on $platform',
        );
        break;
    }
  },
    skip: kIsWeb, // [intended] on web these keys are handled by the browser.
    variant: TargetPlatformVariant.all(),
  );

  testWidgets('shift + home/end keys to document boundary (Mac only)', (WidgetTester tester) async {
    const String testText = 'Now is the time for all good people to come to the aid of their country. Now is the time for all good people to come to the aid of their country.';
    final TextEditingController controller = TextEditingController(text: testText);
    controller.selection = const TextSelection(
      baseOffset: 0,
      extentOffset: 0,
      affinity: TextAffinity.upstream,
    );
    late TextSelection selection;
    await tester.pumpWidget(MaterialApp(
      home: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 400,
          child: EditableText(
            maxLines: 10,
            controller: controller,
            showSelectionHandles: true,
            autofocus: true,
            focusNode: FocusNode(),
            style: Typography.material2018().black.subtitle1!,
            cursorColor: Colors.blue,
            backgroundCursorColor: Colors.grey,
            selectionControls: materialTextSelectionControls,
            keyboardType: TextInputType.text,
            textAlign: TextAlign.right,
            onSelectionChanged: (TextSelection newSelection, SelectionChangedCause? newCause) {
              selection = newSelection;
            },
          ),
        ),
      ),
    ));

    await tester.pump(); // Wait for autofocus to take effect.

    final Scrollable scrollable = tester.widget<Scrollable>(find.byType(Scrollable));
    expect(scrollable.controller!.offset, 0.0);

    // Move near the middle of the document.
    await sendKeys(
      tester,
      <LogicalKeyboardKey>[
        LogicalKeyboardKey.arrowDown,
        LogicalKeyboardKey.arrowRight,
        LogicalKeyboardKey.arrowRight,
        LogicalKeyboardKey.arrowRight,
      ],
      targetPlatform: defaultTargetPlatform,
    );
    expect(
      selection,
      equals(
        const TextSelection.collapsed(
          offset: 32,
        ),
      ),
    );

    // Expand to the start of the document with the home key.
    await sendKeys(
      tester,
      <LogicalKeyboardKey>[
        LogicalKeyboardKey.home,
      ],
      shift: true,
      targetPlatform: defaultTargetPlatform,
    );
    expect(scrollable.controller!.offset, 0.0);
    expect(
      selection,
      equals(
        const TextSelection(
          baseOffset: 32,
          extentOffset: 0,
        ),
      ),
    );

    // Expand to the end of the document with the end key.
    await sendKeys(
      tester,
      <LogicalKeyboardKey>[
        LogicalKeyboardKey.end,
      ],
      shift: true,
      targetPlatform: defaultTargetPlatform,
    );
    final double maxScrollExtent = scrollable.controller!.position.maxScrollExtent;
    expect(scrollable.controller!.offset, maxScrollExtent);
    expect(
      selection,
      equals(
        const TextSelection(
          baseOffset: 0,
          extentOffset: 145,
        ),
      ),
    );
  },
    skip: kIsWeb, // [intended] on web these keys are handled by the browser.
    variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.macOS })
  );

  testWidgets('control + home/end keys (Windows only)', (WidgetTester tester) async {
    final TextEditingController controller = TextEditingController(text: testText);
    controller.selection = const TextSelection(
      baseOffset: 0,
      extentOffset: 0,
      affinity: TextAffinity.upstream,
    );
    await tester.pumpWidget(MaterialApp(
      home: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 400,
          child: EditableText(
            maxLines: 10,
            controller: controller,
            showSelectionHandles: true,
            autofocus: true,
            focusNode: FocusNode(),
            style: Typography.material2018().black.subtitle1!,
            cursorColor: Colors.blue,
            backgroundCursorColor: Colors.grey,
            selectionControls: materialTextSelectionControls,
            keyboardType: TextInputType.text,
            textAlign: TextAlign.right,
          ),
        ),
      ),
    ));

    await tester.pump();

    await sendKeys(
      tester,
      <LogicalKeyboardKey>[
        LogicalKeyboardKey.end,
      ],
      shortcutModifier: true,
      targetPlatform: defaultTargetPlatform,
    );
    await tester.pump();
    expect(
      controller.selection,
      equals(const TextSelection.collapsed(
        offset: testText.length,
        affinity: TextAffinity.upstream,
      )),
    );

    await sendKeys(
      tester,
      <LogicalKeyboardKey>[
        LogicalKeyboardKey.home,
      ],
      shortcutModifier: true,
      targetPlatform: defaultTargetPlatform,
    );
    await tester.pump();
    expect(
      controller.selection,
      equals(const TextSelection.collapsed(offset: 0)),
    );
  },
    skip: kIsWeb, // [intended] on web these keys are handled by the browser.
    variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.windows })
  );

  testWidgets('control + shift + home/end keys (Windows only)', (WidgetTester tester) async {
    final TextEditingController controller = TextEditingController(text: testText);
    controller.selection = const TextSelection(
      baseOffset: 0,
      extentOffset: 0,
      affinity: TextAffinity.upstream,
    );
    await tester.pumpWidget(MaterialApp(
      home: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 400,
          child: EditableText(
            maxLines: 10,
            controller: controller,
            showSelectionHandles: true,
            autofocus: true,
            focusNode: FocusNode(),
            style: Typography.material2018().black.subtitle1!,
            cursorColor: Colors.blue,
            backgroundCursorColor: Colors.grey,
            selectionControls: materialTextSelectionControls,
            keyboardType: TextInputType.text,
            textAlign: TextAlign.right,
          ),
        ),
      ),
    ));

    await tester.pump();

    await sendKeys(
      tester,
      <LogicalKeyboardKey>[
        LogicalKeyboardKey.end,
      ],
      shortcutModifier: true,
      shift: true,
      targetPlatform: defaultTargetPlatform,
    );
    await tester.pump();
    expect(
      controller.selection,
      equals(const TextSelection(
        baseOffset: 0,
        extentOffset: testText.length,
      )),
    );

    // Collapse the selection at the end.
    await sendKeys(
      tester,
      <LogicalKeyboardKey>[
        LogicalKeyboardKey.arrowRight,
      ],
      targetPlatform: defaultTargetPlatform,
    );
    await tester.pump();
    expect(
      controller.selection,
      equals(const TextSelection.collapsed(
        offset: testText.length,
        affinity: TextAffinity.upstream,
      )),
    );

    await sendKeys(
      tester,
      <LogicalKeyboardKey>[
        LogicalKeyboardKey.home,
      ],
      shortcutModifier: true,
      shift: true,
      targetPlatform: defaultTargetPlatform,
    );
    await tester.pump();
    expect(
      controller.selection,
      equals(const TextSelection(
        baseOffset: testText.length,
        extentOffset: 0,
      )),
    );
  },
    skip: kIsWeb, // [intended] on web these keys are handled by the browser.
    variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.windows })
  );

  // Regression test for https://github.com/flutter/flutter/issues/31287
  testWidgets('text selection handle visibility', (WidgetTester tester) async {
    // Text with two separate words to select.
    const String testText = 'XXXXX          XXXXX';
    final TextEditingController controller = TextEditingController(text: testText);

    await tester.pumpWidget(MaterialApp(
      home: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 100,
          child: EditableText(
            showSelectionHandles: true,
            controller: controller,
            focusNode: FocusNode(),
            style: Typography.material2018(platform: TargetPlatform.iOS).black.subtitle1!,
            cursorColor: Colors.blue,
            backgroundCursorColor: Colors.grey,
            selectionControls: cupertinoTextSelectionControls,
            keyboardType: TextInputType.text,
          ),
        ),
      ),
    ));

    final EditableTextState state =
        tester.state<EditableTextState>(find.byType(EditableText));
    final RenderEditable renderEditable = state.renderEditable;
    final Scrollable scrollable = tester.widget<Scrollable>(find.byType(Scrollable));

    bool expectedLeftVisibleBefore = false;
    bool expectedRightVisibleBefore = false;

    Future<void> verifyVisibility(
      HandlePositionInViewport leftPosition,
      bool expectedLeftVisible,
      HandlePositionInViewport rightPosition,
      bool expectedRightVisible,
    ) async {
      await tester.pump();

      // Check the signal from RenderEditable about whether they're within the
      // viewport.

      expect(renderEditable.selectionStartInViewport.value, equals(expectedLeftVisible));
      expect(renderEditable.selectionEndInViewport.value, equals(expectedRightVisible));

      // Check that the animations are functional and going in the right
      // direction.

      final List<FadeTransition> transitions =
        find.byType(FadeTransition).evaluate().map((Element e) => e.widget).cast<FadeTransition>().toList();
      final FadeTransition left = transitions[0];
      final FadeTransition right = transitions[1];

      if (expectedLeftVisibleBefore) {
        expect(left.opacity.value, equals(1.0));
      }
      if (expectedRightVisibleBefore) {
        expect(right.opacity.value, equals(1.0));
      }

      await tester.pump(SelectionOverlay.fadeDuration ~/ 2);

      if (expectedLeftVisible != expectedLeftVisibleBefore) {
        expect(left.opacity.value, equals(0.5));
      }
      if (expectedRightVisible != expectedRightVisibleBefore) {
        expect(right.opacity.value, equals(0.5));
      }

      await tester.pump(SelectionOverlay.fadeDuration ~/ 2);

      if (expectedLeftVisible) {
        expect(left.opacity.value, equals(1.0));
      }
      if (expectedRightVisible) {
        expect(right.opacity.value, equals(1.0));
      }

      expectedLeftVisibleBefore = expectedLeftVisible;
      expectedRightVisibleBefore = expectedRightVisible;

      // Check that the handles' positions are correct.

      final List<RenderBox> handles = List<RenderBox>.from(
        tester.renderObjectList<RenderBox>(
          find.descendant(
            of: find.byType(CompositedTransformFollower),
            matching: find.byType(Padding),
          ),
        ),
      );

      final Size viewport = renderEditable.size;

      void testPosition(double pos, HandlePositionInViewport expected) {
        switch (expected) {
          case HandlePositionInViewport.leftEdge:
            expect(
              pos,
              inExclusiveRange(
                0 - kMinInteractiveDimension,
                0 + kMinInteractiveDimension,
              ),
            );
            break;
          case HandlePositionInViewport.rightEdge:
            expect(
              pos,
              inExclusiveRange(
                viewport.width - kMinInteractiveDimension,
                viewport.width + kMinInteractiveDimension,
              ),
            );
            break;
          case HandlePositionInViewport.within:
            expect(
              pos,
              inExclusiveRange(
                0 - kMinInteractiveDimension,
                viewport.width + kMinInteractiveDimension,
              ),
            );
            break;
        }
      }
      expect(state.selectionOverlay!.handlesAreVisible, isTrue);
      testPosition(handles[0].localToGlobal(Offset.zero).dx, leftPosition);
      testPosition(handles[1].localToGlobal(Offset.zero).dx, rightPosition);
    }

    // Select the first word. Both handles should be visible.
    await tester.tapAt(const Offset(20, 10));
    renderEditable.selectWord(cause: SelectionChangedCause.longPress);
    await tester.pump();
    await verifyVisibility(HandlePositionInViewport.leftEdge, true, HandlePositionInViewport.within, true);

    // Drag the text slightly so the first word is partially visible. Only the
    // right handle should be visible.
    scrollable.controller!.jumpTo(20.0);
    await verifyVisibility(HandlePositionInViewport.leftEdge, false, HandlePositionInViewport.within, true);

    // Drag the text all the way to the left so the first word is not visible at
    // all (and the second word is fully visible). Both handles should be
    // invisible now.
    scrollable.controller!.jumpTo(200.0);
    await verifyVisibility(HandlePositionInViewport.leftEdge, false, HandlePositionInViewport.leftEdge, false);

    // Tap to unselect.
    await tester.tap(find.byType(EditableText));
    await tester.pump();

    // Now that the second word has been dragged fully into view, select it.
    await tester.tapAt(const Offset(80, 10));
    renderEditable.selectWord(cause: SelectionChangedCause.longPress);
    await tester.pump();
    await verifyVisibility(HandlePositionInViewport.within, true, HandlePositionInViewport.within, true);

    // Drag the text slightly to the right. Only the left handle should be
    // visible.
    scrollable.controller!.jumpTo(150);
    await verifyVisibility(HandlePositionInViewport.within, true, HandlePositionInViewport.rightEdge, false);

    // Drag the text all the way to the right, so the second word is not visible
    // at all. Again, both handles should be invisible.
    scrollable.controller!.jumpTo(0);
    await verifyVisibility(HandlePositionInViewport.rightEdge, false, HandlePositionInViewport.rightEdge, false);

  },
      // On web, we don't show the Flutter toolbar and instead rely on the browser
      // toolbar. Until we change that, this test should remain skipped.
      skip: kIsWeb, // [intended]
      variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.iOS, TargetPlatform.macOS })
  );

  testWidgets("scrolling doesn't bounce", (WidgetTester tester) async {
    // 3 lines of text, where the last line overflows and requires scrolling.
    const String testText = 'XXXXX\nXXXXX\nXXXXX';
    final TextEditingController controller = TextEditingController(text: testText);

    await tester.pumpWidget(MaterialApp(
      home: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 100,
          child: EditableText(
            showSelectionHandles: true,
            maxLines: 2,
            controller: controller,
            focusNode: FocusNode(),
            style: Typography.material2018().black.subtitle1!.copyWith(fontFamily: 'Roboto'),
            cursorColor: Colors.blue,
            backgroundCursorColor: Colors.grey,
            selectionControls: materialTextSelectionControls,
            keyboardType: TextInputType.text,
          ),
        ),
      ),
    ));

    final EditableTextState state =
      tester.state<EditableTextState>(find.byType(EditableText));
    final RenderEditable renderEditable = state.renderEditable;
    final Scrollable scrollable = tester.widget<Scrollable>(find.byType(Scrollable));

    expect(scrollable.controller!.position.viewportDimension, equals(28));
    expect(scrollable.controller!.position.pixels, equals(0));

    expect(renderEditable.maxScrollExtent, equals(14));

    scrollable.controller!.jumpTo(20.0);
    await tester.pump();
    expect(scrollable.controller!.position.pixels, equals(20));

    state.bringIntoView(const TextPosition(offset: 0));
    await tester.pump();
    expect(scrollable.controller!.position.pixels, equals(0));


    state.bringIntoView(const TextPosition(offset: 13));
    await tester.pump();
    expect(scrollable.controller!.position.pixels, equals(14));
    expect(scrollable.controller!.position.pixels, equals(renderEditable.maxScrollExtent));
  });

  testWidgets('bringIntoView brings the caret into view when in a viewport', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/55547.
    final TextEditingController controller = TextEditingController(text: testText * 20);
    final ScrollController editableScrollController = ScrollController();
    final ScrollController outerController = ScrollController();

    await tester.pumpWidget(MaterialApp(
      home: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 200,
          height: 200,
          child: SingleChildScrollView(
            controller: outerController,
            child: EditableText(
              maxLines: null,
              controller: controller,
              scrollController: editableScrollController,
              focusNode: FocusNode(),
              style: textStyle,
              cursorColor: Colors.blue,
              backgroundCursorColor: Colors.grey,
            ),
          ),
        ),
      ),
    ));


    expect(outerController.offset, 0);
    expect(editableScrollController.offset, 0);

    final EditableTextState state = tester.state<EditableTextState>(find.byType(EditableText));
    state.bringIntoView(TextPosition(offset: controller.text.length));

    await tester.pumpAndSettle();
    // The SingleChildScrollView is scrolled instead of the EditableText to
    // reveal the caret.
    expect(outerController.offset, outerController.position.maxScrollExtent);
    expect(editableScrollController.offset, 0);
  });

  testWidgets('bringIntoView does nothing if the physics prohibits implicit scrolling', (WidgetTester tester) async {
    final TextEditingController controller = TextEditingController(text: testText * 20);
    final ScrollController scrollController = ScrollController();

    Future<void> buildWithPhysics({ ScrollPhysics? physics }) async {
      await tester.pumpWidget(MaterialApp(
        home: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 200,
            height: 200,
            child: EditableText(
              maxLines: null,
              controller: controller,
              scrollController: scrollController,
              focusNode: FocusNode(),
              style: textStyle,
              cursorColor: Colors.blue,
              backgroundCursorColor: Colors.grey,
              scrollPhysics: physics,
            ),
          ),
        ),
      ));
    }


    await buildWithPhysics();
    expect(scrollController.offset, 0);

    final EditableTextState state = tester.state<EditableTextState>(find.byType(EditableText));
    state.bringIntoView(TextPosition(offset: controller.text.length));

    await tester.pumpAndSettle();
    // Scrolled to the maxScrollExtent to reveal to caret.
    expect(scrollController.offset, scrollController.position.maxScrollExtent);

    scrollController.jumpTo(0);
    await buildWithPhysics(physics: const NoImplicitScrollPhysics());
    expect(scrollController.offset, 0);

    state.bringIntoView(TextPosition(offset: controller.text.length));

    await tester.pumpAndSettle();
    expect(scrollController.offset, 0);
  });

  testWidgets('can change scroll controller', (WidgetTester tester) async {
    final _TestScrollController scrollController1 = _TestScrollController();
    final _TestScrollController scrollController2 = _TestScrollController();

    await tester.pumpWidget(
      MaterialApp(
        home: EditableText(
          controller: TextEditingController(text: 'A' * 1000),
          focusNode: FocusNode(),
          style: textStyle,
          cursorColor: Colors.blue,
          backgroundCursorColor: Colors.grey,
          scrollController: scrollController1,
        ),
      ),
    );

    expect(scrollController1.attached, isTrue);
    expect(scrollController2.attached, isFalse);

    // Change scrollController to controller 2.
    await tester.pumpWidget(
      MaterialApp(
        home: EditableText(
          controller: TextEditingController(text: 'A' * 1000),
          focusNode: FocusNode(),
          style: textStyle,
          cursorColor: Colors.blue,
          backgroundCursorColor: Colors.grey,
          scrollController: scrollController2,
        ),
      ),
    );

    expect(scrollController1.attached, isFalse);
    expect(scrollController2.attached, isTrue);

    // Changing scrollController to null.
    await tester.pumpWidget(
      MaterialApp(
        home: EditableText(
          controller: TextEditingController(text: 'A' * 1000),
          focusNode: FocusNode(),
          style: textStyle,
          cursorColor: Colors.blue,
          backgroundCursorColor: Colors.grey,
        ),
      ),
    );

    expect(scrollController1.attached, isFalse);
    expect(scrollController2.attached, isFalse);

    // Change scrollController to back controller 2.
    await tester.pumpWidget(
      MaterialApp(
        home: EditableText(
          controller: TextEditingController(text: 'A' * 1000),
          focusNode: FocusNode(),
          style: textStyle,
          cursorColor: Colors.blue,
          backgroundCursorColor: Colors.grey,
          scrollController: scrollController2,
        ),
      ),
    );

    expect(scrollController1.attached, isFalse);
    expect(scrollController2.attached, isTrue);
  });

  testWidgets('getLocalRectForCaret does not throw when it sees an infinite point', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SkipPainting(
          child: Transform(
            transform: Matrix4.zero(),
            child: EditableText(
              controller: TextEditingController(),
              focusNode: FocusNode(),
              style: textStyle,
              cursorColor: Colors.blue,
              backgroundCursorColor: Colors.grey,
            ),
          ),
        ),
      ),
    );

    final EditableTextState state = tester.state<EditableTextState>(find.byType(EditableText));
    final Rect rect = state.renderEditable.getLocalRectForCaret(const TextPosition(offset: 0));
    expect(rect.isFinite, true);
    expect(tester.takeException(), isNull);
  });

  testWidgets('obscured multiline fields throw an exception', (WidgetTester tester) async {
    final TextEditingController controller = TextEditingController();
    expect(
      () {
        EditableText(
          backgroundCursorColor: cursorColor,
          controller: controller,
          cursorColor: cursorColor,
          focusNode: focusNode,
          obscureText: true,
          style: textStyle,
        );
      },
      returnsNormally,
    );
    expect(
      () {
        EditableText(
          backgroundCursorColor: cursorColor,
          controller: controller,
          cursorColor: cursorColor,
          focusNode: focusNode,
          maxLines: 2,
          obscureText: true,
          style: textStyle,
        );
      },
      throwsAssertionError,
    );
  });

  group('batch editing', () {
    final TextEditingController controller = TextEditingController(text: testText);
    final EditableText editableText = EditableText(
      showSelectionHandles: true,
      maxLines: 2,
      controller: controller,
      focusNode: FocusNode(),
      cursorColor: Colors.red,
      backgroundCursorColor: Colors.blue,
      style: Typography.material2018().black.subtitle1!.copyWith(fontFamily: 'Roboto'),
      keyboardType: TextInputType.text,
    );

    final Widget widget = MediaQuery(
      data: const MediaQueryData(),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: editableText,
      ),
    );

    testWidgets('batch editing works', (WidgetTester tester) async {
      await tester.pumpWidget(widget);

      // Connect.
      await tester.showKeyboard(find.byType(EditableText));

      final EditableTextState state = tester.state<EditableTextState>(find.byWidget(editableText));
      state.updateEditingValue(const TextEditingValue(text: 'remote value'));
      tester.testTextInput.log.clear();

      state.beginBatchEdit();

      controller.text = 'new change 1';
      expect(state.currentTextEditingValue.text, 'new change 1');
      expect(tester.testTextInput.log, isEmpty);

      // Nesting.
      state.beginBatchEdit();
      controller.text = 'new change 2';
      expect(state.currentTextEditingValue.text, 'new change 2');
      expect(tester.testTextInput.log, isEmpty);

      // End the innermost batch edit. Not yet.
      state.endBatchEdit();
      expect(tester.testTextInput.log, isEmpty);

      controller.text = 'new change 3';
      expect(state.currentTextEditingValue.text, 'new change 3');
      expect(tester.testTextInput.log, isEmpty);

      // Finish the outermost batch edit.
      state.endBatchEdit();
      expect(tester.testTextInput.log, hasLength(1));
      expect(
        tester.testTextInput.log,
        contains(matchesMethodCall('TextInput.setEditingState', args: containsPair('text', 'new change 3'))),
      );
    });

    testWidgets('batch edits need to be nested properly', (WidgetTester tester) async {
      await tester.pumpWidget(widget);

      // Connect.
      await tester.showKeyboard(find.byType(EditableText));

      final EditableTextState state = tester.state<EditableTextState>(find.byWidget(editableText));
      state.updateEditingValue(const TextEditingValue(text: 'remote value'));
      tester.testTextInput.log.clear();

      String? errorString;
      try {
        state.endBatchEdit();
      } catch (e) {
        errorString = e.toString();
      }

      expect(errorString, contains('Unbalanced call to endBatchEdit'));
    });

     testWidgets('catch unfinished batch edits on disposal', (WidgetTester tester) async {
      await tester.pumpWidget(widget);

      // Connect.
      await tester.showKeyboard(find.byType(EditableText));

      final EditableTextState state = tester.state<EditableTextState>(find.byWidget(editableText));
      state.updateEditingValue(const TextEditingValue(text: 'remote value'));
      tester.testTextInput.log.clear();

      state.beginBatchEdit();
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(Container());
      expect(tester.takeException(), isNotNull);
    });
  });

  group('EditableText does not send editing values more than once', () {
    final TextEditingController controller = TextEditingController(text: testText);
    final EditableText editableText = EditableText(
      showSelectionHandles: true,
      maxLines: 2,
      controller: controller,
      focusNode: FocusNode(),
      cursorColor: Colors.red,
      backgroundCursorColor: Colors.blue,
      style: Typography.material2018().black.subtitle1!.copyWith(fontFamily: 'Roboto'),
      keyboardType: TextInputType.text,
      inputFormatters: <TextInputFormatter>[LengthLimitingTextInputFormatter(6)],
      onChanged: (String s) => controller.text += ' onChanged',
    );

    final Widget widget = MediaQuery(
      data: const MediaQueryData(),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: editableText,
      ),
    );

    controller.addListener(() {
      if (!controller.text.endsWith('listener')) {
        controller.text += ' listener';
      }
    });

    testWidgets('input from text input plugin', (WidgetTester tester) async {
      await tester.pumpWidget(widget);

      // Connect.
      await tester.showKeyboard(find.byType(EditableText));
      tester.testTextInput.log.clear();

      final EditableTextState state = tester.state<EditableTextState>(find.byWidget(editableText));
      state.updateEditingValue(const TextEditingValue(text: 'remoteremoteremote'));

      // Apply in order: length formatter -> listener -> onChanged -> listener.
      expect(controller.text, 'remote listener onChanged listener');
      final List<TextEditingValue> updates = tester.testTextInput.log
        .where((MethodCall call) => call.method == 'TextInput.setEditingState')
        .map((MethodCall call) => TextEditingValue.fromJSON(call.arguments as Map<String, dynamic>))
        .toList(growable: false);

      expect(updates, const <TextEditingValue>[TextEditingValue(text: 'remote listener onChanged listener')]);

      tester.testTextInput.log.clear();

      // If by coincidence the text input plugin sends the same value back,
      // do nothing.
      state.updateEditingValue(const TextEditingValue(text: 'remote listener onChanged listener'));
      expect(controller.text, 'remote listener onChanged listener');
      expect(tester.testTextInput.log, isEmpty);
    });

    testWidgets('input from text selection menu', (WidgetTester tester) async {
      await tester.pumpWidget(widget);

      // Connect.
      await tester.showKeyboard(find.byType(EditableText));
      tester.testTextInput.log.clear();

      final EditableTextState state = tester.state<EditableTextState>(find.byWidget(editableText));
      state.userUpdateTextEditingValue(const TextEditingValue(text: 'remoteremoteremote'), SelectionChangedCause.keyboard);

      // Apply in order: length formatter -> listener -> onChanged -> listener.
      expect(controller.text, 'remote listener onChanged listener');
      final List<TextEditingValue> updates = tester.testTextInput.log
        .where((MethodCall call) => call.method == 'TextInput.setEditingState')
        .map((MethodCall call) => TextEditingValue.fromJSON(call.arguments as Map<String, dynamic>))
        .toList(growable: false);

      expect(updates, const <TextEditingValue>[TextEditingValue(text: 'remote listener onChanged listener')]);

      tester.testTextInput.log.clear();
    });

    testWidgets('input from controller', (WidgetTester tester) async {
      await tester.pumpWidget(widget);

      // Connect.
      await tester.showKeyboard(find.byType(EditableText));
      tester.testTextInput.log.clear();

      controller.text = 'remoteremoteremote';
      final List<TextEditingValue> updates = tester.testTextInput.log
        .where((MethodCall call) => call.method == 'TextInput.setEditingState')
        .map((MethodCall call) => TextEditingValue.fromJSON(call.arguments as Map<String, dynamic>))
        .toList(growable: false);

      expect(updates, const <TextEditingValue>[TextEditingValue(text: 'remoteremoteremote listener')]);
    });

    testWidgets('input from changing controller', (WidgetTester tester) async {
      final TextEditingController controller = TextEditingController(text: testText);
      Widget build({ TextEditingController? textEditingController }) {
        return MediaQuery(
          data: const MediaQueryData(),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: EditableText(
              showSelectionHandles: true,
              maxLines: 2,
              controller: textEditingController ?? controller,
              focusNode: FocusNode(),
              cursorColor: Colors.red,
              backgroundCursorColor: Colors.blue,
              style: Typography.material2018().black.subtitle1!.copyWith(fontFamily: 'Roboto'),
              keyboardType: TextInputType.text,
              inputFormatters: <TextInputFormatter>[LengthLimitingTextInputFormatter(6)],
            ),
          ),
        );
      }

      await tester.pumpWidget(build());

      // Connect.
      await tester.showKeyboard(find.byType(EditableText));
      tester.testTextInput.log.clear();
      await tester.pumpWidget(build(textEditingController: TextEditingController(text: 'new text')));

      List<TextEditingValue> updates = tester.testTextInput.log
        .where((MethodCall call) => call.method == 'TextInput.setEditingState')
        .map((MethodCall call) => TextEditingValue.fromJSON(call.arguments as Map<String, dynamic>))
        .toList(growable: false);

      expect(updates, const <TextEditingValue>[TextEditingValue(text: 'new text')]);

      tester.testTextInput.log.clear();
      await tester.pumpWidget(build(textEditingController: TextEditingController(text: 'new new text')));

      updates = tester.testTextInput.log
        .where((MethodCall call) => call.method == 'TextInput.setEditingState')
        .map((MethodCall call) => TextEditingValue.fromJSON(call.arguments as Map<String, dynamic>))
        .toList(growable: false);

      expect(updates, const <TextEditingValue>[TextEditingValue(text: 'new new text')]);
    });
  });

  testWidgets('input imm channel calls are ordered correctly', (WidgetTester tester) async {
    const String testText = 'flutter is the best!';
    final TextEditingController controller = TextEditingController(text: testText);
    final EditableText et = EditableText(
      showSelectionHandles: true,
      maxLines: 2,
      controller: controller,
      focusNode: FocusNode(),
      cursorColor: Colors.red,
      backgroundCursorColor: Colors.blue,
      style: Typography.material2018().black.subtitle1!.copyWith(fontFamily: 'Roboto'),
      keyboardType: TextInputType.text,
    );

    await tester.pumpWidget(MaterialApp(
      home: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 100,
          child: et,
        ),
      ),
    ));

    await tester.showKeyboard(find.byType(EditableText));
    // TextInput.show should be after TextInput.setEditingState.
    // On Android setEditingState triggers an IME restart which may prevent
    // the keyboard from showing if the show keyboard request comes before the
    // restart.
    // See: https://github.com/flutter/flutter/issues/68571.
    final List<String> logOrder = <String>[
      'TextInput.setClient',
      'TextInput.setEditableSizeAndTransform',
      'TextInput.setMarkedTextRect',
      'TextInput.setStyle',
      'TextInput.setEditingState',
      'TextInput.show',
      'TextInput.requestAutofill',
      'TextInput.setEditingState',
      'TextInput.show',
      'TextInput.setCaretRect',
    ];
    expect(
      tester.testTextInput.log.map((MethodCall m) => m.method),
      logOrder,
    );
  });

  testWidgets(
    'keyboard is requested after setEditingState after switching to a new text field',
    (WidgetTester tester) async {
      // Regression test for https://github.com/flutter/flutter/issues/68571.
      final EditableText editableText1 = EditableText(
        showSelectionHandles: true,
        maxLines: 2,
        controller: TextEditingController(),
        focusNode: FocusNode(),
        cursorColor: Colors.red,
        backgroundCursorColor: Colors.blue,
        style: Typography.material2018().black.subtitle1!.copyWith(fontFamily: 'Roboto'),
        keyboardType: TextInputType.text,
      );

      final EditableText editableText2 = EditableText(
        showSelectionHandles: true,
        maxLines: 2,
        controller: TextEditingController(),
        focusNode: FocusNode(),
        cursorColor: Colors.red,
        backgroundCursorColor: Colors.blue,
        style: Typography.material2018().black.subtitle1!.copyWith(fontFamily: 'Roboto'),
        keyboardType: TextInputType.text,
      );

      await tester.pumpWidget(MaterialApp(
        home: Center(
          child: Column(
            children: <Widget>[editableText1, editableText2],
          ),
        ),
      ));

      await tester.tap(find.byWidget(editableText1));
      await tester.pumpAndSettle();

      tester.testTextInput.log.clear();
      await tester.tap(find.byWidget(editableText2));
      await tester.pumpAndSettle();

      // Send TextInput.show after TextInput.setEditingState. Otherwise
      // some Android keyboards ignore the "show keyboard" request, as the
      // Android text input plugin restarts the input method when setEditingState
      // is sent by the framework.
      final List<String> logOrder = <String>[
        'TextInput.clearClient',
        'TextInput.setClient',
        'TextInput.setEditableSizeAndTransform',
        'TextInput.setMarkedTextRect',
        'TextInput.setStyle',
        'TextInput.setEditingState',
        'TextInput.show',
        'TextInput.requestAutofill',
        'TextInput.setCaretRect',
      ];
      expect(
        tester.testTextInput.log.map((MethodCall m) => m.method),
        logOrder,
      );
  });

  testWidgets(
    'Autofill does not request focus',
    (WidgetTester tester) async {
      // Regression test for https://github.com/flutter/flutter/issues/91354 .
      final FocusNode focusNode1 = FocusNode();
      final EditableText editableText1 = EditableText(
        showSelectionHandles: true,
        maxLines: 2,
        controller: TextEditingController(),
        focusNode: focusNode1,
        cursorColor: Colors.red,
        backgroundCursorColor: Colors.blue,
        style: Typography.material2018().black.subtitle1!.copyWith(fontFamily: 'Roboto'),
        keyboardType: TextInputType.text,
      );

      final FocusNode focusNode2 = FocusNode();
      final EditableText editableText2 = EditableText(
        showSelectionHandles: true,
        maxLines: 2,
        controller: TextEditingController(),
        focusNode: focusNode2,
        cursorColor: Colors.red,
        backgroundCursorColor: Colors.blue,
        style: Typography.material2018().black.subtitle1!.copyWith(fontFamily: 'Roboto'),
        keyboardType: TextInputType.text,
      );

      await tester.pumpWidget(MaterialApp(
        home: Center(
          child: Column(
            children: <Widget>[editableText1, editableText2],
          ),
        ),
      ));

      // editableText1 has the focus.
      await tester.tap(find.byWidget(editableText1));
      await tester.pumpAndSettle();

      final EditableTextState state2 = tester.state<EditableTextState>(find.byWidget(editableText2));
      // Update editableText2 when it's not focused. It should not request focus.
      state2.updateEditingValue(
        const TextEditingValue(text: 'password', selection: TextSelection.collapsed(offset: 8)),
      );
      await tester.pumpAndSettle();

      expect(focusNode1.hasFocus, isTrue);
      expect(focusNode2.hasFocus, isFalse);
  });

  testWidgets('setEditingState is not called when text changes', (WidgetTester tester) async {
    // We shouldn't get a message here because this change is owned by the platform side.
    const String testText = 'flutter is the best!';
    final TextEditingController controller = TextEditingController(text: testText);
    final EditableText et = EditableText(
      showSelectionHandles: true,
      maxLines: 2,
      controller: controller,
      focusNode: FocusNode(),
      cursorColor: Colors.red,
      backgroundCursorColor: Colors.blue,
      style: Typography.material2018().black.subtitle1!.copyWith(fontFamily: 'Roboto'),
      keyboardType: TextInputType.text,
    );

    await tester.pumpWidget(MaterialApp(
      home: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 100,
          child: et,
        ),
      ),
    ));

    await tester.enterText(find.byType(EditableText), '...');

    final List<String> logOrder = <String>[
      'TextInput.setClient',
      'TextInput.setEditableSizeAndTransform',
      'TextInput.setMarkedTextRect',
      'TextInput.setStyle',
      'TextInput.setEditingState',
      'TextInput.show',
      'TextInput.requestAutofill',
      'TextInput.setEditingState',
      'TextInput.show',
      'TextInput.setCaretRect',
      'TextInput.show',
    ];
    expect(tester.testTextInput.log.length, logOrder.length);
    int index = 0;
    for (final MethodCall m in tester.testTextInput.log) {
      expect(m.method, logOrder[index]);
      index++;
    }
    expect(tester.testTextInput.editingState!['text'], 'flutter is the best!');
  });

  testWidgets('setEditingState is called when text changes on controller', (WidgetTester tester) async {
    // We should get a message here because this change is owned by the framework side.
    const String testText = 'flutter is the best!';
    final TextEditingController controller = TextEditingController(text: testText);
    final EditableText et = EditableText(
      showSelectionHandles: true,
      maxLines: 2,
      controller: controller,
      focusNode: FocusNode(),
      cursorColor: Colors.red,
      backgroundCursorColor: Colors.blue,
      style: Typography.material2018().black.subtitle1!.copyWith(fontFamily: 'Roboto'),
      keyboardType: TextInputType.text,
    );

    await tester.pumpWidget(MaterialApp(
      home: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 100,
          child: et,
        ),
      ),
    ));

    await tester.showKeyboard(find.byType(EditableText));
    controller.text += '...';
    await tester.idle();

    final List<String> logOrder = <String>[
      'TextInput.setClient',
      'TextInput.setEditableSizeAndTransform',
      'TextInput.setMarkedTextRect',
      'TextInput.setStyle',
      'TextInput.setEditingState',
      'TextInput.show',
      'TextInput.requestAutofill',
      'TextInput.setEditingState',
      'TextInput.show',
      'TextInput.setCaretRect',
      'TextInput.setEditingState',
    ];

    expect(
      tester.testTextInput.log.map((MethodCall m) => m.method),
      logOrder,
    );
    expect(tester.testTextInput.editingState!['text'], 'flutter is the best!...');
  });

  testWidgets('Synchronous test of local and remote editing values', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/65059
    final List<MethodCall> log = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.textInput, (MethodCall methodCall) async {
      log.add(methodCall);
      return null;
    });
    final TextInputFormatter formatter = TextInputFormatter.withFunction((TextEditingValue oldValue, TextEditingValue newValue) {
      if (newValue.text == 'I will be modified by the formatter.') {
        newValue = const TextEditingValue(text: 'Flutter is the best!');
      }
      return newValue;
    });
    final TextEditingController controller = TextEditingController();
    late StateSetter setState;

    final FocusNode focusNode = FocusNode(debugLabel: 'EditableText Focus Node');
    Widget builder() {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setter) {
          setState = setter;
          return MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(),
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Center(
                  child: Material(
                    child: EditableText(
                      controller: controller,
                      focusNode: focusNode,
                      style: textStyle,
                      cursorColor: Colors.red,
                      backgroundCursorColor: Colors.red,
                      keyboardType: TextInputType.multiline,
                      inputFormatters: <TextInputFormatter>[
                        formatter,
                      ],
                      onChanged: (String value) { },
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    await tester.pumpWidget(builder());
    await tester.tap(find.byType(EditableText));
    await tester.showKeyboard(find.byType(EditableText));
    await tester.pump();

    log.clear();

    final EditableTextState state = tester.firstState(find.byType(EditableText));
    // setEditingState is not called when only the remote changes
    state.updateEditingValue(TextEditingValue(
      text: 'a',
      selection: controller.selection,
    ));

    expect(log.length, 0);

    // setEditingState is called when remote value modified by the formatter.
    state.updateEditingValue(TextEditingValue(
      text: 'I will be modified by the formatter.',
      selection: controller.selection,
    ));
    expect(log.length, 1);
    MethodCall methodCall = log[0];
    expect(
      methodCall,
      isMethodCall('TextInput.setEditingState', arguments: <String, dynamic>{
        'text': 'Flutter is the best!',
        'selectionBase': -1,
        'selectionExtent': -1,
        'selectionAffinity': 'TextAffinity.downstream',
        'selectionIsDirectional': false,
        'composingBase': -1,
        'composingExtent': -1,
      }),
    );

    log.clear();

    // setEditingState is called when the [controller.value] is modified by local.
    setState(() {
      controller.text = 'I love flutter!';
    });
    expect(log.length, 1);
    methodCall = log[0];
    expect(
      methodCall,
      isMethodCall('TextInput.setEditingState', arguments: <String, dynamic>{
        'text': 'I love flutter!',
        'selectionBase': -1,
        'selectionExtent': -1,
        'selectionAffinity': 'TextAffinity.downstream',
        'selectionIsDirectional': false,
        'composingBase': -1,
        'composingExtent': -1,
      }),
    );

    log.clear();

    // Currently `_receivedRemoteTextEditingValue` equals 'I will be modified by the formatter.',
    // setEditingState will be called when set the [controller.value] to `_receivedRemoteTextEditingValue` by local.
    setState(() {
      controller.text = 'I will be modified by the formatter.';
    });
    expect(log.length, 1);
    methodCall = log[0];
    expect(
      methodCall,
      isMethodCall('TextInput.setEditingState', arguments: <String, dynamic>{
        'text': 'I will be modified by the formatter.',
        'selectionBase': -1,
        'selectionExtent': -1,
        'selectionAffinity': 'TextAffinity.downstream',
        'selectionIsDirectional': false,
        'composingBase': -1,
        'composingExtent': -1,
      }),
    );
  });

  testWidgets('Send text input state to engine when the input formatter rejects user input', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/67828
    final List<MethodCall> log = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.textInput, (MethodCall methodCall) async {
      log.add(methodCall);
      return null;
    });
    final TextInputFormatter formatter = TextInputFormatter.withFunction((TextEditingValue oldValue, TextEditingValue newValue) {
      return const TextEditingValue(text: 'Flutter is the best!');
    });
    final TextEditingController controller = TextEditingController();

    final FocusNode focusNode = FocusNode(debugLabel: 'EditableText Focus Node');
    Widget builder() {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setter) {
          return MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(),
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Center(
                  child: Material(
                    child: EditableText(
                      controller: controller,
                      focusNode: focusNode,
                      style: textStyle,
                      cursorColor: Colors.red,
                      backgroundCursorColor: Colors.red,
                      keyboardType: TextInputType.multiline,
                      inputFormatters: <TextInputFormatter>[
                        formatter,
                      ],
                      onChanged: (String value) { },
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    await tester.pumpWidget(builder());
    await tester.tap(find.byType(EditableText));
    await tester.showKeyboard(find.byType(EditableText));
    await tester.pump();

    log.clear();

    final EditableTextState state = tester.firstState(find.byType(EditableText));

    // setEditingState is called when remote value modified by the formatter.
    state.updateEditingValue(TextEditingValue(
      text: 'I will be modified by the formatter.',
      selection: controller.selection,
    ));
    expect(log.length, 1);
    expect(log, contains(matchesMethodCall(
      'TextInput.setEditingState',
      args: allOf(
        containsPair('text', 'Flutter is the best!'),
      ),
    )));

    log.clear();

    state.updateEditingValue(const TextEditingValue(
      text: 'I will be modified by the formatter.',
    ));
    expect(log.length, 1);
    expect(log, contains(matchesMethodCall(
      'TextInput.setEditingState',
      args: allOf(
        containsPair('text', 'Flutter is the best!'),
      ),
    )));
  });

  testWidgets('Repeatedly receiving [TextEditingValue] will not trigger a keyboard request', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/66036
    final List<MethodCall> log = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.textInput, (MethodCall methodCall) async {
      log.add(methodCall);
      return null;
    });
    final TextEditingController controller = TextEditingController();

    final FocusNode focusNode = FocusNode(debugLabel: 'EditableText Focus Node');
    Widget builder() {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setter) {
          return MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(),
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Center(
                  child: Material(
                    child: EditableText(
                      controller: controller,
                      focusNode: focusNode,
                      style: textStyle,
                      cursorColor: Colors.red,
                      backgroundCursorColor: Colors.red,
                      keyboardType: TextInputType.multiline,
                      onChanged: (String value) { },
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    await tester.pumpWidget(builder());
    await tester.tap(find.byType(EditableText));
    await tester.pump();

    // The keyboard is shown after tap the EditableText.
    expect(focusNode.hasFocus, true);

    log.clear();

    final EditableTextState state = tester.firstState(find.byType(EditableText));

    state.updateEditingValue(TextEditingValue(
      text: 'a',
      selection: controller.selection,
    ));
    await tester.pump();

    // Nothing called when only the remote changes.
    expect(log.length, 0);

    // Hide the keyboard.
    focusNode.unfocus();
    await tester.pump();

    expect(log.length, 2);
    MethodCall methodCall = log[0];
    // Close the InputConnection.
    expect(methodCall, isMethodCall('TextInput.clearClient', arguments: null));
    methodCall = log[1];
    expect(methodCall, isMethodCall('TextInput.hide', arguments: null));
    // The keyboard loses focus.
    expect(focusNode.hasFocus, false);

    log.clear();

    // Send repeat value from the engine.
    state.updateEditingValue(TextEditingValue(
      text: 'a',
      selection: controller.selection,
    ));
    await tester.pump();

    // Nothing called when only the remote changes.
    expect(log.length, 0);
    // The keyboard is not be requested after a repeat value from the engine.
    expect(focusNode.hasFocus, false);
  });

  group('TextEditingController', () {
    testWidgets('TextEditingController.text set to empty string clears field', (WidgetTester tester) async {
      final TextEditingController controller = TextEditingController();
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Center(
                child: Material(
                  child: EditableText(
                    controller: controller,
                    focusNode: focusNode,
                    style: textStyle,
                    cursorColor: Colors.red,
                    backgroundCursorColor: Colors.red,
                    keyboardType: TextInputType.multiline,
                    onChanged: (String value) { },
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      controller.text = '...';
      await tester.pump();
      expect(find.text('...'), findsOneWidget);

      controller.text = '';
      await tester.pump();
      expect(find.text('...'), findsNothing);
    });

    testWidgets('TextEditingController.clear() behavior test', (WidgetTester tester) async {
      // Regression test for https://github.com/flutter/flutter/issues/66316
      final List<MethodCall> log = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.textInput, (MethodCall methodCall) async {
        log.add(methodCall);
        return null;
      });
      final TextEditingController controller = TextEditingController();

      final FocusNode focusNode = FocusNode(debugLabel: 'EditableText Focus Node');
      Widget builder() {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setter) {
            return MaterialApp(
              home: MediaQuery(
                data: const MediaQueryData(),
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Center(
                    child: Material(
                      child: EditableText(
                        controller: controller,
                        focusNode: focusNode,
                        style: textStyle,
                        cursorColor: Colors.red,
                        backgroundCursorColor: Colors.red,
                        keyboardType: TextInputType.multiline,
                        onChanged: (String value) { },
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      }

      await tester.pumpWidget(builder());
      await tester.tap(find.byType(EditableText));
      await tester.pump();

      // The keyboard is shown after tap the EditableText.
      expect(focusNode.hasFocus, true);

      log.clear();

      final EditableTextState state = tester.firstState(find.byType(EditableText));

      state.updateEditingValue(TextEditingValue(
        text: 'a',
        selection: controller.selection,
      ));
      await tester.pump();

      // Nothing called when only the remote changes.
      expect(log, isEmpty);

      controller.clear();

      expect(log.length, 1);
      expect(
        log[0],
        isMethodCall('TextInput.setEditingState', arguments: <String, dynamic>{
          'text': '',
          'selectionBase': 0,
          'selectionExtent': 0,
          'selectionAffinity': 'TextAffinity.downstream',
          'selectionIsDirectional': false,
          'composingBase': -1,
          'composingExtent': -1,
        }),
      );
    });

    testWidgets('TextEditingController.buildTextSpan receives build context', (WidgetTester tester) async {
      final _AccentColorTextEditingController controller = _AccentColorTextEditingController('a');
      const Color color = Color.fromARGB(255, 1, 2, 3);
      final ThemeData lightTheme = ThemeData.light();
      await tester.pumpWidget(MaterialApp(
        theme: lightTheme.copyWith(
          colorScheme: lightTheme.colorScheme.copyWith(secondary: color),
        ),
        home: EditableText(
          controller: controller,
          focusNode: FocusNode(),
          style: Typography.material2018().black.subtitle1!,
          cursorColor: Colors.blue,
          backgroundCursorColor: Colors.grey,
        ),
      ));

      final RenderEditable renderEditable = findRenderEditable(tester);
      final TextSpan textSpan = renderEditable.text! as TextSpan;
      expect(textSpan.style!.color, color);
    });

    testWidgets('controller listener changes value', (WidgetTester tester) async {
      const double maxValue = 5.5555;
      final TextEditingController controller = TextEditingController();

      controller.addListener(() {
        final double value = double.tryParse(controller.text.trim()) ?? .0;
        if (value > maxValue) {
          controller.text = maxValue.toString();
          controller.selection = TextSelection.fromPosition(
              TextPosition(offset: maxValue.toString().length));
        }
      });
      await tester.pumpWidget(MaterialApp(
        home: EditableText(
          controller: controller,
          focusNode: focusNode,
          style: textStyle,
          cursorColor: Colors.blue,
          backgroundCursorColor: Colors.grey,
        ),
      ));

      final EditableTextState state =
        tester.state<EditableTextState>(find.byType(EditableText));

      state.updateEditingValue(const TextEditingValue(text: '1', selection: TextSelection.collapsed(offset: 1)));
      await tester.pump();
      state.updateEditingValue(const TextEditingValue(text: '12', selection: TextSelection.collapsed(offset: 2)));
      await tester.pump();

      expect(controller.text, '5.5555');
      expect(controller.selection.baseOffset, 6);
      expect(controller.selection.extentOffset, 6);
    });
  });

  testWidgets('autofocus:true on first frame does not throw', (WidgetTester tester) async {
    final TextEditingController controller = TextEditingController(text: testText);
    controller.selection = const TextSelection(
      baseOffset: 0,
      extentOffset: 0,
      affinity: TextAffinity.upstream,
    );

    await tester.pumpWidget(MaterialApp(
      home: EditableText(
        maxLines: 10,
        controller: controller,
        showSelectionHandles: true,
        autofocus: true,
        focusNode: FocusNode(),
        style: Typography.material2018().black.subtitle1!,
        cursorColor: Colors.blue,
        backgroundCursorColor: Colors.grey,
        selectionControls: materialTextSelectionControls,
        keyboardType: TextInputType.text,
        textAlign: TextAlign.right,
      ),
    ));


    await tester.pumpAndSettle(); // Wait for autofocus to take effect.

    final dynamic exception = tester.takeException();
    expect(exception, isNull);
  });

  testWidgets('updateEditingValue filters multiple calls from formatter', (WidgetTester tester) async {
    final MockTextFormatter formatter = MockTextFormatter();
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(),
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
              inputFormatters: <TextInputFormatter>[formatter],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(EditableText));
    await tester.showKeyboard(find.byType(EditableText));
    controller.text = '';
    await tester.idle();

    final EditableTextState state =
        tester.state<EditableTextState>(find.byType(EditableText));
    expect(tester.testTextInput.editingState!['text'], equals(''));
    expect(state.wantKeepAlive, true);

    state.updateEditingValue(TextEditingValue.empty);
    state.updateEditingValue(const TextEditingValue(text: 'a'));
    state.updateEditingValue(const TextEditingValue(text: 'aa'));
    state.updateEditingValue(const TextEditingValue(text: 'aaa'));
    state.updateEditingValue(const TextEditingValue(text: 'aa'));
    state.updateEditingValue(const TextEditingValue(text: 'aaa'));
    state.updateEditingValue(const TextEditingValue(text: 'aaaa'));
    state.updateEditingValue(const TextEditingValue(text: 'aa'));
    state.updateEditingValue(const TextEditingValue(text: 'aaaaaaa'));
    state.updateEditingValue(const TextEditingValue(text: 'aa'));
    state.updateEditingValue(const TextEditingValue(text: 'aaaaaaaaa'));
    state.updateEditingValue(const TextEditingValue(text: 'aaaaaaaaa')); // Skipped

    const List<String> referenceLog = <String>[
      '[1]: , a',
      '[1]: normal aa',
      '[2]: a, aa',
      '[2]: normal aaaa',
      '[3]: aa, aaa',
      '[3]: normal aaaaaa',
      '[4]: aaa, aa',
      '[4]: deleting aa',
      '[5]: aa, aaa',
      '[5]: normal aaaaaaaaaa',
      '[6]: aaa, aaaa',
      '[6]: normal aaaaaaaaaaaa',
      '[7]: aaaa, aa',
      '[7]: deleting aaaaa',
      '[8]: aa, aaaaaaa',
      '[8]: normal aaaaaaaaaaaaaaaa',
      '[9]: aaaaaaa, aa',
      '[9]: deleting aaaaaaa',
      '[10]: aa, aaaaaaaaa',
      '[10]: normal aaaaaaaaaaaaaaaaaaaa',
    ];

    expect(formatter.log, referenceLog);
  });

  testWidgets('formatter logic handles repeat filtering', (WidgetTester tester) async {
    final MockTextFormatter formatter = MockTextFormatter();
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(),
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
              inputFormatters: <TextInputFormatter>[formatter],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(EditableText));
    await tester.showKeyboard(find.byType(EditableText));
    controller.text = '';
    await tester.idle();

    final EditableTextState state =
        tester.state<EditableTextState>(find.byType(EditableText));
    expect(tester.testTextInput.editingState!['text'], equals(''));
    expect(state.wantKeepAlive, true);

    // We no longer perform full repeat filtering in framework, it is now left
    // to the engine to prevent repeat calls from being sent in the first place.
    // Engine preventing repeats is far more reliable and avoids many of the ambiguous
    // filtering we performed before.
    expect(formatter.formatCallCount, 0);
    state.updateEditingValue(const TextEditingValue(text: '01'));
    expect(formatter.formatCallCount, 1);
    state.updateEditingValue(const TextEditingValue(text: '012'));
    expect(formatter.formatCallCount, 2);
    state.updateEditingValue(const TextEditingValue(text: '0123')); // Text change causes reformat
    expect(formatter.formatCallCount, 3);
    state.updateEditingValue(const TextEditingValue(text: '0123')); // No text change, does not format
    expect(formatter.formatCallCount, 3);
    state.updateEditingValue(const TextEditingValue(text: '0123')); // No text change, does not format
    expect(formatter.formatCallCount, 3);
    state.updateEditingValue(const TextEditingValue(text: '0123', selection: TextSelection.collapsed(offset: 2))); // Selection change does not reformat
    expect(formatter.formatCallCount, 3);
    state.updateEditingValue(const TextEditingValue(text: '0123', selection: TextSelection.collapsed(offset: 2))); // No text change, does not format
    expect(formatter.formatCallCount, 3);
    state.updateEditingValue(const TextEditingValue(text: '0123', selection: TextSelection.collapsed(offset: 2))); // No text change, does not format
    expect(formatter.formatCallCount, 3);

    // Composing changes should not trigger reformat, as it could cause infinite loops on some IMEs.
    state.updateEditingValue(const TextEditingValue(text: '0123', selection: TextSelection.collapsed(offset: 2), composing: TextRange(start: 1, end: 2)));
    expect(formatter.formatCallCount, 3);
    expect(formatter.lastOldValue.composing, TextRange.empty);
    expect(formatter.lastNewValue.composing, TextRange.empty); // The new composing was registered in formatter.
    // Clearing composing region should trigger reformat.
    state.updateEditingValue(const TextEditingValue(text: '01234', selection: TextSelection.collapsed(offset: 2))); // Formats, with oldValue containing composing region.
    expect(formatter.formatCallCount, 4);
    expect(formatter.lastOldValue.composing, const TextRange(start: 1, end: 2));
    expect(formatter.lastNewValue.composing, TextRange.empty);

    const List<String> referenceLog = <String>[
      '[1]: , 01',
      '[1]: normal aa',
      '[2]: 01, 012',
      '[2]: normal aaaa',
      '[3]: 012, 0123',
      '[3]: normal aaaaaa',
      '[4]: 0123, 01234',
      '[4]: normal aaaaaaaa',
    ];

    expect(formatter.log, referenceLog);
  });

  // Regression test for https://github.com/flutter/flutter/issues/53612
  testWidgets('formatter logic handles initial repeat edge case', (WidgetTester tester) async {
    final MockTextFormatter formatter = MockTextFormatter();
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(),
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
              inputFormatters: <TextInputFormatter>[formatter],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(EditableText));
    await tester.showKeyboard(find.byType(EditableText));
    controller.text = 'test';
    await tester.idle();

    final EditableTextState state =
        tester.state<EditableTextState>(find.byType(EditableText));
    expect(tester.testTextInput.editingState!['text'], equals('test'));
    expect(state.wantKeepAlive, true);

    expect(formatter.formatCallCount, 0);
    state.updateEditingValue(const TextEditingValue(text: 'test'));
    state.updateEditingValue(const TextEditingValue(text: 'test', composing: TextRange(start: 1, end: 2)));
    state.updateEditingValue(const TextEditingValue(text: '0')); // pass to formatter once to check the values.
    expect(formatter.lastOldValue.composing, const TextRange(start: 1, end: 2));
    expect(formatter.lastOldValue.text, 'test');
  });

  testWidgets('EditableText changes mouse cursor when hovered', (WidgetTester tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: FocusScope(
            node: focusScopeNode,
            child: MouseRegion(
              cursor: SystemMouseCursors.forbidden,
              child: EditableText(
                controller: controller,
                backgroundCursorColor: Colors.grey,
                focusNode: focusNode,
                style: textStyle,
                cursorColor: cursorColor,
                mouseCursor: SystemMouseCursors.click,
              ),
            ),
          ),
        ),
      ),
    );

    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse, pointer: 1);
    await gesture.addPointer(location: tester.getCenter(find.byType(EditableText)));

    await tester.pump();

    expect(RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1), SystemMouseCursors.click);

    // Test default cursor
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: FocusScope(
            node: focusScopeNode,
            child: MouseRegion(
              cursor: SystemMouseCursors.forbidden,
              child: EditableText(
                controller: controller,
                backgroundCursorColor: Colors.grey,
                focusNode: focusNode,
                style: textStyle,
                cursorColor: cursorColor,
              ),
            ),
          ),
        ),
      ),
    );

    expect(RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1), SystemMouseCursors.text);
  });

  testWidgets('Can access characters on editing string', (WidgetTester tester) async {
    late int charactersLength;
    final Widget widget = MaterialApp(
      home: EditableText(
        backgroundCursorColor: Colors.grey,
        controller: TextEditingController(),
        focusNode: FocusNode(),
        style: Typography.material2018().black.subtitle1!,
        cursorColor: Colors.blue,
        selectionControls: materialTextSelectionControls,
        keyboardType: TextInputType.text,
        onChanged: (String value) {
          charactersLength = value.characters.length;
        },
      ),
    );
    await tester.pumpWidget(widget);

    // Enter an extended grapheme cluster whose string length is different than
    // its characters length.
    await tester.enterText(find.byType(EditableText), '👨‍👩‍👦');
    await tester.pump();

    expect(charactersLength, 1);
  });

  testWidgets('EditableText can set and update clipBehavior', (WidgetTester tester) async {
    await tester.pumpWidget(MediaQuery(
      data: const MediaQueryData(),
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
    ));
    final RenderEditable renderObject = tester.allRenderObjects.whereType<RenderEditable>().first;
    expect(renderObject.clipBehavior, equals(Clip.hardEdge));

    await tester.pumpWidget(MediaQuery(
      data: const MediaQueryData(),
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
            clipBehavior: Clip.antiAlias,
          ),
        ),
      ),
    ));
    expect(renderObject.clipBehavior, equals(Clip.antiAlias));
  });

  testWidgets('EditableText inherits DefaultTextHeightBehavior', (WidgetTester tester) async {
    const TextHeightBehavior customTextHeightBehavior = TextHeightBehavior(
      applyHeightToFirstAscent: false,
    );
    await tester.pumpWidget(MediaQuery(
      data: const MediaQueryData(),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: FocusScope(
          node: focusScopeNode,
          autofocus: true,
          child: DefaultTextHeightBehavior(
            textHeightBehavior: customTextHeightBehavior,
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
    ));
    final RenderEditable renderObject = tester.allRenderObjects.whereType<RenderEditable>().first;
    expect(renderObject.textHeightBehavior, equals(customTextHeightBehavior));
  });

  testWidgets('EditableText defaultTextHeightBehavior is used over inherited widget', (WidgetTester tester) async {
    const TextHeightBehavior inheritedTextHeightBehavior = TextHeightBehavior(
      applyHeightToFirstAscent: false,
    );
    const TextHeightBehavior customTextHeightBehavior = TextHeightBehavior(
      applyHeightToLastDescent: false,
      applyHeightToFirstAscent: false,
    );
    await tester.pumpWidget(MediaQuery(
      data: const MediaQueryData(),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: FocusScope(
          node: focusScopeNode,
          autofocus: true,
          child: DefaultTextHeightBehavior(
            textHeightBehavior: inheritedTextHeightBehavior,
            child: EditableText(
              backgroundCursorColor: Colors.grey,
              controller: controller,
              focusNode: focusNode,
              style: textStyle,
              cursorColor: cursorColor,
              textHeightBehavior: customTextHeightBehavior,
            ),
          ),
        ),
      ),
    ));
    final RenderEditable renderObject = tester.allRenderObjects.whereType<RenderEditable>().first;
    expect(renderObject.textHeightBehavior, isNot(equals(inheritedTextHeightBehavior)));
    expect(renderObject.textHeightBehavior, equals(customTextHeightBehavior));
  });

  test('Asserts if composing text is not valid', () async {
    void expectToAssert(TextEditingValue value, bool shouldAssert) {
      dynamic initException;
      dynamic updateException;
      controller = TextEditingController();
      try {
        controller = TextEditingController.fromValue(value);
      } catch (e) {
        initException = e;
      }

      controller = TextEditingController();
      try {
        controller.value = value;
      } catch (e) {
        updateException = e;
      }

      expect(initException?.toString(), shouldAssert ? contains('composing range'): isNull);
      expect(updateException?.toString(), shouldAssert ? contains('composing range'): isNull);
    }

    expectToAssert(TextEditingValue.empty, false);
    expectToAssert(const TextEditingValue(text: 'test', composing: TextRange(start: 1, end: 0)), true);
    expectToAssert(const TextEditingValue(text: 'test', composing: TextRange(start: 1, end: 9)), true);
    expectToAssert(const TextEditingValue(text: 'test', composing: TextRange(start: -1, end: 9)), false);
  });

  testWidgets('Preserves composing range if cursor moves within that range', (WidgetTester tester) async {
    final Widget widget = MaterialApp(
      home: EditableText(
        backgroundCursorColor: Colors.grey,
        controller: controller,
        focusNode: focusNode,
        style: textStyle,
        cursorColor: cursorColor,
        selectionControls: materialTextSelectionControls,
      ),
    );
    await tester.pumpWidget(widget);

    final EditableTextState state = tester.state<EditableTextState>(find.byType(EditableText));
    state.updateEditingValue(const TextEditingValue(
      text: 'foo composing bar',
      composing: TextRange(start: 4, end: 12),
    ));
    controller.selection = const TextSelection.collapsed(offset: 5);
    expect(state.currentTextEditingValue.composing, const TextRange(start: 4, end: 12));
  });

  testWidgets('Clears composing range if cursor moves outside that range', (WidgetTester tester) async {
    final Widget widget = MaterialApp(
      home: EditableText(
        backgroundCursorColor: Colors.grey,
        controller: controller,
        focusNode: focusNode,
        style: textStyle,
        cursorColor: cursorColor,
        selectionControls: materialTextSelectionControls,
      ),
    );
    await tester.pumpWidget(widget);

    // Positioning cursor before the composing range should clear the composing range.
    final EditableTextState state = tester.state<EditableTextState>(find.byType(EditableText));
    state.updateEditingValue(const TextEditingValue(
      text: 'foo composing bar',
      selection: TextSelection.collapsed(offset: 4),
      composing: TextRange(start: 4, end: 12),
    ));
    controller.selection = const TextSelection.collapsed(offset: 2);
    expect(state.currentTextEditingValue.composing, TextRange.empty);

    // Reset the composing range.
    state.updateEditingValue(const TextEditingValue(
      text: 'foo composing bar',
      selection: TextSelection.collapsed(offset: 4),
      composing: TextRange(start: 4, end: 12),
    ));
    expect(state.currentTextEditingValue.composing, const TextRange(start: 4, end: 12));

    // Positioning cursor after the composing range should clear the composing range.
    state.updateEditingValue(const TextEditingValue(
      text: 'foo composing bar',
      selection: TextSelection.collapsed(offset: 4),
      composing: TextRange(start: 4, end: 12),
    ));
    controller.selection = const TextSelection.collapsed(offset: 14);
    expect(state.currentTextEditingValue.composing, TextRange.empty);
  });

  testWidgets('Clears composing range if cursor moves outside that range - case two', (WidgetTester tester) async {
    final Widget widget = MaterialApp(
      home: EditableText(
        backgroundCursorColor: Colors.grey,
        controller: controller,
        focusNode: focusNode,
        style: textStyle,
        cursorColor: cursorColor,
        selectionControls: materialTextSelectionControls,
      ),
    );
    await tester.pumpWidget(widget);

    // Setting a selection before the composing range clears the composing range.
    final EditableTextState state = tester.state<EditableTextState>(find.byType(EditableText));
    state.updateEditingValue(const TextEditingValue(
      text: 'foo composing bar',
      selection: TextSelection.collapsed(offset: 4),
      composing: TextRange(start: 4, end: 12),
    ));
    controller.selection = const TextSelection(baseOffset: 1, extentOffset: 2);
    expect(state.currentTextEditingValue.composing, TextRange.empty);

    // Reset the composing range.
    state.updateEditingValue(const TextEditingValue(
      text: 'foo composing bar',
      selection: TextSelection.collapsed(offset: 4),
      composing: TextRange(start: 4, end: 12),
    ));
    expect(state.currentTextEditingValue.composing, const TextRange(start: 4, end: 12));

    // Setting a selection within the composing range clears the composing range.
    state.updateEditingValue(const TextEditingValue(
      text: 'foo composing bar',
      selection: TextSelection.collapsed(offset: 4),
      composing: TextRange(start: 4, end: 12),
    ));
    controller.selection = const TextSelection(baseOffset: 5, extentOffset: 7);
    expect(state.currentTextEditingValue.composing, TextRange.empty);

    // Reset the composing range.
    state.updateEditingValue(const TextEditingValue(
      text: 'foo composing bar',
      selection: TextSelection.collapsed(offset: 4),
      composing: TextRange(start: 4, end: 12),
    ));
    expect(state.currentTextEditingValue.composing, const TextRange(start: 4, end: 12));

    // Setting a selection after the composing range clears the composing range.
    state.updateEditingValue(const TextEditingValue(
      text: 'foo composing bar',
      selection: TextSelection.collapsed(offset: 4),
      composing: TextRange(start: 4, end: 12),
    ));
    controller.selection = const TextSelection(baseOffset: 13, extentOffset: 15);
    expect(state.currentTextEditingValue.composing, TextRange.empty);
  });

  group('Length formatter', () {
    const int maxLength = 5;

    Future<void> setupWidget(
      WidgetTester tester,
      LengthLimitingTextInputFormatter formatter,
    ) async {
      final Widget widget = MaterialApp(
        home: EditableText(
          backgroundCursorColor: Colors.grey,
          controller: controller,
          focusNode: focusNode,
          inputFormatters: <TextInputFormatter>[formatter],
          style: textStyle,
          cursorColor: cursorColor,
          selectionControls: materialTextSelectionControls,
        ),
      );

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();
    }

    // Regression test for https://github.com/flutter/flutter/issues/65374.
    testWidgets('will not cause crash while the TextEditingValue is composing', (WidgetTester tester) async {
      await setupWidget(
        tester,
        LengthLimitingTextInputFormatter(
          maxLength,
          maxLengthEnforcement: MaxLengthEnforcement.truncateAfterCompositionEnds,
        ),
      );

      final EditableTextState state = tester.state<EditableTextState>(find.byType(EditableText));
      state.updateEditingValue(const TextEditingValue(text: 'abcde'));
      expect(state.currentTextEditingValue.composing, TextRange.empty);
      state.updateEditingValue(const TextEditingValue(text: 'abcde', composing: TextRange(start: 2, end: 4)));
      expect(state.currentTextEditingValue.composing, const TextRange(start: 2, end: 4));

      // Formatter will not update format while the editing value is composing.
      state.updateEditingValue(const TextEditingValue(text: 'abcdef', composing: TextRange(start: 2, end: 5)));
      expect(state.currentTextEditingValue.text, 'abcdef');
      expect(state.currentTextEditingValue.composing, const TextRange(start: 2, end: 5));

      // After composing ends, formatter will update.
      state.updateEditingValue(const TextEditingValue(text: 'abcdef'));
      expect(state.currentTextEditingValue.text, 'abcde');
      expect(state.currentTextEditingValue.composing, TextRange.empty);
    });

    testWidgets('handles composing text correctly, continued', (WidgetTester tester) async {
      await setupWidget(
        tester,
        LengthLimitingTextInputFormatter(
          maxLength,
          maxLengthEnforcement: MaxLengthEnforcement.truncateAfterCompositionEnds,
        ),
      );

      final EditableTextState state = tester.state<EditableTextState>(find.byType(EditableText));

      // Initially we're at maxLength with no composing text.
      controller.text = 'abcde' ;
      assert(state.currentTextEditingValue == const TextEditingValue(text: 'abcde'));

      // Should be able to change the editing value if the new value is still shorter
      // than maxLength.
      state.updateEditingValue(const TextEditingValue(text: 'abcde', composing: TextRange(start: 2, end: 4)));
      expect(state.currentTextEditingValue.composing, const TextRange(start: 2, end: 4));

      // Reset.
      controller.text = 'abcde' ;
      assert(state.currentTextEditingValue == const TextEditingValue(text: 'abcde'));

      // The text should not change when trying to insert when the text is already
      // at maxLength.
      state.updateEditingValue(const TextEditingValue(text: 'abcdef', composing: TextRange(start: 5, end: 6)));
      expect(state.currentTextEditingValue.text, 'abcde');
      expect(state.currentTextEditingValue.composing, TextRange.empty);
    });

    // Regression test for https://github.com/flutter/flutter/issues/68086.
    testWidgets('enforced composing truncated', (WidgetTester tester) async {
      await setupWidget(
        tester,
        LengthLimitingTextInputFormatter(
          maxLength,
          maxLengthEnforcement: MaxLengthEnforcement.enforced,
        ),
      );

      final EditableTextState state = tester.state<EditableTextState>(find.byType(EditableText));

      // Initially we're at maxLength with no composing text.
      state.updateEditingValue(const TextEditingValue(text: 'abcde'));
      expect(state.currentTextEditingValue.composing, TextRange.empty);

      // When it's not longer than `maxLength`, it can still start composing.
      state.updateEditingValue(const TextEditingValue(text: 'abcde', composing: TextRange(start: 3, end: 5)));
      expect(state.currentTextEditingValue.composing, const TextRange(start: 3, end: 5));

      // `newValue` will be truncated if `composingMaxLengthEnforced`.
      state.updateEditingValue(const TextEditingValue(text: 'abcdef', composing: TextRange(start: 3, end: 6)));
      expect(state.currentTextEditingValue.text, 'abcde');
      expect(state.currentTextEditingValue.composing, const TextRange(start: 3, end: 5));

      // Reset the value.
      state.updateEditingValue(const TextEditingValue(text: 'abcde'));
      expect(state.currentTextEditingValue.composing, TextRange.empty);

      // Change the value in order to take effects on web test.
      state.updateEditingValue(const TextEditingValue(text: '你好啊朋友'));
      expect(state.currentTextEditingValue.composing, TextRange.empty);

      // Start composing with a longer value, it should be the same state.
      state.updateEditingValue(const TextEditingValue(text: '你好啊朋友们', composing: TextRange(start: 3, end: 6)));
      expect(state.currentTextEditingValue.composing, TextRange.empty);
    });

    // Regression test for https://github.com/flutter/flutter/issues/68086.
    testWidgets('default truncate behaviors with different platforms', (WidgetTester tester) async {
      await setupWidget(tester, LengthLimitingTextInputFormatter(maxLength));

      final EditableTextState state = tester.state<EditableTextState>(find.byType(EditableText));

      // Initially we're at maxLength with no composing text.
      state.updateEditingValue(const TextEditingValue(text: '你好啊朋友'));
      expect(state.currentTextEditingValue.composing, TextRange.empty);

      // When it's not longer than `maxLength`, it can still start composing.
      state.updateEditingValue(const TextEditingValue(text: '你好啊朋友', composing: TextRange(start: 3, end: 5)));
      expect(state.currentTextEditingValue.composing, const TextRange(start: 3, end: 5));

      state.updateEditingValue(const TextEditingValue(text: '你好啊朋友们', composing: TextRange(start: 3, end: 6)));
      if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.fuchsia
      ) {
        // `newValue` will not be truncated on couple platforms.
        expect(state.currentTextEditingValue.text, '你好啊朋友们');
        expect(state.currentTextEditingValue.composing, const TextRange(start: 3, end: 6));
      } else {
        // `newValue` on other platforms will be truncated.
        expect(state.currentTextEditingValue.text, '你好啊朋友');
        expect(state.currentTextEditingValue.composing, const TextRange(start: 3, end: 5));
      }

      // Reset the value.
      state.updateEditingValue(const TextEditingValue(text: '你好啊朋友'));
      expect(state.currentTextEditingValue.composing, TextRange.empty);

      // Start composing with a longer value, it should be the same state.
      state.updateEditingValue(const TextEditingValue(text: '你好啊朋友们', composing: TextRange(start: 3, end: 6)));
      expect(state.currentTextEditingValue.text, '你好啊朋友');
      expect(state.currentTextEditingValue.composing, TextRange.empty);
    });

    // Regression test for https://github.com/flutter/flutter/issues/68086.
    testWidgets("composing range removed if it's overflowed the truncated value's length", (WidgetTester tester) async {
      await setupWidget(
        tester,
        LengthLimitingTextInputFormatter(
          maxLength,
          maxLengthEnforcement: MaxLengthEnforcement.enforced,
        ),
      );

      final EditableTextState state = tester.state<EditableTextState>(find.byType(EditableText));

      // Initially we're not at maxLength with no composing text.
      state.updateEditingValue(const TextEditingValue(text: 'abc'));
      expect(state.currentTextEditingValue.composing, TextRange.empty);

      // Start composing.
      state.updateEditingValue(const TextEditingValue(text: 'abcde', composing: TextRange(start: 3, end: 5)));
      expect(state.currentTextEditingValue.composing, const TextRange(start: 3, end: 5));

      // Reset the value.
      state.updateEditingValue(const TextEditingValue(text: 'abc'));
      expect(state.currentTextEditingValue.composing, TextRange.empty);

      // Start composing with a range already overflowed the truncated length.
      state.updateEditingValue(const TextEditingValue(text: 'abcdefgh', composing: TextRange(start: 5, end: 7)));
      expect(state.currentTextEditingValue.composing, TextRange.empty);
    });

    // Regression test for https://github.com/flutter/flutter/issues/68086.
    testWidgets('composing range removed with different platforms', (WidgetTester tester) async {
      await setupWidget(tester, LengthLimitingTextInputFormatter(maxLength));

      final EditableTextState state = tester.state<EditableTextState>(find.byType(EditableText));

      // Initially we're not at maxLength with no composing text.
      state.updateEditingValue(const TextEditingValue(text: 'abc'));
      expect(state.currentTextEditingValue.composing, TextRange.empty);

      // Start composing.
      state.updateEditingValue(const TextEditingValue(text: 'abcde', composing: TextRange(start: 3, end: 5)));
      expect(state.currentTextEditingValue.composing, const TextRange(start: 3, end: 5));

      // Reset the value.
      state.updateEditingValue(const TextEditingValue(text: 'abc'));
      expect(state.currentTextEditingValue.composing, TextRange.empty);

      // Start composing with a range already overflowed the truncated length.
      state.updateEditingValue(const TextEditingValue(text: 'abcdefgh', composing: TextRange(start: 5, end: 7)));
      if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.fuchsia
      ) {
        expect(state.currentTextEditingValue.composing, const TextRange(start: 5, end: 7));
      } else {
        expect(state.currentTextEditingValue.composing, TextRange.empty);
      }
    });

    testWidgets("composing range handled correctly when it's overflowed", (WidgetTester tester) async {
      const String string = '👨‍👩‍👦0123456';

      await setupWidget(tester, LengthLimitingTextInputFormatter(maxLength));

      final EditableTextState state = tester.state<EditableTextState>(find.byType(EditableText));

      // Initially we're not at maxLength with no composing text.
      state.updateEditingValue(const TextEditingValue(text: string));
      expect(state.currentTextEditingValue.composing, TextRange.empty);

      // Clearing composing range if collapsed.
      state.updateEditingValue(const TextEditingValue(text: string, composing: TextRange(start: 10, end: 10)));
      expect(state.currentTextEditingValue.composing, TextRange.empty);

      // Clearing composing range if overflowed.
      state.updateEditingValue(const TextEditingValue(text: string, composing: TextRange(start: 10, end: 11)));
      expect(state.currentTextEditingValue.composing, TextRange.empty);
    });

    // Regression test for https://github.com/flutter/flutter/issues/68086.
    testWidgets('typing in the middle with different platforms.', (WidgetTester tester) async {
      await setupWidget(tester, LengthLimitingTextInputFormatter(maxLength));

      final EditableTextState state = tester.state<EditableTextState>(find.byType(EditableText));

      // Initially we're not at maxLength with no composing text.
      state.updateEditingValue(const TextEditingValue(text: 'abc'));
      expect(state.currentTextEditingValue.composing, TextRange.empty);

      // Start typing in the middle.
      state.updateEditingValue(const TextEditingValue(text: 'abDEc', composing: TextRange(start: 3, end: 4)));
      expect(state.currentTextEditingValue.text, 'abDEc');
      expect(state.currentTextEditingValue.composing, const TextRange(start: 3, end: 4));

      // Keep typing when the value has exceed the limitation.
      state.updateEditingValue(const TextEditingValue(text: 'abDEFc', composing: TextRange(start: 3, end: 5)));
      if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.fuchsia
      ) {
        expect(state.currentTextEditingValue.text, 'abDEFc');
        expect(state.currentTextEditingValue.composing, const TextRange(start: 3, end: 5));
      } else {
        expect(state.currentTextEditingValue.text, 'abDEc');
        expect(state.currentTextEditingValue.composing, const TextRange(start: 3, end: 4));
      }

      // Reset the value according to the limit.
      state.updateEditingValue(const TextEditingValue(text: 'abDEc'));
      expect(state.currentTextEditingValue.text, 'abDEc');
      expect(state.currentTextEditingValue.composing, TextRange.empty);

      state.updateEditingValue(const TextEditingValue(text: 'abDEFc', composing: TextRange(start: 4, end: 5)));
      expect(state.currentTextEditingValue.composing, TextRange.empty);
    });
  });

  group('callback errors', () {
    const String errorText = 'Test EditableText callback error';

    testWidgets('onSelectionChanged can throw errors', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: EditableText(
          showSelectionHandles: true,
          maxLines: 2,
          controller: TextEditingController(
            text: 'flutter is the best!',
          ),
          focusNode: FocusNode(),
          cursorColor: Colors.red,
          backgroundCursorColor: Colors.blue,
          style: Typography.material2018().black.subtitle1!.copyWith(fontFamily: 'Roboto'),
          keyboardType: TextInputType.text,
          selectionControls: materialTextSelectionControls,
          onSelectionChanged: (TextSelection selection, SelectionChangedCause? cause) {
            throw FlutterError(errorText);
          },
        ),
      ));

      // Interact with the field to establish the input connection.
      await tester.tap(find.byType(EditableText));
      final dynamic error = tester.takeException();
      expect(error, isFlutterError);
      expect(error.toString(), contains(errorText));
    });

    testWidgets('onChanged can throw errors', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: EditableText(
          showSelectionHandles: true,
          maxLines: 2,
          controller: TextEditingController(
            text: 'flutter is the best!',
          ),
          focusNode: FocusNode(),
          cursorColor: Colors.red,
          backgroundCursorColor: Colors.blue,
          style: Typography.material2018().black.subtitle1!.copyWith(fontFamily: 'Roboto'),
          keyboardType: TextInputType.text,
          onChanged: (String text) {
            throw FlutterError(errorText);
          },
        ),
      ));

      // Modify the text and expect an error from onChanged.
      await tester.enterText(find.byType(EditableText), '...');
      final dynamic error = tester.takeException();
      expect(error, isFlutterError);
      expect(error.toString(), contains(errorText));
    });

    testWidgets('onEditingComplete can throw errors', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: EditableText(
          showSelectionHandles: true,
          maxLines: 2,
          controller: TextEditingController(
            text: 'flutter is the best!',
          ),
          focusNode: FocusNode(),
          cursorColor: Colors.red,
          backgroundCursorColor: Colors.blue,
          style: Typography.material2018().black.subtitle1!.copyWith(fontFamily: 'Roboto'),
          keyboardType: TextInputType.text,
          onEditingComplete: () {
            throw FlutterError(errorText);
          },
        ),
      ));

      // Interact with the field to establish the input connection.
      final Offset topLeft = tester.getTopLeft(find.byType(EditableText));
      await tester.tapAt(topLeft + const Offset(0.0, 5.0));
      await tester.pump();

      // Submit and expect an error from onEditingComplete.
      await tester.testTextInput.receiveAction(TextInputAction.done);
      final dynamic error = tester.takeException();
      expect(error, isFlutterError);
      expect(error.toString(), contains(errorText));
    });

    testWidgets('onSubmitted can throw errors', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: EditableText(
          showSelectionHandles: true,
          maxLines: 2,
          controller: TextEditingController(
            text: 'flutter is the best!',
          ),
          focusNode: FocusNode(),
          cursorColor: Colors.red,
          backgroundCursorColor: Colors.blue,
          style: Typography.material2018().black.subtitle1!.copyWith(fontFamily: 'Roboto'),
          keyboardType: TextInputType.text,
          onSubmitted: (String text) {
            throw FlutterError(errorText);
          },
        ),
      ));

      // Interact with the field to establish the input connection.
      final Offset topLeft = tester.getTopLeft(find.byType(EditableText));
      await tester.tapAt(topLeft + const Offset(0.0, 5.0));
      await tester.pump();

      // Submit and expect an error from onSubmitted.
      await tester.testTextInput.receiveAction(TextInputAction.done);
      final dynamic error = tester.takeException();
      expect(error, isFlutterError);
      expect(error.toString(), contains(errorText));
    });

    testWidgets('input formatters can throw errors', (WidgetTester tester) async {
      final TextInputFormatter badFormatter = TextInputFormatter.withFunction(
        (TextEditingValue oldValue, TextEditingValue newValue) => throw FlutterError(errorText),
      );
      final TextEditingController controller = TextEditingController(
        text: 'flutter is the best!',
      );
      await tester.pumpWidget(MaterialApp(
        home: EditableText(
          showSelectionHandles: true,
          maxLines: 2,
          controller: controller,
          inputFormatters: <TextInputFormatter>[badFormatter],
          focusNode: FocusNode(),
          cursorColor: Colors.red,
          backgroundCursorColor: Colors.blue,
          style: Typography.material2018().black.subtitle1!.copyWith(fontFamily: 'Roboto'),
          keyboardType: TextInputType.text,
        ),
      ));

      // Interact with the field to establish the input connection.
      await tester.tap(find.byType(EditableText));
      await tester.pump();

      await tester.enterText(find.byType(EditableText), 'text');

      final dynamic error = tester.takeException();
      expect(error, isFlutterError);
      expect(error.toString(), contains(errorText));
      expect(controller.text, 'text');
    });
  });

  // Regression test for https://github.com/flutter/flutter/issues/72400.
  testWidgets("delete doesn't cause crash when selection is -1,-1", (WidgetTester tester) async {
    final UnsettableController unsettableController = UnsettableController();
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: EditableText(
            autofocus: true,
            controller: unsettableController,
            backgroundCursorColor: Colors.grey,
            focusNode: focusNode,
            style: textStyle,
            cursorColor: cursorColor,
          ),
        ),
      ),
    );

    await tester.pump(); // Wait for the autofocus to take effect.

    // Delete
    await sendKeys(
      tester,
      <LogicalKeyboardKey>[
        LogicalKeyboardKey.delete,
      ],
      targetPlatform: TargetPlatform.android,
    );

    expect(tester.takeException(), null);
  });

  testWidgets('can change behavior by overriding text editing shortcuts', (WidgetTester tester) async {
    const  Map<SingleActivator, Intent> testShortcuts = <SingleActivator, Intent>{
      SingleActivator(LogicalKeyboardKey.arrowLeft): ExtendSelectionByCharacterIntent(forward: true, collapseSelection: true),
      SingleActivator(LogicalKeyboardKey.keyX, control: true): ExtendSelectionByCharacterIntent(forward: true, collapseSelection: true),
      SingleActivator(LogicalKeyboardKey.keyC, control: true): ExtendSelectionByCharacterIntent(forward: true, collapseSelection: true),
      SingleActivator(LogicalKeyboardKey.keyV, control: true): ExtendSelectionByCharacterIntent(forward: true, collapseSelection: true),
      SingleActivator(LogicalKeyboardKey.keyA, control: true): ExtendSelectionByCharacterIntent(forward: true, collapseSelection: true),
    };
    final TextEditingController controller = TextEditingController(text: testText);
    controller.selection = const TextSelection(
      baseOffset: 0,
      extentOffset: 0,
      affinity: TextAffinity.upstream,
    );
    await tester.pumpWidget(MaterialApp(
      home: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 400,
          child: Shortcuts(
            shortcuts: testShortcuts,
            child: EditableText(
              maxLines: 10,
              controller: controller,
              showSelectionHandles: true,
              autofocus: true,
              focusNode: focusNode,
              style: Typography.material2018().black.subtitle1!,
              cursorColor: Colors.blue,
              backgroundCursorColor: Colors.grey,
              selectionControls: materialTextSelectionControls,
              keyboardType: TextInputType.text,
              textAlign: TextAlign.right,
            ),
          ),
        ),
      ),
    ));

    await tester.pump(); // Wait for autofocus to take effect.

    // The right arrow key moves to the right as usual.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(controller.selection.isCollapsed, isTrue);
    expect(controller.selection.baseOffset, 1);

    // And the testShortcuts also moves to the right due to the Shortcuts override.
    for (final SingleActivator singleActivator in testShortcuts.keys) {
      controller.selection = const TextSelection.collapsed(offset: 0);
      await tester.pump();

      await sendKeys(
        tester,
        <LogicalKeyboardKey>[singleActivator.trigger],
        shortcutModifier: singleActivator.control,
        targetPlatform: defaultTargetPlatform,
      );
      expect(controller.selection.isCollapsed, isTrue);
      expect(controller.selection.baseOffset, 1);
    }

    // On web, using keyboard for selection is handled by the browser.
  }, skip: kIsWeb); // [intended]

  testWidgets('navigating by word', (WidgetTester tester) async {
    final TextEditingController controller = TextEditingController(text: 'word word word');
    // word wo|rd| word
    controller.selection = const TextSelection(
      baseOffset: 7,
      extentOffset: 9,
      affinity: TextAffinity.upstream,
    );
    await tester.pumpWidget(MaterialApp(
      home: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 400,
          child: EditableText(
            maxLines: 10,
            controller: controller,
            autofocus: true,
            focusNode: focusNode,
            style: Typography.material2018().black.subtitle1!,
            cursorColor: Colors.blue,
            backgroundCursorColor: Colors.grey,
            keyboardType: TextInputType.text,
          ),
        ),
      ),
    ));

    await tester.pump(); // Wait for autofocus to take effect.
    expect(controller.selection.isCollapsed, false);
    expect(controller.selection.baseOffset, 7);
    expect(controller.selection.extentOffset, 9);

    await sendKeys(
      tester,
      <LogicalKeyboardKey>[LogicalKeyboardKey.arrowRight],
      shift: true,
      wordModifier: true,
      targetPlatform: defaultTargetPlatform,
    );
    await tester.pump();
    // word wo|rd word|
    expect(controller.selection.isCollapsed, false);
    expect(controller.selection.baseOffset, 7);
    expect(controller.selection.extentOffset, 14);

    await sendKeys(
      tester,
      <LogicalKeyboardKey>[LogicalKeyboardKey.arrowLeft],
      shift: true,
      wordModifier: true,
      targetPlatform: defaultTargetPlatform,
    );
    // word wo|rd |word
    expect(controller.selection.isCollapsed, false);
    expect(controller.selection.baseOffset, 7);
    expect(controller.selection.extentOffset, 10);

    await sendKeys(
      tester,
      <LogicalKeyboardKey>[LogicalKeyboardKey.arrowLeft],
      shift: true,
      wordModifier: true,
      targetPlatform: defaultTargetPlatform,
    );
    if (defaultTargetPlatform == TargetPlatform.macOS || defaultTargetPlatform == TargetPlatform.iOS) {
      // word wo|rd word
      expect(controller.selection.isCollapsed, true);
      expect(controller.selection.baseOffset, 7);
      expect(controller.selection.extentOffset, 7);

      await sendKeys(
        tester,
        <LogicalKeyboardKey>[LogicalKeyboardKey.arrowLeft],
        shift: true,
        wordModifier: true,
        targetPlatform: defaultTargetPlatform,
      );
    }

    // word |wo|rd word
    expect(controller.selection.isCollapsed, false);
    expect(controller.selection.baseOffset, 7);
    expect(controller.selection.extentOffset, 5);

    await sendKeys(
      tester,
      <LogicalKeyboardKey>[LogicalKeyboardKey.arrowLeft],
      shift: true,
      wordModifier: true,
      targetPlatform: defaultTargetPlatform,
    );
    // |word wo|rd word
    expect(controller.selection.isCollapsed, false);
    expect(controller.selection.baseOffset, 7);
    expect(controller.selection.extentOffset, 0);

    await sendKeys(
      tester,
      <LogicalKeyboardKey>[LogicalKeyboardKey.arrowRight],
      shift: true,
      wordModifier: true,
      targetPlatform: defaultTargetPlatform,
    );
    // word| wo|rd word
    expect(controller.selection.isCollapsed, false);
    expect(controller.selection.baseOffset, 7);
    expect(controller.selection.extentOffset, 4);

    await sendKeys(
      tester,
      <LogicalKeyboardKey>[LogicalKeyboardKey.arrowRight],
      shift: true,
      wordModifier: true,
      targetPlatform: defaultTargetPlatform,
    );
    if (defaultTargetPlatform == TargetPlatform.macOS || defaultTargetPlatform == TargetPlatform.iOS) {
      // word wo|rd word
      expect(controller.selection.isCollapsed, true);
      expect(controller.selection.baseOffset, 7);
      expect(controller.selection.extentOffset, 7);

      await sendKeys(
        tester,
        <LogicalKeyboardKey>[LogicalKeyboardKey.arrowRight],
        shift: true,
        wordModifier: true,
        targetPlatform: defaultTargetPlatform,
      );
    }

    // word wo|rd| word
    expect(controller.selection.isCollapsed, false);
    expect(controller.selection.baseOffset, 7);
    expect(controller.selection.extentOffset, 9);

    // On web, using keyboard for selection is handled by the browser.
  }, variant: TargetPlatformVariant.all(), skip: kIsWeb); // [intended]

  testWidgets('navigating multiline text', (WidgetTester tester) async {
    const String multilineText = 'word word word\nword word\nword'; // 15 + 10 + 4;
    final TextEditingController controller = TextEditingController(text: multilineText);
    // wo|rd wo|rd
    controller.selection = const TextSelection(
      baseOffset: 17,
      extentOffset: 22,
      affinity: TextAffinity.upstream,
    );
    await tester.pumpWidget(MaterialApp(
      home: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 400,
          child: EditableText(
            maxLines: 10,
            controller: controller,
            autofocus: true,
            focusNode: focusNode,
            style: Typography.material2018().black.subtitle1!,
            cursorColor: Colors.blue,
            backgroundCursorColor: Colors.grey,
            keyboardType: TextInputType.text,
          ),
        ),
      ),
    ));

    await tester.pump(); // Wait for autofocus to take effect.
    expect(controller.selection.isCollapsed, false);
    expect(controller.selection.baseOffset, 17);
    expect(controller.selection.extentOffset, 22);

    // Multiple expandRightByLine shortcuts only move to the end of the line and
    // not to the next line.
    await sendKeys(
      tester,
      <LogicalKeyboardKey>[
        LogicalKeyboardKey.arrowRight,
        LogicalKeyboardKey.arrowRight,
        LogicalKeyboardKey.arrowRight,
      ],
      shift: true,
      lineModifier: true,
      targetPlatform: defaultTargetPlatform,
    );
    expect(controller.selection.isCollapsed, false);
    expect(controller.selection.baseOffset, 17);
    expect(controller.selection.extentOffset, 24);

    // Multiple expandLeftByLine shortcuts only move to the start of the line
    // and not to the previous line.
    await sendKeys(
      tester,
      <LogicalKeyboardKey>[
        LogicalKeyboardKey.arrowLeft,
        LogicalKeyboardKey.arrowLeft,
        LogicalKeyboardKey.arrowLeft,
      ],
      shift: true,
      lineModifier: true,
      targetPlatform: defaultTargetPlatform,
    );
    expect(controller.selection.isCollapsed, false);
    switch (defaultTargetPlatform) {
      // These platforms extend by line.
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        expect(controller.selection.baseOffset, 17);
        expect(controller.selection.extentOffset, 15);
        break;

      // Mac and iOS expand by line.
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        expect(controller.selection.baseOffset, 15);
        expect(controller.selection.extentOffset, 24);
        break;
    }

    // Set the caret to the end of a line.
    controller.selection = const TextSelection(
      baseOffset: 24,
      extentOffset: 24,
      affinity: TextAffinity.upstream,
    );
    await tester.pump();
    expect(controller.selection.isCollapsed, true);
    expect(controller.selection.baseOffset, 24);
    expect(controller.selection.extentOffset, 24);

    // Can't expand right by line any further.
    await sendKeys(
      tester,
      <LogicalKeyboardKey>[
        LogicalKeyboardKey.arrowRight,
      ],
      shift: true,
      lineModifier: true,
      targetPlatform: defaultTargetPlatform,
    );
    expect(controller.selection.isCollapsed, true);
    expect(controller.selection.baseOffset, 24);
    expect(controller.selection.extentOffset, 24);

    // Can select the entire line from the end.
    await sendKeys(
      tester,
      <LogicalKeyboardKey>[
        LogicalKeyboardKey.arrowLeft,
      ],
      shift: true,
      lineModifier: true,
      targetPlatform: defaultTargetPlatform,
    );
    expect(controller.selection.isCollapsed, false);
    expect(controller.selection.baseOffset, 24);
    expect(controller.selection.extentOffset, 15);

    // Set the caret to the start of a line.
    controller.selection = const TextSelection(
      baseOffset: 15,
      extentOffset: 15,
      affinity: TextAffinity.upstream,
    );
    await tester.pump();
    expect(controller.selection.isCollapsed, true);
    expect(controller.selection.baseOffset, 15);
    expect(controller.selection.extentOffset, 15);

    // Can't expand let any further.
    await sendKeys(
      tester,
      <LogicalKeyboardKey>[
        LogicalKeyboardKey.arrowLeft,
      ],
      shift: true,
      lineModifier: true,
      targetPlatform: defaultTargetPlatform,
    );
    expect(controller.selection.isCollapsed, true);
    expect(controller.selection.baseOffset, 15);
    expect(controller.selection.extentOffset, 15);

    // Can select the entire line from the start.
    await sendKeys(
      tester,
      <LogicalKeyboardKey>[
        LogicalKeyboardKey.arrowRight,
      ],
      shift: true,
      lineModifier: true,
      targetPlatform: defaultTargetPlatform,
    );
    expect(controller.selection.isCollapsed, false);
    expect(controller.selection.baseOffset, 15);
    expect(controller.selection.extentOffset, 24);
    // On web, using keyboard for selection is handled by the browser.
  }, variant: TargetPlatformVariant.all(), skip: kIsWeb); // [intended]

  testWidgets("Mac's expand by line behavior on multiple lines", (WidgetTester tester) async {
    const String multilineText = 'word word word\nword word\nword'; // 15 + 10 + 4;
    final TextEditingController controller = TextEditingController(text: multilineText);
    // word word word
    // wo|rd word
    // w|ord
    controller.selection = const TextSelection(
      baseOffset: 17,
      extentOffset: 26,
      affinity: TextAffinity.upstream,
    );
    await tester.pumpWidget(MaterialApp(
      home: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 400,
          child: EditableText(
            maxLines: 10,
            controller: controller,
            autofocus: true,
            focusNode: focusNode,
            style: Typography.material2018().black.subtitle1!,
            cursorColor: Colors.blue,
            backgroundCursorColor: Colors.grey,
            keyboardType: TextInputType.text,
          ),
        ),
      ),
    ));

    await tester.pump(); // Wait for autofocus to take effect.
    expect(controller.selection.isCollapsed, false);
    expect(controller.selection.baseOffset, 17);
    expect(controller.selection.extentOffset, 26);

    // Expanding right to the end of the line moves the extent on the second
    // selected line.
    await sendKeys(
      tester,
      <LogicalKeyboardKey>[
        LogicalKeyboardKey.arrowRight,
      ],
      shift: true,
      lineModifier: true,
      targetPlatform: defaultTargetPlatform,
    );
    expect(controller.selection.isCollapsed, false);
    expect(controller.selection.baseOffset, 17);
    expect(controller.selection.extentOffset, 29);

    // Expanding right again does nothing.
    await sendKeys(
      tester,
      <LogicalKeyboardKey>[
        LogicalKeyboardKey.arrowRight,
        LogicalKeyboardKey.arrowRight,
        LogicalKeyboardKey.arrowRight,
      ],
      shift: true,
      lineModifier: true,
      targetPlatform: defaultTargetPlatform,
    );
    expect(controller.selection.isCollapsed, false);
    expect(controller.selection.baseOffset, 17);
    expect(controller.selection.extentOffset, 29);

    // Expanding left by line moves the base on the first selected line to the
    // beginning of that line.
    await sendKeys(
      tester,
      <LogicalKeyboardKey>[
        LogicalKeyboardKey.arrowLeft,
      ],
      shift: true,
      lineModifier: true,
      targetPlatform: defaultTargetPlatform,
    );
    expect(controller.selection.isCollapsed, false);
    expect(controller.selection.baseOffset, 15);
    expect(controller.selection.extentOffset, 29);

    // Expanding left again does nothing.
    await sendKeys(
      tester,
      <LogicalKeyboardKey>[
        LogicalKeyboardKey.arrowLeft,
        LogicalKeyboardKey.arrowLeft,
        LogicalKeyboardKey.arrowLeft,
      ],
      shift: true,
      lineModifier: true,
      targetPlatform: defaultTargetPlatform,
    );
    expect(controller.selection.isCollapsed, false);
    expect(controller.selection.baseOffset, 15);
    expect(controller.selection.extentOffset, 29);
  },
    // On web, using keyboard for selection is handled by the browser.
    skip: kIsWeb, // [intended]
    variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.macOS })
  );

  testWidgets("Mac's expand extent position", (WidgetTester tester) async {
    const String testText = 'Now is the time for all good people to come to the aid of their country';
    final TextEditingController controller = TextEditingController(text: testText);
    // Start the selection in the middle somewhere.
    controller.selection = const TextSelection.collapsed(offset: 10);
    await tester.pumpWidget(MaterialApp(
      home: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 400,
          child: EditableText(
            maxLines: 10,
            controller: controller,
            autofocus: true,
            focusNode: focusNode,
            style: Typography.material2018().black.subtitle1!,
            cursorColor: Colors.blue,
            backgroundCursorColor: Colors.grey,
            keyboardType: TextInputType.text,
          ),
        ),
      ),
    ));

    await tester.pump(); // Wait for autofocus to take effect.
    expect(controller.selection.isCollapsed, true);
    expect(controller.selection.baseOffset, 10);

    // With cursor in the middle of the line, cmd + left. Left end is the extent.
    await sendKeys(
      tester,
      <LogicalKeyboardKey>[
        LogicalKeyboardKey.arrowLeft,
      ],
      lineModifier: true,
      shift: true,
      targetPlatform: defaultTargetPlatform,
    );
    expect(
      controller.selection,
      equals(
        const TextSelection(
          baseOffset: 10,
          extentOffset: 0,
          affinity: TextAffinity.upstream,
        ),
      ),
    );

    // With cursor in the middle of the line, cmd + right. Right end is the extent.
    controller.selection = const TextSelection.collapsed(offset: 10);
    await tester.pump();
    await sendKeys(
      tester,
      <LogicalKeyboardKey>[
        LogicalKeyboardKey.arrowRight,
      ],
      lineModifier: true,
      shift: true,
      targetPlatform: defaultTargetPlatform,
    );
    expect(
      controller.selection,
      equals(
        const TextSelection(
          baseOffset: 10,
          extentOffset: 29,
          affinity: TextAffinity.upstream,
        ),
      ),
    );

    // With cursor in the middle of the line, cmd + left then cmd + right. Left end is the extent.
    controller.selection = const TextSelection.collapsed(offset: 10);
    await tester.pump();
    await sendKeys(
      tester,
      <LogicalKeyboardKey>[
        LogicalKeyboardKey.arrowLeft,
      ],
      lineModifier: true,
      shift: true,
      targetPlatform: defaultTargetPlatform,
    );
    await tester.pump();
    await sendKeys(
      tester,
      <LogicalKeyboardKey>[
        LogicalKeyboardKey.arrowRight,
      ],
      lineModifier: true,
      shift: true,
      targetPlatform: defaultTargetPlatform,
    );
    expect(
      controller.selection,
      equals(
        const TextSelection(
          baseOffset: 29,
          extentOffset: 0,
          affinity: TextAffinity.upstream,
        ),
      ),
    );

    // With cursor in the middle of the line, cmd + right then cmd + left. Right end is the extent.
    controller.selection = const TextSelection.collapsed(offset: 10);
    await tester.pump();
    await sendKeys(
      tester,
      <LogicalKeyboardKey>[
        LogicalKeyboardKey.arrowRight,
      ],
      lineModifier: true,
      shift: true,
      targetPlatform: defaultTargetPlatform,
    );
    await tester.pump();
    await sendKeys(
      tester,
      <LogicalKeyboardKey>[
        LogicalKeyboardKey.arrowLeft,
      ],
      lineModifier: true,
      shift: true,
      targetPlatform: defaultTargetPlatform,
    );
    expect(
      controller.selection,
      equals(
        const TextSelection(
          baseOffset: 0,
          extentOffset: 29,
          affinity: TextAffinity.upstream,
        ),
      ),
    );

    // With an RTL selection in the middle of the line, cmd + left. Left end is the extent.
    controller.selection = const TextSelection(baseOffset: 12, extentOffset: 8);
    await tester.pump();
    await sendKeys(
      tester,
      <LogicalKeyboardKey>[
        LogicalKeyboardKey.arrowLeft,
      ],
      lineModifier: true,
      shift: true,
      targetPlatform: defaultTargetPlatform,
    );
    expect(
      controller.selection,
      equals(
        const TextSelection(
          baseOffset: 12,
          extentOffset: 0,
          affinity: TextAffinity.upstream,
        ),
      ),
    );

    // With an RTL selection in the middle of the line, cmd + right. Left end is the extent.
    controller.selection = const TextSelection(baseOffset: 12, extentOffset: 8);
    await tester.pump();
    await sendKeys(
      tester,
      <LogicalKeyboardKey>[
        LogicalKeyboardKey.arrowRight,
      ],
      lineModifier: true,
      shift: true,
      targetPlatform: defaultTargetPlatform,
    );
    expect(
      controller.selection,
      equals(
        const TextSelection(
          baseOffset: 29,
          extentOffset: 8,
          affinity: TextAffinity.upstream,
        ),
      ),
    );

    // With an LTR selection in the middle of the line, cmd + right. Right end is the extent.
    controller.selection = const TextSelection(baseOffset: 8, extentOffset: 12);
    await tester.pump();
    await sendKeys(
      tester,
      <LogicalKeyboardKey>[
        LogicalKeyboardKey.arrowRight,
      ],
      lineModifier: true,
      shift: true,
      targetPlatform: defaultTargetPlatform,
    );
    expect(
      controller.selection,
      equals(
        const TextSelection(
          baseOffset: 8,
          extentOffset: 29,
          affinity: TextAffinity.upstream,
        ),
      ),
    );

    // With an LTR selection in the middle of the line, cmd + left. Right end is the extent.
    controller.selection = const TextSelection(baseOffset: 8, extentOffset: 12);
    await tester.pump();
    await sendKeys(
      tester,
      <LogicalKeyboardKey>[
        LogicalKeyboardKey.arrowLeft,
      ],
      lineModifier: true,
      shift: true,
      targetPlatform: defaultTargetPlatform,
    );
    expect(
      controller.selection,
      equals(
        const TextSelection(
          baseOffset: 0,
          extentOffset: 12,
          affinity: TextAffinity.upstream,
        ),
      ),
    );
  },
    // On web, using keyboard for selection is handled by the browser.
    skip: kIsWeb, // [intended]
    variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.macOS })
  );

  testWidgets('expanding selection to start/end single line', (WidgetTester tester) async {
    final TextEditingController controller = TextEditingController(text: 'word word word');
    // word wo|rd| word
    controller.selection = const TextSelection(
      baseOffset: 7,
      extentOffset: 9,
      affinity: TextAffinity.upstream,
    );
    await tester.pumpWidget(MaterialApp(
      home: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 400,
          child: EditableText(
            maxLines: 10,
            controller: controller,
            autofocus: true,
            focusNode: focusNode,
            style: Typography.material2018().black.subtitle1!,
            cursorColor: Colors.blue,
            backgroundCursorColor: Colors.grey,
            keyboardType: TextInputType.text,
          ),
        ),
      ),
    ));

    await tester.pump(); // Wait for autofocus to take effect.
    expect(controller.selection.isCollapsed, false);
    expect(controller.selection.baseOffset, 7);
    expect(controller.selection.extentOffset, 9);

    final String targetPlatform = defaultTargetPlatform.toString();
    final String platform = targetPlatform.substring(targetPlatform.indexOf('.') + 1).toLowerCase();

    // Select to the start.
    await sendKeys(
      tester,
      <LogicalKeyboardKey>[
        LogicalKeyboardKey.home,
      ],
      shift: true,
      targetPlatform: defaultTargetPlatform,
    );

    // |word word| word
    expect(
      controller.selection,
      equals(
        const TextSelection(
          baseOffset: 9,
          extentOffset: 0,
          affinity: TextAffinity.upstream,
        ),
      ),
      reason: 'on $platform',
    );

    // Select to the end.
    await sendKeys(
      tester,
      <LogicalKeyboardKey>[
        LogicalKeyboardKey.end,
      ],
      shift: true,
      targetPlatform: defaultTargetPlatform,
    );

    // |word word word|
    expect(
      controller.selection,
      equals(
        const TextSelection(
          baseOffset: 0,
          extentOffset: 14,
          affinity: TextAffinity.upstream,
        ),
      ),
      reason: 'on $platform',
    );

  },
      // On web, using keyboard for selection is handled by the browser.
      skip: kIsWeb, // [intended]
      variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.macOS })
  );

  testWidgets('can change text editing behavior by overriding actions', (WidgetTester tester) async {
    final TextEditingController controller = TextEditingController(text: testText);
    controller.selection = const TextSelection(
      baseOffset: 0,
      extentOffset: 0,
      affinity: TextAffinity.upstream,
    );
    bool myIntentWasCalled = false;
    final CallbackAction<ExtendSelectionByCharacterIntent> overrideAction = CallbackAction<ExtendSelectionByCharacterIntent>(
      onInvoke: (ExtendSelectionByCharacterIntent intent) { myIntentWasCalled = true; return null; },
    );
    await tester.pumpWidget(MaterialApp(
      home: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 400,
          child: Actions(
            actions: <Type, Action<Intent>>{ ExtendSelectionByCharacterIntent: overrideAction, },
            child: EditableText(
              maxLines: 10,
              controller: controller,
              showSelectionHandles: true,
              autofocus: true,
              focusNode: focusNode,
              style: Typography.material2018().black.subtitle1!,
              cursorColor: Colors.blue,
              backgroundCursorColor: Colors.grey,
              selectionControls: materialTextSelectionControls,
              keyboardType: TextInputType.text,
              textAlign: TextAlign.right,
            ),
          ),
        ),
      ),
    ));
    await tester.pump(); // Wait for autofocus to take effect.

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(controller.selection.isCollapsed, isTrue);
    expect(controller.selection.baseOffset, 0);
    expect(myIntentWasCalled, isTrue);

    // On web, using keyboard for selection is handled by the browser.
  }, skip: kIsWeb); // [intended]

  testWidgets('ignore key event from web platform', (WidgetTester tester) async {
    final TextEditingController controller = TextEditingController(
      text: 'test\ntest',
    );
    controller.selection = const TextSelection(
      baseOffset: 0,
      extentOffset: 0,
      affinity: TextAffinity.upstream,
    );
    bool myIntentWasCalled = false;
    await tester.pumpWidget(MaterialApp(
      home: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 400,
          child: Actions(
            actions: <Type, Action<Intent>>{
              ExtendSelectionByCharacterIntent: CallbackAction<ExtendSelectionByCharacterIntent>(
                onInvoke: (ExtendSelectionByCharacterIntent intent) { myIntentWasCalled = true; return null; },
              ),
            },
            child: EditableText(
              maxLines: 10,
              controller: controller,
              showSelectionHandles: true,
              autofocus: true,
              focusNode: focusNode,
              style: Typography.material2018().black.subtitle1!,
              cursorColor: Colors.blue,
              backgroundCursorColor: Colors.grey,
              selectionControls: materialTextSelectionControls,
              keyboardType: TextInputType.text,
              textAlign: TextAlign.right,
            ),
          ),
        ),
      ),
    ));

    await tester.pump(); // Wait for autofocus to take effect.

    if (kIsWeb) {
      await simulateKeyDownEvent(LogicalKeyboardKey.arrowRight, platform: 'web');
      await tester.pump();
      expect(myIntentWasCalled, isFalse);
      expect(controller.selection.isCollapsed, true);
      expect(controller.selection.baseOffset, 0);
    } else {
      await simulateKeyDownEvent(LogicalKeyboardKey.arrowRight, platform: 'android');
      await tester.pump();
      expect(myIntentWasCalled, isTrue);
      expect(controller.selection.isCollapsed, true);
      expect(controller.selection.baseOffset, 0);
    }
  }, variant: KeySimulatorTransitModeVariant.all());

  testWidgets('the toolbar is disposed when selection changes and there is no selectionControls', (WidgetTester tester) async {
    late StateSetter setState;
    bool enableInteractiveSelection = true;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setter) {
                setState = setter;
                return EditableText(
                  focusNode: focusNode,
                  style: Typography.material2018().black.subtitle1!,
                  cursorColor: Colors.blue,
                  backgroundCursorColor: Colors.grey,
                  selectionControls: enableInteractiveSelection ? materialTextSelectionControls : null,
                  controller: controller,
                  enableInteractiveSelection: enableInteractiveSelection,
                );
              },
            ),
          ),
        ),
      ),
    );

    final EditableTextState state =
        tester.state<EditableTextState>(find.byType(EditableText));

    // Can't show the toolbar when there's no focus.
    expect(state.showToolbar(), false);
    await tester.pumpAndSettle();
    expect(find.text('Paste'), findsNothing);

    // Can show the toolbar when focused even though there's no text.
    state.renderEditable.selectWordsInRange(
      from: Offset.zero,
      cause: SelectionChangedCause.tap,
    );
    await tester.pump();
    expect(state.showToolbar(), isTrue);
    await tester.pumpAndSettle();
    expect(find.text('Paste'), findsOneWidget);

    // Find the FadeTransition in the toolbar and expect that it has not been
    // disposed.
    final FadeTransition fadeTransition = find.byType(FadeTransition).evaluate()
      .map((Element element) => element.widget as FadeTransition)
      .firstWhere((FadeTransition fadeTransition) {
        return fadeTransition.child is CompositedTransformFollower;
      });
    expect(fadeTransition.toString(), isNot(contains('DISPOSED')));

    // Turn off interactive selection and change the text, which triggers the
    // toolbar to be disposed.
    setState(() {
      enableInteractiveSelection = false;
    });
    await tester.pump();
    await tester.enterText(find.byType(EditableText), 'abc');
    await tester.pump();

    expect(fadeTransition.toString(), contains('DISPOSED'));
    // On web, using keyboard for selection is handled by the browser.
  }, skip: kIsWeb); // [intended]

  testWidgets('EditableText does not leak animation controllers', (WidgetTester tester) async {
    final FocusNode focusNode = FocusNode();
    await tester.pumpWidget(
      MaterialApp(
        home: EditableText(
          autofocus: true,
          controller: TextEditingController(text: 'A'),
          focusNode: focusNode,
          style: textStyle,
          cursorColor: Colors.blue,
          backgroundCursorColor: Colors.grey,
          cursorOpacityAnimates: true,
        ),
      ),
    );

    expect(focusNode.hasPrimaryFocus, isTrue);
    final EditableTextState state = tester.state(find.byType(EditableText));

    state.updateFloatingCursor(RawFloatingCursorPoint(state: FloatingCursorDragState.Start, offset: Offset.zero));

    // Start the cursor blink opacity animation controller.
    // _kCursorBlinkWaitForStart
    await tester.pump(const Duration(milliseconds: 150));
    // _kCursorBlinkHalfPeriod
    await tester.pump(const Duration(milliseconds: 500));

    // Start the floating cursor reset animation controller.
    state.updateFloatingCursor(RawFloatingCursorPoint(state: FloatingCursorDragState.End, offset: Offset.zero));

    expect(tester.binding.transientCallbackCount, 2);

    await tester.pumpWidget(const SizedBox());
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('Selection will be scrolled into view with SelectionChangedCause', (WidgetTester tester) async {
    final GlobalKey<EditableTextState> key = GlobalKey<EditableTextState>();
    final String text = List<int>.generate(64, (int index) => index).join('\n');
    final TextEditingController controller = TextEditingController(text: text);
    final ScrollController scrollController = ScrollController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              height: 32,
              child: EditableText(
                key: key,
                focusNode: focusNode,
                style: Typography.material2018().black.subtitle1!,
                cursorColor: Colors.blue,
                backgroundCursorColor: Colors.grey,
                controller: controller,
                scrollController: scrollController,
                maxLines: 2,
              ),
            ),
          ),
        ),
      ),
    );

    final TextSelectionDelegate textSelectionDelegate = key.currentState!;

    late double maxScrollExtent;
    Future<void> resetSelectionAndScrollOffset([bool setMaxScrollExtent = true]) async {
      controller.value = controller.value.copyWith(
        text: text,
        selection: controller.selection.copyWith(baseOffset: 0, extentOffset: 1),
      );
      await tester.pump();
      final double targetOffset = setMaxScrollExtent ? scrollController.position.maxScrollExtent : 0.0;
      scrollController.jumpTo(targetOffset);
      await tester.pumpAndSettle();
      maxScrollExtent = scrollController.position.maxScrollExtent;
      expect(scrollController.offset, targetOffset);
    }

    // Cut
    await resetSelectionAndScrollOffset();
    textSelectionDelegate.cutSelection(SelectionChangedCause.keyboard);
    await tester.pump();
    expect(scrollController.offset, maxScrollExtent);

    await resetSelectionAndScrollOffset();
    textSelectionDelegate.cutSelection(SelectionChangedCause.toolbar);
    await tester.pump();
    expect(scrollController.offset.roundToDouble(), 0.0);

    // Paste
    await resetSelectionAndScrollOffset();
    await textSelectionDelegate.pasteText(SelectionChangedCause.keyboard);
    await tester.pump();
    expect(scrollController.offset, maxScrollExtent);

    await resetSelectionAndScrollOffset();
    await textSelectionDelegate.pasteText(SelectionChangedCause.toolbar);
    await tester.pump();
    expect(scrollController.offset.roundToDouble(), 0.0);

    // Select all
    await resetSelectionAndScrollOffset(false);
    textSelectionDelegate.selectAll(SelectionChangedCause.keyboard);
    await tester.pump();
    expect(scrollController.offset, 0.0);

    await resetSelectionAndScrollOffset(false);
    textSelectionDelegate.selectAll(SelectionChangedCause.toolbar);
    await tester.pump();
    expect(scrollController.offset.roundToDouble(), maxScrollExtent);

    // Copy
    await resetSelectionAndScrollOffset();
    textSelectionDelegate.copySelection(SelectionChangedCause.keyboard);
    await tester.pump();
    expect(scrollController.offset, maxScrollExtent);

    await resetSelectionAndScrollOffset();
    textSelectionDelegate.copySelection(SelectionChangedCause.toolbar);
    await tester.pump();
    expect(scrollController.offset.roundToDouble(), 0.0);
  });

  testWidgets('Should not scroll on paste if caret already visible', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/96658.
    final ScrollController scrollController = ScrollController();
    final TextEditingController controller = TextEditingController(
      text: 'Lorem ipsum please paste here: \n${".\n" * 50}',
    );
    final FocusNode focusNode = FocusNode();

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            height: 600.0,
            width: 600.0,
            child: EditableText(
              controller: controller,
              scrollController: scrollController,
              focusNode: focusNode,
              maxLines: null,
              style: const TextStyle(fontSize: 36.0),
              backgroundCursorColor: Colors.grey,
              cursorColor: cursorColor,
            ),
          ),
        ),
      )
    );

    await Clipboard.setData(const ClipboardData(text: 'Fairly long text to be pasted'));
    focusNode.requestFocus();

    final EditableTextState state =
        tester.state<EditableTextState>(find.byType(EditableText));

    expect(scrollController.offset, 0.0);

    controller.selection = const TextSelection.collapsed(offset: 31);
    await state.pasteText(SelectionChangedCause.toolbar);
    await tester.pumpAndSettle();

    // No scroll should happen as the caret is in the viewport all the time.
    expect(scrollController.offset, 0.0);
  });

  testWidgets('Autofill enabled by default', (WidgetTester tester) async {
    final FocusNode focusNode = FocusNode();
    await tester.pumpWidget(
      MaterialApp(
        home: EditableText(
          autofocus: true,
          controller: TextEditingController(text: 'A'),
          focusNode: focusNode,
          style: textStyle,
          cursorColor: Colors.blue,
          backgroundCursorColor: Colors.grey,
          cursorOpacityAnimates: true,
        ),
      ),
    );

    assert(focusNode.hasFocus);
    expect(
      tester.testTextInput.log,
      contains(matchesMethodCall('TextInput.requestAutofill')),
    );
  });

  testWidgets('Autofill can be disabled', (WidgetTester tester) async {
    final FocusNode focusNode = FocusNode();
    await tester.pumpWidget(
      MaterialApp(
        home: EditableText(
          autofocus: true,
          controller: TextEditingController(text: 'A'),
          focusNode: focusNode,
          style: textStyle,
          cursorColor: Colors.blue,
          backgroundCursorColor: Colors.grey,
          cursorOpacityAnimates: true,
          autofillHints: null,
        ),
      ),
    );

    assert(focusNode.hasFocus);
    expect(
      tester.testTextInput.log,
      isNot(contains(matchesMethodCall('TextInput.requestAutofill'))),
    );
  });

  group('TextEditingHistory', () {
    Future<void> sendUndoRedo(WidgetTester tester, [bool redo = false]) {
      return sendKeys(
        tester,
        <LogicalKeyboardKey>[
          LogicalKeyboardKey.keyZ,
        ],
        shortcutModifier: true,
        shift: redo,
        targetPlatform: defaultTargetPlatform,
      );
    }

    Future<void> sendUndo(WidgetTester tester) => sendUndoRedo(tester);
    Future<void> sendRedo(WidgetTester tester) => sendUndoRedo(tester, true);

    testWidgets('inside EditableText', (WidgetTester tester) async {
      final TextEditingController controller = TextEditingController();
      final FocusNode focusNode = FocusNode();
      await tester.pumpWidget(
        MaterialApp(
          home: EditableText(
            controller: controller,
            focusNode: focusNode,
            style: textStyle,
            cursorColor: Colors.blue,
            backgroundCursorColor: Colors.grey,
            cursorOpacityAnimates: true,
            autofillHints: null,
          ),
        ),
      );

      expect(
        controller.value,
        TextEditingValue.empty,
      );

      // Undo/redo have no effect on an empty field that has never been edited.
      await sendUndo(tester);
      expect(
        controller.value,
        TextEditingValue.empty,
      );
      await sendRedo(tester);
      expect(
        controller.value,
        TextEditingValue.empty,
      );

      await tester.pump();
      expect(
        controller.value,
        TextEditingValue.empty,
      );

      focusNode.requestFocus();
      expect(
        controller.value,
        TextEditingValue.empty,
      );
      await tester.pump();
      expect(
        controller.value,
        const TextEditingValue(
          selection: TextSelection.collapsed(offset: 0),
        ),
      );

      // Wait for the throttling.
      await tester.pump(const Duration(milliseconds: 500));

      // Undo/redo still have no effect. The field is focused and the value has
      // changed, but the text remains empty.
      await sendUndo(tester);
      expect(
        controller.value,
        const TextEditingValue(
          selection: TextSelection.collapsed(offset: 0),
        ),
      );
      await sendRedo(tester);
      expect(
        controller.value,
        const TextEditingValue(
          selection: TextSelection.collapsed(offset: 0),
        ),
      );

      await tester.enterText(find.byType(EditableText), '1');
      expect(
        controller.value,
        const TextEditingValue(
          text: '1',
          selection: TextSelection.collapsed(offset: 1),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      // Can undo/redo a single insertion.
      await sendUndo(tester);
      expect(
        controller.value,
        const TextEditingValue(
          selection: TextSelection.collapsed(offset: 0),
        ),
      );
      await sendUndo(tester);
      expect(
        controller.value,
        const TextEditingValue(
          selection: TextSelection.collapsed(offset: 0),
        ),
      );

      await sendRedo(tester);
      expect(
        controller.value,
        const TextEditingValue(
          text: '1',
          selection: TextSelection.collapsed(offset: 1),
        ),
      );
      await sendRedo(tester);
      expect(
        controller.value,
        const TextEditingValue(
          text: '1',
          selection: TextSelection.collapsed(offset: 1),
        ),
      );

      // And can undo/redo multiple insertions.
      await tester.enterText(find.byType(EditableText), '13');
      expect(
        controller.value,
        const TextEditingValue(
          text: '13',
          selection: TextSelection.collapsed(offset: 2),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await sendRedo(tester);
      expect(
        controller.value,
        const TextEditingValue(
          text: '13',
          selection: TextSelection.collapsed(offset: 2),
        ),
      );
      await sendUndo(tester);
      expect(
        controller.value,
        const TextEditingValue(
          text: '1',
          selection: TextSelection.collapsed(offset: 1),
        ),
      );
      await sendUndo(tester);
      expect(
        controller.value,
        const TextEditingValue(
          selection: TextSelection.collapsed(offset: 0),
        ),
      );
      await sendRedo(tester);
      expect(
        controller.value,
        const TextEditingValue(
          text: '1',
          selection: TextSelection.collapsed(offset: 1),
        ),
      );
      await sendRedo(tester);
      expect(
        controller.value,
        const TextEditingValue(
          text: '13',
          selection: TextSelection.collapsed(offset: 2),
        ),
      );

      // Can change the middle of the stack timeline.
      await sendUndo(tester);
      expect(
        controller.value,
        const TextEditingValue(
          text: '1',
          selection: TextSelection.collapsed(offset: 1),
        ),
      );
      await tester.enterText(find.byType(EditableText), '12');
      await tester.pump(const Duration(milliseconds: 500));
      await sendRedo(tester);
      expect(
        controller.value,
        const TextEditingValue(
          text: '12',
          selection: TextSelection.collapsed(offset: 2),
        ),
      );
      await sendRedo(tester);
      expect(
        controller.value,
        const TextEditingValue(
          text: '12',
          selection: TextSelection.collapsed(offset: 2),
        ),
      );
      await sendUndo(tester);
      expect(
        controller.value,
        const TextEditingValue(
          text: '1',
          selection: TextSelection.collapsed(offset: 1),
        ),
      );
      await sendUndo(tester);
      expect(
        controller.value,
        const TextEditingValue(
          selection: TextSelection.collapsed(offset: 0),
        ),
      );
      await sendRedo(tester);
      expect(
        controller.value,
        const TextEditingValue(
          text: '1',
          selection: TextSelection.collapsed(offset: 1),
        ),
      );
      await sendRedo(tester);
      expect(
        controller.value,
        const TextEditingValue(
          text: '12',
          selection: TextSelection.collapsed(offset: 2),
        ),
      );
    // On web, these keyboard shortcuts are handled by the browser.
    }, variant: TargetPlatformVariant.all(), skip: kIsWeb); // [intended]

    testWidgets('inside EditableText, duplicate changes', (WidgetTester tester) async {
      final TextEditingController controller = TextEditingController();
      final FocusNode focusNode = FocusNode();
      await tester.pumpWidget(
        MaterialApp(
          home: EditableText(
            controller: controller,
            focusNode: focusNode,
            style: textStyle,
            cursorColor: Colors.blue,
            backgroundCursorColor: Colors.grey,
            cursorOpacityAnimates: true,
            autofillHints: null,
          ),
        ),
      );

      expect(
        controller.value,
        TextEditingValue.empty,
      );

      focusNode.requestFocus();
      expect(
        controller.value,
        TextEditingValue.empty,
      );
      await tester.pump();
      expect(
        controller.value,
        const TextEditingValue(
          selection: TextSelection.collapsed(offset: 0),
        ),
      );

      // Wait for the throttling.
      await tester.pump(const Duration(milliseconds: 500));

      await tester.enterText(find.byType(EditableText), '1');
      expect(
        controller.value,
        const TextEditingValue(
          text: '1',
          selection: TextSelection.collapsed(offset: 1),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      // Can undo/redo a single insertion.
      await sendUndo(tester);
      expect(
        controller.value,
        const TextEditingValue(
          selection: TextSelection.collapsed(offset: 0),
        ),
      );
      await sendRedo(tester);
      expect(
        controller.value,
        const TextEditingValue(
          text: '1',
          selection: TextSelection.collapsed(offset: 1),
        ),
      );

      // Changes that result in the same state won't be saved on the undo stack.
      await tester.enterText(find.byType(EditableText), '12');
      expect(
        controller.value,
        const TextEditingValue(
          text: '12',
          selection: TextSelection.collapsed(offset: 2),
        ),
      );
      await tester.enterText(find.byType(EditableText), '1');
      expect(
        controller.value,
        const TextEditingValue(
          text: '1',
          selection: TextSelection.collapsed(offset: 1),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(
        controller.value,
        const TextEditingValue(
          text: '1',
          selection: TextSelection.collapsed(offset: 1),
        ),
      );
      await sendRedo(tester);
      expect(
        controller.value,
        const TextEditingValue(
          text: '1',
          selection: TextSelection.collapsed(offset: 1),
        ),
      );
      await sendUndo(tester);
      expect(
        controller.value,
        const TextEditingValue(
          selection: TextSelection.collapsed(offset: 0),
        ),
      );
      await sendUndo(tester);
      expect(
        controller.value,
        const TextEditingValue(
          selection: TextSelection.collapsed(offset: 0),
        ),
      );
      await sendRedo(tester);
      expect(
        controller.value,
        const TextEditingValue(
          text: '1',
          selection: TextSelection.collapsed(offset: 1),
        ),
      );
      await sendRedo(tester);
      expect(
        controller.value,
        const TextEditingValue(
          text: '1',
          selection: TextSelection.collapsed(offset: 1),
        ),
      );
    // On web, these keyboard shortcuts are handled by the browser.
    }, variant: TargetPlatformVariant.all(), skip: kIsWeb); // [intended]

    testWidgets('inside EditableText, autofocus', (WidgetTester tester) async {
      final TextEditingController controller = TextEditingController();
      await tester.pumpWidget(
        MaterialApp(
          home: EditableText(
            autofocus: true,
            controller: controller,
            focusNode: FocusNode(),
            style: textStyle,
            cursorColor: Colors.blue,
            backgroundCursorColor: Colors.grey,
            cursorOpacityAnimates: true,
            autofillHints: null,
          ),
        ),
      );

      expect(
        controller.value,
        const TextEditingValue(
          selection: TextSelection.collapsed(offset: 0),
        ),
      );
      await tester.pump();
      expect(
        controller.value,
        const TextEditingValue(
          selection: TextSelection.collapsed(offset: 0),
        ),
      );
      // Wait for the throttling.
      await tester.pump(const Duration(milliseconds: 500));
      await tester.enterText(find.byType(EditableText), '1');
      await tester.pump(const Duration(milliseconds: 500));
      expect(
        controller.value,
        const TextEditingValue(
          text: '1',
          selection: TextSelection.collapsed(offset: 1),
        ),
      );
      await sendUndo(tester);
      expect(
        controller.value,
        const TextEditingValue(
          selection: TextSelection.collapsed(offset: 0),
        ),
      );
      await sendUndo(tester);
      expect(
        controller.value,
        const TextEditingValue(
          selection: TextSelection.collapsed(offset: 0),
        ),
      );
      await sendRedo(tester);
      expect(
        controller.value,
        const TextEditingValue(
          text: '1',
          selection: TextSelection.collapsed(offset: 1),
        ),
      );
      await sendRedo(tester);
      expect(
        controller.value,
        const TextEditingValue(
          text: '1',
          selection: TextSelection.collapsed(offset: 1),
        ),
      );
    }, variant: TargetPlatformVariant.all(), skip: kIsWeb); // [intended]
  });

  testWidgets('pasting with the keyboard collapses the selection and places it after the pasted content', (WidgetTester tester) async {
    Future<void> testPasteSelection(WidgetTester tester, _VoidFutureCallback paste) async {
      final TextEditingController controller = TextEditingController();
      await tester.pumpWidget(
        MaterialApp(
          home: EditableText(
            backgroundCursorColor: Colors.grey,
            controller: controller,
            focusNode: focusNode,
            style: textStyle,
            cursorColor: cursorColor,
            selectionControls: materialTextSelectionControls,
          ),
        ),
      );

      await tester.pump();
      expect(controller.text, '');

      await tester.enterText(find.byType(EditableText), '12345');
      expect(controller.value, const TextEditingValue(
        text: '12345',
        selection: TextSelection.collapsed(offset: 5),
      ));

      await sendKeys(
        tester,
        <LogicalKeyboardKey>[
          LogicalKeyboardKey.arrowLeft,
          LogicalKeyboardKey.arrowLeft,
          LogicalKeyboardKey.arrowLeft,
          LogicalKeyboardKey.arrowLeft,
          LogicalKeyboardKey.arrowLeft,
        ],
        shift: true,
        targetPlatform: defaultTargetPlatform,
      );

      expect(controller.value, const TextEditingValue(
        text: '12345',
        selection: TextSelection(baseOffset: 5, extentOffset: 0),
      ));

      await sendKeys(
        tester,
        <LogicalKeyboardKey>[
          LogicalKeyboardKey.keyC,
        ],
        shortcutModifier: true,
        targetPlatform: defaultTargetPlatform,
      );
      expect(controller.value, const TextEditingValue(
        text: '12345',
        selection: TextSelection(baseOffset: 5, extentOffset: 0),
      ));

      // Pasting content of equal length, reversed selection.
      await paste();
      expect(controller.value, const TextEditingValue(
        text: '12345',
        selection: TextSelection.collapsed(offset: 5),
      ));

      // Pasting content of longer length, forward selection.
      await sendKeys(
        tester,
        <LogicalKeyboardKey>[
          LogicalKeyboardKey.arrowLeft,
        ],
        targetPlatform: defaultTargetPlatform,
      );
      await sendKeys(
        tester,
        <LogicalKeyboardKey>[
          LogicalKeyboardKey.arrowRight,
        ],
        shift: true,
        targetPlatform: defaultTargetPlatform,
      );
      expect(controller.value, const TextEditingValue(
        text: '12345',
        selection: TextSelection(baseOffset: 4, extentOffset: 5),
      ));
      await paste();
      expect(controller.value, const TextEditingValue(
        text: '123412345',
        selection: TextSelection.collapsed(offset: 9),
      ));

      // Pasting content of shorter length, forward selection.
      await sendKeys(
        tester,
        <LogicalKeyboardKey>[
          LogicalKeyboardKey.keyA,
        ],
        shortcutModifier: true,
        targetPlatform: defaultTargetPlatform,
      );
      expect(controller.value, const TextEditingValue(
        text: '123412345',
        selection: TextSelection(baseOffset: 0, extentOffset: 9),
      ));
      await paste();
      // Pump to allow postFrameCallbacks to finish before dispose.
      await tester.pump();
      expect(controller.value, const TextEditingValue(
        text: '12345',
        selection: TextSelection.collapsed(offset: 5),
      ));
    }

    // Test pasting with the keyboard.
    await testPasteSelection(tester, () {
      return sendKeys(
        tester,
        <LogicalKeyboardKey>[
          LogicalKeyboardKey.keyV,
        ],
        shortcutModifier: true,
        targetPlatform: defaultTargetPlatform,
      );
    });

    // Test pasting with the toolbar.
    await testPasteSelection(tester, () async {
      final EditableTextState state =
          tester.state<EditableTextState>(find.byType(EditableText));
      expect(state.showToolbar(), true);
      await tester.pumpAndSettle();
      expect(find.text('Paste'), findsOneWidget);
      return tester.tap(find.text('Paste'));
    });
  }, skip: kIsWeb); // [intended]

  // Regression test for https://github.com/flutter/flutter/issues/98322.
  testWidgets('EditableText consumes ActivateIntent and ButtonActivateIntent', (WidgetTester tester) async {
    bool receivedIntent = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Actions(
          actions: <Type, Action<Intent>>{
            ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) {
              receivedIntent = true;
              return;
            }),
            ButtonActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) {
              receivedIntent = true;
              return;
            }),
          },
          child: EditableText(
            autofocus: true,
            backgroundCursorColor: Colors.blue,
            controller: controller,
            focusNode: focusNode,
            style: textStyle,
            cursorColor: cursorColor,
          ),
        ),
      ),
    );

    await tester.pump();
    expect(focusNode.hasFocus, isTrue);

    // ActivateIntent, which is triggered by space and enter in WidgetsApp, is
    // consumed by EditableText so that the space/enter reach the IME.
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(receivedIntent, isFalse);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(receivedIntent, isFalse);
  });

  // Regression test for https://github.com/flutter/flutter/issues/100585.
  testWidgets('can paste and remove field', (WidgetTester tester) async {
    final TextEditingController controller = TextEditingController(text: 'text');
    late StateSetter setState;
    bool showField = true;
    final _CustomTextSelectionControls controls = _CustomTextSelectionControls(
      onPaste: () {
        setState(() {
          showField = false;
        });
      },
    );
    await tester.pumpWidget(MaterialApp(
      home: StatefulBuilder(
        builder: (BuildContext context, StateSetter stateSetter) {
          setState = stateSetter;
          if (!showField) {
            return const Placeholder();
          }
          return EditableText(
            backgroundCursorColor: Colors.grey,
            controller: controller,
            focusNode: focusNode,
            style: textStyle,
            cursorColor: cursorColor,
            selectionControls: controls,
          );
        },
      ),
    ));

    await tester.tap(find.byType(EditableText));
    await tester.pump();

    final EditableTextState state =
        tester.state<EditableTextState>(find.byType(EditableText));

    await tester.longPress(find.byType(EditableText));
    await tester.pump();
    expect(state.showToolbar(), isTrue);
    await tester.pumpAndSettle();
    expect(find.text('Paste'), findsOneWidget);

    await tester.tap(find.text('Paste'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), null);
  // On web, the text selection toolbar paste button is handled by the browser.
  }, skip: kIsWeb); // [intended]

  // Regression test for https://github.com/flutter/flutter/issues/100585.
  testWidgets('can cut and remove field', (WidgetTester tester) async {
    final TextEditingController controller = TextEditingController(text: 'text');
    late StateSetter setState;
    bool showField = true;
    final _CustomTextSelectionControls controls = _CustomTextSelectionControls(
      onCut: () {
        setState(() {
          showField = false;
        });
      },
    );
    await tester.pumpWidget(MaterialApp(
      home: StatefulBuilder(
        builder: (BuildContext context, StateSetter stateSetter) {
          setState = stateSetter;
          if (!showField) {
            return const Placeholder();
          }
          return EditableText(
            backgroundCursorColor: Colors.grey,
            controller: controller,
            focusNode: focusNode,
            style: textStyle,
            cursorColor: cursorColor,
            selectionControls: controls,
          );
        },
      ),
    ));

    await tester.tap(find.byType(EditableText));
    await tester.pump();

    final EditableTextState state =
        tester.state<EditableTextState>(find.byType(EditableText));

    await tester.tapAt(textOffsetToPosition(tester, 2));
    state.renderEditable.selectWord(cause: SelectionChangedCause.longPress);
    await tester.pump();
    expect(state.showToolbar(), isTrue);
    await tester.pumpAndSettle();
    expect(find.text('Cut'), findsOneWidget);

    await tester.tap(find.text('Cut'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), null);
  // On web, the text selection toolbar cut button is handled by the browser.
  }, skip: kIsWeb); // [intended]

  group('Mac document shortcuts', () {
    testWidgets('ctrl-A/E', (WidgetTester tester) async {
      final String targetPlatformString = defaultTargetPlatform.toString();
      final String platform = targetPlatformString.substring(targetPlatformString.indexOf('.') + 1).toLowerCase();
      final TextEditingController controller = TextEditingController(text: testText);
      controller.selection = const TextSelection(
        baseOffset: 0,
        extentOffset: 0,
        affinity: TextAffinity.upstream,
      );
      await tester.pumpWidget(MaterialApp(
        home: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 400,
            child: EditableText(
              maxLines: 10,
              controller: controller,
              showSelectionHandles: true,
              autofocus: true,
              focusNode: FocusNode(),
              style: Typography.material2018().black.subtitle1!,
              cursorColor: Colors.blue,
              backgroundCursorColor: Colors.grey,
              selectionControls: materialTextSelectionControls,
              keyboardType: TextInputType.text,
              textAlign: TextAlign.right,
            ),
          ),
        ),
      ));

      await tester.pump(); // Wait for autofocus to take effect.

      expect(controller.selection.isCollapsed, isTrue);
      expect(controller.selection.baseOffset, 0);

      await tester.sendKeyDownEvent(
        LogicalKeyboardKey.controlLeft,
        platform: platform,
      );
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.keyE, platform: platform);
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft, platform: platform);
      await tester.pump();

      expect(
        controller.selection,
        equals(
          const TextSelection.collapsed(
            offset: 19,
            affinity: TextAffinity.upstream,
          ),
        ),
        reason: 'on $platform',
      );

      await tester.sendKeyDownEvent(
        LogicalKeyboardKey.controlLeft,
        platform: platform,
      );
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.keyA, platform: platform);
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft, platform: platform);
      await tester.pump();

      expect(
        controller.selection,
        equals(
          const TextSelection.collapsed(
            offset: 0,
          ),
        ),
        reason: 'on $platform',
      );
    },
      skip: kIsWeb, // [intended] on web these keys are handled by the browser.
      variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.iOS,  TargetPlatform.macOS }),
    );

    testWidgets('ctrl-F/B', (WidgetTester tester) async {
      final String targetPlatformString = defaultTargetPlatform.toString();
      final String platform = targetPlatformString.substring(targetPlatformString.indexOf('.') + 1).toLowerCase();
      final TextEditingController controller = TextEditingController(text: testText);
      controller.selection = const TextSelection(
        baseOffset: 0,
        extentOffset: 0,
        affinity: TextAffinity.upstream,
      );
      await tester.pumpWidget(MaterialApp(
        home: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 400,
            child: EditableText(
              maxLines: 10,
              controller: controller,
              showSelectionHandles: true,
              autofocus: true,
              focusNode: FocusNode(),
              style: Typography.material2018().black.subtitle1!,
              cursorColor: Colors.blue,
              backgroundCursorColor: Colors.grey,
              selectionControls: materialTextSelectionControls,
              keyboardType: TextInputType.text,
              textAlign: TextAlign.right,
            ),
          ),
        ),
      ));

      await tester.pump(); // Wait for autofocus to take effect.

      expect(controller.selection.isCollapsed, isTrue);
      expect(controller.selection.baseOffset, 0);

      await tester.sendKeyDownEvent(
        LogicalKeyboardKey.controlLeft,
        platform: platform,
      );
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.keyF, platform: platform);
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft, platform: platform);
      await tester.pump();

      expect(controller.selection.isCollapsed, isTrue);
      expect(controller.selection.baseOffset, 1);

      await tester.sendKeyDownEvent(
        LogicalKeyboardKey.controlLeft,
        platform: platform,
      );
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.keyB, platform: platform);
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft, platform: platform);
      await tester.pump();

      expect(controller.selection.isCollapsed, isTrue);
      expect(controller.selection.baseOffset, 0);
    },
      skip: kIsWeb, // [intended] on web these keys are handled by the browser.
      variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.iOS,  TargetPlatform.macOS }),
    );

    testWidgets('ctrl-N/P', (WidgetTester tester) async {
      final String targetPlatformString = defaultTargetPlatform.toString();
      final String platform = targetPlatformString.substring(targetPlatformString.indexOf('.') + 1).toLowerCase();
      final TextEditingController controller = TextEditingController(text: testText);
      controller.selection = const TextSelection(
        baseOffset: 0,
        extentOffset: 0,
        affinity: TextAffinity.upstream,
      );
      await tester.pumpWidget(MaterialApp(
        home: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 400,
            child: EditableText(
              maxLines: 10,
              controller: controller,
              showSelectionHandles: true,
              autofocus: true,
              focusNode: FocusNode(),
              style: Typography.material2018().black.subtitle1!,
              cursorColor: Colors.blue,
              backgroundCursorColor: Colors.grey,
              selectionControls: materialTextSelectionControls,
              keyboardType: TextInputType.text,
              textAlign: TextAlign.right,
            ),
          ),
        ),
      ));

      await tester.pump(); // Wait for autofocus to take effect.

      expect(controller.selection.isCollapsed, isTrue);
      expect(controller.selection.baseOffset, 0);

      await tester.sendKeyDownEvent(
        LogicalKeyboardKey.controlLeft,
        platform: platform,
      );
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.keyN, platform: platform);
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft, platform: platform);
      await tester.pump();

      expect(controller.selection.isCollapsed, isTrue);
      expect(controller.selection.baseOffset, 20);

      await tester.sendKeyDownEvent(
        LogicalKeyboardKey.controlLeft,
        platform: platform,
      );
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.keyP, platform: platform);
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft, platform: platform);
      await tester.pump();

      expect(controller.selection.isCollapsed, isTrue);
      expect(controller.selection.baseOffset, 0);
    },
      skip: kIsWeb, // [intended] on web these keys are handled by the browser.
      variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.iOS,  TargetPlatform.macOS }),
    );

    group('ctrl-T to transpose', () {
      Future<void> ctrlT(WidgetTester tester, String platform) async {
        await tester.sendKeyDownEvent(
          LogicalKeyboardKey.controlLeft,
          platform: platform,
        );
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.keyT, platform: platform);
        await tester.pump();
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft, platform: platform);
        await tester.pump();
      }

      testWidgets('with normal characters', (WidgetTester tester) async {
        final String targetPlatformString = defaultTargetPlatform.toString();
        final String platform = targetPlatformString.substring(targetPlatformString.indexOf('.') + 1).toLowerCase();

        final TextEditingController controller = TextEditingController(text: testText);
        controller.selection = const TextSelection(
          baseOffset: 0,
          extentOffset: 0,
          affinity: TextAffinity.upstream,
        );
        await tester.pumpWidget(MaterialApp(
          home: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 400,
              child: EditableText(
                maxLines: 10,
                controller: controller,
                showSelectionHandles: true,
                autofocus: true,
                focusNode: FocusNode(),
                style: Typography.material2018().black.subtitle1!,
                cursorColor: Colors.blue,
                backgroundCursorColor: Colors.grey,
                selectionControls: materialTextSelectionControls,
                keyboardType: TextInputType.text,
                textAlign: TextAlign.right,
              ),
            ),
          ),
        ));

        await tester.pump(); // Wait for autofocus to take effect.

        expect(controller.selection.isCollapsed, isTrue);
        expect(controller.selection.baseOffset, 0);

        // ctrl-T does nothing at the start of the field.
        await ctrlT(tester, platform);
        expect(controller.selection.isCollapsed, isTrue);
        expect(controller.selection.baseOffset, 0);

        controller.selection = const TextSelection(
          baseOffset: 1,
          extentOffset: 4,
        );
        await tester.pump();
        expect(controller.selection.isCollapsed, isFalse);
        expect(controller.selection.baseOffset, 1);
        expect(controller.selection.extentOffset, 4);

        // ctrl-T does nothing when the selection isn't collapsed.
        await ctrlT(tester, platform);
        expect(controller.selection.isCollapsed, isFalse);
        expect(controller.selection.baseOffset, 1);
        expect(controller.selection.extentOffset, 4);

        controller.selection = const TextSelection.collapsed(offset: 5);
        await tester.pump();
        expect(controller.selection.isCollapsed, isTrue);
        expect(controller.selection.baseOffset, 5);

        // ctrl-T swaps the previous and next characters when they exist.
        await ctrlT(tester, platform);
        expect(controller.selection.isCollapsed, isTrue);
        expect(controller.selection.baseOffset, 6);
        expect(controller.text.substring(0, 19), 'Now si the time for');

        await ctrlT(tester, platform);
        expect(controller.selection.isCollapsed, isTrue);
        expect(controller.selection.baseOffset, 7);
        expect(controller.text.substring(0, 19), 'Now s ithe time for');

        await ctrlT(tester, platform);
        expect(controller.selection.isCollapsed, isTrue);
        expect(controller.selection.baseOffset, 8);
        expect(controller.text.substring(0, 19), 'Now s tihe time for');

        controller.selection = TextSelection.collapsed(
          offset: controller.text.length,
        );
        await tester.pump();
        expect(controller.selection.isCollapsed, isTrue);
        expect(controller.selection.baseOffset, controller.text.length);
        expect(controller.text.substring(55, 72), 'of their country.');

        await ctrlT(tester, platform);
        expect(controller.selection.isCollapsed, isTrue);
        expect(controller.selection.baseOffset, controller.text.length);
        expect(controller.text.substring(55, 72), 'of their countr.y');
      },
        skip: kIsWeb, // [intended] on web these keys are handled by the browser.
        variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.iOS,  TargetPlatform.macOS }),
      );

      testWidgets('with extended grapheme clusters', (WidgetTester tester) async {
        final String targetPlatformString = defaultTargetPlatform.toString();
        final String platform = targetPlatformString.substring(targetPlatformString.indexOf('.') + 1).toLowerCase();

        final TextEditingController controller = TextEditingController(
          // One extended grapheme cluster of length 8 and one surrogate pair of
          // length 2.
          text: '👨‍👩‍👦😆',
        );
        controller.selection = const TextSelection(
          baseOffset: 0,
          extentOffset: 0,
          affinity: TextAffinity.upstream,
        );
        await tester.pumpWidget(MaterialApp(
          home: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 400,
              child: EditableText(
                maxLines: 10,
                controller: controller,
                showSelectionHandles: true,
                autofocus: true,
                focusNode: FocusNode(),
                style: Typography.material2018().black.subtitle1!,
                cursorColor: Colors.blue,
                backgroundCursorColor: Colors.grey,
                selectionControls: materialTextSelectionControls,
                keyboardType: TextInputType.text,
                textAlign: TextAlign.right,
              ),
            ),
          ),
        ));

        await tester.pump(); // Wait for autofocus to take effect.

        expect(controller.selection.isCollapsed, isTrue);
        expect(controller.selection.baseOffset, 0);

        // ctrl-T does nothing at the start of the field.
        await ctrlT(tester, platform);
        expect(controller.selection.isCollapsed, isTrue);
        expect(controller.selection.baseOffset, 0);
        expect(controller.text, '👨‍👩‍👦😆');

        controller.selection = const TextSelection(
          baseOffset: 8,
          extentOffset: 10,
        );
        await tester.pump();
        expect(controller.selection.isCollapsed, isFalse);
        expect(controller.selection.baseOffset, 8);
        expect(controller.selection.extentOffset, 10);

        // ctrl-T does nothing when the selection isn't collapsed.
        await ctrlT(tester, platform);
        expect(controller.selection.isCollapsed, isFalse);
        expect(controller.selection.baseOffset, 8);
        expect(controller.selection.extentOffset, 10);
        expect(controller.text, '👨‍👩‍👦😆');

        controller.selection = const TextSelection.collapsed(offset: 8);
        await tester.pump();
        expect(controller.selection.isCollapsed, isTrue);
        expect(controller.selection.baseOffset, 8);

        // ctrl-T swaps the previous and next characters when they exist.
        await ctrlT(tester, platform);
        expect(controller.selection.isCollapsed, isTrue);
        expect(controller.selection.baseOffset, 10);
        expect(controller.text, '😆👨‍👩‍👦');

        await ctrlT(tester, platform);
        expect(controller.selection.isCollapsed, isTrue);
        expect(controller.selection.baseOffset, 10);
        expect(controller.text, '👨‍👩‍👦😆');
      },
        skip: kIsWeb, // [intended] on web these keys are handled by the browser.
        variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.iOS,  TargetPlatform.macOS }),
      );
    });
  });
}

class UnsettableController extends TextEditingController {
  @override
  set value(TextEditingValue v) {
    // Do nothing for set, which causes selection to remain as -1, -1.
  }
}

class MockTextFormatter extends TextInputFormatter {
  MockTextFormatter() : formatCallCount = 0, log = <String>[];

  int formatCallCount;
  List<String> log;
  late TextEditingValue lastOldValue;
  late TextEditingValue lastNewValue;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    lastOldValue = oldValue;
    lastNewValue = newValue;
    formatCallCount++;
    log.add('[$formatCallCount]: ${oldValue.text}, ${newValue.text}');
    TextEditingValue finalValue;
    if (newValue.text.length < oldValue.text.length) {
      finalValue = _handleTextDeletion(oldValue, newValue);
    } else {
      finalValue = _formatText(newValue);
    }
    return finalValue;
  }


  TextEditingValue _handleTextDeletion(TextEditingValue oldValue, TextEditingValue newValue) {
    final String result = 'a' * (formatCallCount - 2);
    log.add('[$formatCallCount]: deleting $result');
    return TextEditingValue(text: newValue.text, selection: newValue.selection, composing: newValue.composing);
  }

  TextEditingValue _formatText(TextEditingValue value) {
    final String result = 'a' * formatCallCount * 2;
    log.add('[$formatCallCount]: normal $result');
    return TextEditingValue(text: value.text, selection: value.selection, composing: value.composing);
  }
}

class MockTextSelectionControls extends Fake implements TextSelectionControls {
  @override
  Widget buildToolbar(BuildContext context, Rect globalEditableRegion, double textLineHeight, Offset position, List<TextSelectionPoint> endpoints, TextSelectionDelegate delegate, ClipboardStatusNotifier? clipboardStatus, Offset? lastSecondaryTapDownPosition) {
    return Container();
  }

  @override
  Widget buildHandle(BuildContext context, TextSelectionHandleType type, double textLineHeight, [VoidCallback? onTap]) {
    return Container();
  }

  @override
  Size getHandleSize(double textLineHeight) {
    return Size.zero;
  }

  @override
  Offset getHandleAnchor(TextSelectionHandleType type, double textLineHeight) {
    return Offset.zero;
  }

  bool testCanCut = false;
  bool testCanCopy = false;
  bool testCanPaste = false;

  int cutCount = 0;
  int pasteCount = 0;
  int copyCount = 0;

  // TODO(chunhtai): remove optional parameter once migration is done.
  // https://github.com/flutter/flutter/issues/99360
  @override
  void handleCopy(TextSelectionDelegate delegate, [ClipboardStatusNotifier? clipboardStatus]) {
    copyCount += 1;
  }

  @override
  Future<void> handlePaste(TextSelectionDelegate delegate) async {
    pasteCount += 1;
  }

  // TODO(chunhtai): remove optional parameter once migration is done.
  // https://github.com/flutter/flutter/issues/99360
  @override
  void handleCut(TextSelectionDelegate delegate, [ClipboardStatusNotifier? clipboardStatus]) {
    cutCount += 1;
  }

  @override
  bool canCut(TextSelectionDelegate delegate) {
    return testCanCut;
  }

  @override
  bool canCopy(TextSelectionDelegate delegate) {
    return testCanCopy;
  }

  @override
  bool canPaste(TextSelectionDelegate delegate) {
    return testCanPaste;
  }
}

// Fake text selection controls that call a callback when paste happens.
class _CustomTextSelectionControls extends TextSelectionControls {
  _CustomTextSelectionControls({
    this.onPaste,
    this.onCut,
  });

  static const double _kToolbarContentDistanceBelow = 20.0;
  static const double _kToolbarContentDistance = 8.0;

  final VoidCallback? onPaste;
  final VoidCallback? onCut;

  @override
  Widget buildToolbar(BuildContext context, Rect globalEditableRegion, double textLineHeight, Offset position, List<TextSelectionPoint> endpoints, TextSelectionDelegate delegate, ClipboardStatusNotifier? clipboardStatus, Offset? lastSecondaryTapDownPosition) {
    final Offset selectionMidpoint = position;
    final TextSelectionPoint startTextSelectionPoint = endpoints[0];
    final TextSelectionPoint endTextSelectionPoint = endpoints.length > 1
      ? endpoints[1]
      : endpoints[0];
    final Offset anchorAbove = Offset(
      globalEditableRegion.left + selectionMidpoint.dx,
      globalEditableRegion.top + startTextSelectionPoint.point.dy - textLineHeight - _kToolbarContentDistance
    );
    final Offset anchorBelow = Offset(
      globalEditableRegion.left + selectionMidpoint.dx,
      globalEditableRegion.top + endTextSelectionPoint.point.dy + _kToolbarContentDistanceBelow,
    );
    return _CustomTextSelectionToolbar(
      anchorAbove: anchorAbove,
      anchorBelow: anchorBelow,
      handlePaste: () => handlePaste(delegate),
      handleCut: () => handleCut(delegate),
    );
  }

  @override
  Widget buildHandle(BuildContext context, TextSelectionHandleType type, double textLineHeight, [VoidCallback? onTap]) {
    return Container();
  }

  @override
  Size getHandleSize(double textLineHeight) {
    return Size.zero;
  }

  @override
  Offset getHandleAnchor(TextSelectionHandleType type, double textLineHeight) {
    return Offset.zero;
  }

  @override
  bool canCut(TextSelectionDelegate delegate) {
    return true;
  }

  @override
  bool canPaste(TextSelectionDelegate delegate) {
    return true;
  }

  @override
  Future<void> handlePaste(TextSelectionDelegate delegate) {
    onPaste?.call();
    return super.handlePaste(delegate);
  }

  @override
  void handleCut(TextSelectionDelegate delegate, [ClipboardStatusNotifier? clipboardStatus]) {
    onCut?.call();
    return super.handleCut(delegate, clipboardStatus);
  }
}

// A fake text selection toolbar with only a paste button.
class _CustomTextSelectionToolbar extends StatefulWidget {
  const _CustomTextSelectionToolbar({
    required this.anchorAbove,
    required this.anchorBelow,
    this.handlePaste,
    this.handleCut,
  });

  final Offset anchorAbove;
  final Offset anchorBelow;
  final VoidCallback? handlePaste;
  final VoidCallback? handleCut;

  @override
  _CustomTextSelectionToolbarState createState() => _CustomTextSelectionToolbarState();
}

class _CustomTextSelectionToolbarState extends State<_CustomTextSelectionToolbar> {
  @override
  Widget build(BuildContext context) {
    return TextSelectionToolbar(
      anchorAbove: widget.anchorAbove,
      anchorBelow: widget.anchorBelow,
      toolbarBuilder: (BuildContext context, Widget child) {
        return Container(
          color: Colors.pink,
          child: child,
        );
      },
      children: <Widget>[
        TextSelectionToolbarTextButton(
          padding: TextSelectionToolbarTextButton.getPadding(0, 2),
          onPressed: widget.handleCut,
          child: const Text('Cut'),
        ),
        TextSelectionToolbarTextButton(
          padding: TextSelectionToolbarTextButton.getPadding(1, 2),
          onPressed: widget.handlePaste,
          child: const Text('Paste'),
        ),
      ],
    );
  }
}

class CustomStyleEditableText extends EditableText {
  CustomStyleEditableText({
    super.key,
    required super.controller,
    required super.cursorColor,
    required super.focusNode,
    required super.style,
  }) : super(
          backgroundCursorColor: Colors.grey,
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

class TransformedEditableText extends StatefulWidget {
  const TransformedEditableText({
    super.key,
    required this.offset,
    required this.transformButtonKey,
  });

  final Offset offset;
  final Key transformButtonKey;

  @override
  State<TransformedEditableText> createState() => _TransformedEditableTextState();
}

class _TransformedEditableTextState extends State<TransformedEditableText> {
  bool _isTransformed = false;

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: const MediaQueryData(),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Transform.translate(
              offset: _isTransformed ? widget.offset : Offset.zero,
              child: EditableText(
                controller: TextEditingController(),
                focusNode: FocusNode(),
                style: Typography.material2018().black.subtitle1!,
                cursorColor: Colors.blue,
                backgroundCursorColor: Colors.grey,
              ),
            ),
            ElevatedButton(
              key: widget.transformButtonKey,
              onPressed: () {
                setState(() {
                  _isTransformed = !_isTransformed;
                });
              },
              child: const Text('Toggle Transform'),
            ),
          ],
        ),
      ),
    );
  }
}

class NoImplicitScrollPhysics extends AlwaysScrollableScrollPhysics {
  const NoImplicitScrollPhysics({ super.parent });

  @override
  bool get allowImplicitScrolling => false;

  @override
  NoImplicitScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return NoImplicitScrollPhysics(parent: buildParent(ancestor));
  }
}

class SkipPainting extends SingleChildRenderObjectWidget {
  const SkipPainting({ super.key, required Widget super.child });

  @override
  SkipPaintingRenderObject createRenderObject(BuildContext context) => SkipPaintingRenderObject();
}

class SkipPaintingRenderObject extends RenderProxyBox {
  @override
  void paint(PaintingContext context, Offset offset) { }
}

class _AccentColorTextEditingController extends TextEditingController {
  _AccentColorTextEditingController(String text) : super(text: text);

  @override
  TextSpan buildTextSpan({required BuildContext context, TextStyle? style, required bool withComposing}) {
    final Color color = Theme.of(context).colorScheme.secondary;
    return super.buildTextSpan(context: context, style: TextStyle(color: color), withComposing: withComposing);
  }
}

class _TestScrollController extends ScrollController {
  bool get attached => hasListeners;
}
