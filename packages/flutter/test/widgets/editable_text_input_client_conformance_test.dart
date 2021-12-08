// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';
import 'editable_text_test.dart' show matchesMethodCall;

final FocusNode focusNode = FocusNode(debugLabel: 'EditableText Node');
final FocusScopeNode focusScopeNode = FocusScopeNode(debugLabel: 'EditableText Scope Node');
const TextStyle textStyle = TextStyle();
const Color red = Color.fromARGB(0xFF, 0xFF, 0x00, 0x00);

void main() {
  final TextEditingController controller = TextEditingController();
  final EditableText editableText = EditableText(
    backgroundCursorColor: const Color.fromARGB(0xFF, 0xFF, 0xFF, 0xFF),
    controller: controller,
    focusNode: focusNode,
    style: textStyle,
    cursorColor: red,
  );

  group('responds to reconnect requests correctly', () {
    tearDown(() { controller.text = ''; });

    testWidgets('The client reconnects and sends its editing state', (WidgetTester tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: editableText,
          ),
        ),
      );
      focusNode.requestFocus();
      await tester.idle();
      await tester.enterText(find.byWidget(editableText), 'test text');
      tester.testTextInput.log.clear();

      TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger.handlePlatformMessage(
        SystemChannels.textInput.name,
        SystemChannels.textInput.codec.encodeMethodCall(
          const MethodCall('TextInputClient.requestExistingInputState'),
        ),
        (ByteData? data) { /* response from framework is discarded */ },
      );

      expect(tester.testTextInput.log, containsAllInOrder(<Matcher>[
        matchesMethodCall('TextInput.setClient'),
        matchesMethodCall('TextInput.setEditingState', args: containsPair('text', 'test text')),
      ]));
    });

    testWidgets('do not reconnect if there is no connected client', (WidgetTester tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: editableText,
          ),
        ),
      );
      focusNode.requestFocus();
      await tester.idle();
      await tester.enterText(find.byWidget(editableText), 'test text');
      focusNode.unfocus();
      await tester.idle();
      tester.testTextInput.log.clear();

      TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger.handlePlatformMessage(
        SystemChannels.textInput.name,
        SystemChannels.textInput.codec.encodeMethodCall(
          const MethodCall('TextInputClient.requestExistingInputState'),
        ),
        (ByteData? data) { /* response from framework is discarded */ },
      );

      expect(tester.testTextInput.log, isEmpty);
    });

    testWidgets('Client must reuse the previous connection', (WidgetTester tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: editableText,
          ),
        ),
      );
      focusNode.requestFocus();
      await tester.idle();
      await tester.enterText(find.byWidget(editableText), 'test text');

      // Get the initial client/connection ID.
      final List<dynamic> args = tester.testTextInput.log
        .lastWhere((MethodCall methodCall) => methodCall.method == 'TextInput.setClient')
        .arguments as List<dynamic>;
      final int clientID = args[0] as int;
      tester.testTextInput.log.clear();

      TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger.handlePlatformMessage(
        SystemChannels.textInput.name,
        SystemChannels.textInput.codec.encodeMethodCall(
          const MethodCall('TextInputClient.requestExistingInputState'),
        ),
        (ByteData? data) { /* response from framework is discarded */ },
      );

      final List<dynamic> newArgs = tester.testTextInput.log
        .firstWhere((MethodCall methodCall) => methodCall.method == 'TextInput.setClient').arguments as List<dynamic>;
      expect(newArgs[0], clientID);
    });
  });

  group('Handles autofill', () {
    testWidgets('when there is no explicit AutofillScope', (WidgetTester tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: editableText,
          ),
        ),
      );
      focusNode.requestFocus();
      await tester.idle();
      final String autofillId = tester.state<EditableTextState>(find.byWidget(editableText)).autofillId;
      tester.testTextInput.log.clear();

      const TextEditingValue newValue = TextEditingValue(text: 'new text', selection: TextSelection.collapsed(offset: 8));
      TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger.handlePlatformMessage(
        SystemChannels.textInput.name,
        SystemChannels.textInput.codec.encodeMethodCall(
          MethodCall(
            'TextInputClient.updateEditingStateWithTag',
            <dynamic>[<String, dynamic>{ autofillId: newValue.toJSON() }],
          ),
        ),
        (ByteData? data) { /* response from framework is discarded */ },
      );

      expect(controller.value, newValue);
    });
  });

  testWidgets('editing state can be updated', (WidgetTester tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: editableText,
        ),
      ),
    );
    focusNode.requestFocus();
    await tester.idle();

    const TextEditingValue newValue = TextEditingValue(text: 'new text', selection: TextSelection.collapsed(offset: 8));
    tester.testTextInput.enterText('new text');

    expect(controller.value, newValue);
  });

  testWidgets('editing state can be updated via deltas', (WidgetTester tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: editableText,
        ),
      ),
    );
    focusNode.requestFocus();
    await tester.idle();
    const String jsonDelta = '{'
        '"oldText": "",'
        ' "deltaText": "let there be text",'
        ' "deltaStart": 0,'
        ' "deltaEnd": 0,'
        ' "selectionBase": 17,'
        ' "selectionExtent": 17,'
        ' "selectionAffinity" : "TextAffinity.downstream" ,'
        ' "selectionIsDirectional": false,'
        ' "composingBase": -1,'
        ' "composingExtent": -1}';


    TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger.handlePlatformMessage(
      SystemChannels.textInput.name,
      SystemChannels.textInput.codec.encodeMethodCall(
        MethodCall(
          'TextInputClient.updateEditingStateWithDeltas',
          <dynamic>[-1, <String, dynamic>{ 'deltas' :  <dynamic>[jsonDecode(jsonDelta)] }],
        ),
      ),
      (ByteData? data) { /* response from framework is discarded */ },
    );

    expect(controller.value.text, 'let there be text');
  });

  testWidgets('performAction is handled', (WidgetTester tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: editableText,
        ),
      ),
    );
    focusNode.requestFocus();
    await tester.idle();

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.idle();
    expect(focusNode.hasFocus, isFalse);
  });

  testWidgets('performAction is handled', (WidgetTester tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: editableText,
        ),
      ),
    );
    focusNode.requestFocus();
    await tester.idle();

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.idle();
    expect(focusNode.hasFocus, isFalse);
  });

  group('private or unrecognized command', () {
    testWidgets('Android private command invokes the user callback', (WidgetTester tester) async {
      String? lastCommand;
      Map<String, dynamic>? lastData;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: EditableText(
              backgroundCursorColor: const Color.fromARGB(0xFF, 0xFF, 0xFF, 0xFF),
              controller: controller,
              focusNode: focusNode,
              style: textStyle,
              cursorColor: red,
              onAppPrivateCommand: (String command, Map<String, dynamic> data) {
                lastCommand = command;
                lastData = data;
              },
            ),
          ),
        ),
      );
      focusNode.requestFocus();
      await tester.idle();

      TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger.handlePlatformMessage(
        SystemChannels.textInput.name,
        SystemChannels.textInput.codec.encodeMethodCall(
          const MethodCall(
            'TextInputClient.performPrivateCommand',
            <dynamic>[-1, <String, dynamic>{ 'action' : 'greetings',  'data': <String, dynamic>{ 'hello' : 'world' } }],
          ),
        ),
        (ByteData? data) { /* response from framework is discarded */ },
      );

      expect(lastCommand, 'greetings');
      expect(lastData, <String, dynamic>{ 'hello' : 'world' });
    });

    testWidgets('Unrecognized commands can be handled by Action overrides', (WidgetTester tester) async {
      String? lastCommand;
      Map<String, dynamic>? lastData;
      MethodCall? lastMethodCall;

      await tester.pumpWidget(
        Actions(
          actions: <Type, Action<Intent>>{
            PerformPrivateTextInputCommandIntent: CallbackAction<PerformPrivateTextInputCommandIntent>(
              onInvoke: (PerformPrivateTextInputCommandIntent intent) { lastMethodCall = intent.methodCall; },
            ),
          },
          child: MediaQuery(
            data: const MediaQueryData(),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: EditableText(
                backgroundCursorColor: const Color.fromARGB(0xFF, 0xFF, 0xFF, 0xFF),
                controller: controller,
                focusNode: focusNode,
                style: textStyle,
                cursorColor: red,
                onAppPrivateCommand: (String command, Map<String, dynamic> data) {
                  lastCommand = command;
                  lastData = data;
                },
              ),
            ),
          ),
        ),
      );
      focusNode.requestFocus();
      await tester.idle();

      const MethodCall bogusMethodCall = MethodCall(
        'TextInputClient.someBogusTextInputCommand',
        <dynamic>[-1, <String, dynamic>{ 'action' : 'greetings',  'data': <String, dynamic>{ 'hello' : 'world' } }],
      );
      TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger.handlePlatformMessage(
        SystemChannels.textInput.name,
        SystemChannels.textInput.codec.encodeMethodCall(bogusMethodCall),
        (ByteData? data) { /* response from framework is discarded */ },
      );

      // The method call isn't handled by the overriden method.
      expect(lastCommand, isNull);
      expect(lastData, isNull);
      expect(lastMethodCall?.method, bogusMethodCall.method);
      expect(lastMethodCall?.arguments, bogusMethodCall.arguments);
    });
  });

  testWidgets('updateFloatingCursor is handled', (WidgetTester tester) async {
    controller.value = const TextEditingValue(text: '1234567890', selection: TextSelection(baseOffset: 4, extentOffset: 10));
    addTearDown(() { controller.value = TextEditingValue.empty; });
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: editableText,
        ),
      ),
    );
    focusNode.requestFocus();
    await tester.idle();

    TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger.handlePlatformMessage(
      SystemChannels.textInput.name,
      SystemChannels.textInput.codec.encodeMethodCall(
        const MethodCall(
          'TextInputClient.updateFloatingCursor',
          <dynamic>[-1,  'FloatingCursorDragState.start', <String, dynamic>{ 'X': 0.0, 'Y': 0.0, }],
        ),
      ),
      (ByteData? data) { /* response from framework is discarded */ },
    );
    TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger.handlePlatformMessage(
      SystemChannels.textInput.name,
      SystemChannels.textInput.codec.encodeMethodCall(
        const MethodCall(
          'TextInputClient.updateFloatingCursor',
          <dynamic>[-1,  'FloatingCursorDragState.update', <String, dynamic>{ 'X': -1000.0, 'Y': 0.0, }],
        ),
      ),
      (ByteData? data) { /* response from framework is discarded */ },
    );
    TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger.handlePlatformMessage(
      SystemChannels.textInput.name,
      SystemChannels.textInput.codec.encodeMethodCall(
        const MethodCall(
          'TextInputClient.updateFloatingCursor',
          <dynamic>[-1,  'FloatingCursorDragState.end', <String, dynamic>{ 'X': 0.0, 'Y': 0.0, }],
        ),
      ),
      (ByteData? data) { /* response from framework is discarded */ },
    );

    await tester.pump();
    await tester.pumpAndSettle();
    expect(controller.selection, const TextSelection.collapsed(offset: 0));
  });

  testWidgets('showAutocorrectionPromptRect is handled', (WidgetTester tester) async {
    controller.value = const TextEditingValue(text: '1234567890', selection: TextSelection(baseOffset: 0, extentOffset: 10));
    addTearDown(() { controller.value = TextEditingValue.empty; });
    const Color highlightColor = Color(0x12345678);
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: EditableText(
            backgroundCursorColor: const Color.fromARGB(0xFF, 0xFF, 0xFF, 0xFF),
            controller: controller,
            focusNode: focusNode,
            style: textStyle,
            cursorColor: red,
            autocorrectionTextRectColor: highlightColor,
          ),
        ),
      ),
    );
    focusNode.requestFocus();
    await tester.pumpAndSettle();

    expect(find.byType(EditableText), isNot(paints..rect(color: highlightColor)));

    TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger.handlePlatformMessage(
      SystemChannels.textInput.name,
      SystemChannels.textInput.codec.encodeMethodCall(
        const MethodCall(
          'TextInputClient.showAutocorrectionPromptRect',
          <dynamic>[-1,  0, 10],
        ),
      ),
      (ByteData? data) { /* response from framework is discarded */ },
    );

    await tester.pumpAndSettle();

    expect(find.byType(EditableText), paints..rect(color: highlightColor));
  });

  group('text manipulation intents are handled', () {
    const TextEditingValue initialValue = TextEditingValue(
      text: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut a euismod nibh. Morbi laoreet purus.',
      selection: TextSelection(baseOffset: 30, extentOffset: 34),
    );

    setUp(() { controller.value = initialValue; });
    tearDown(() { controller.value = TextEditingValue.empty; });

    testWidgets('Delete character intents are handled', (WidgetTester tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: editableText,
          ),
        ),
      );
      focusNode.requestFocus();
      await tester.idle();

      TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger.handlePlatformMessage(
        SystemChannels.textInput.name,
        SystemChannels.textInput.codec.encodeMethodCall(
          const MethodCall(
            'TextInputClient.DeleteCharacterIntent',
            <dynamic>[-1,  true],
          ),
        ),
        (ByteData? data) { /* response from framework is discarded */ },
      );
      expect(controller.value, isNot(initialValue));
    });

    testWidgets('Delete word intents are handled', (WidgetTester tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: editableText,
          ),
        ),
      );
      focusNode.requestFocus();
      await tester.idle();

      TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger.handlePlatformMessage(
        SystemChannels.textInput.name,
        SystemChannels.textInput.codec.encodeMethodCall(
          const MethodCall(
            'TextInputClient.DeleteToNextWordBoundaryIntent',
            <dynamic>[-1,  true],
          ),
        ),
        (ByteData? data) { /* response from framework is discarded */ },
      );
      expect(controller.value, isNot(initialValue));
    });

    testWidgets('Delete line intents are handled', (WidgetTester tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: editableText,
          ),
        ),
      );
      focusNode.requestFocus();
      await tester.idle();

      TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger.handlePlatformMessage(
        SystemChannels.textInput.name,
        SystemChannels.textInput.codec.encodeMethodCall(
          const MethodCall(
            'TextInputClient.DeleteToLineBreakIntent',
            <dynamic>[-1,  true],
          ),
        ),
        (ByteData? data) { /* response from framework is discarded */ },
      );
      expect(controller.value, isNot(initialValue));
    });

    testWidgets('horizontal caret movement intents are handled', (WidgetTester tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: editableText,
          ),
        ),
      );
      focusNode.requestFocus();
      await tester.idle();

      TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger.handlePlatformMessage(
        SystemChannels.textInput.name,
        SystemChannels.textInput.codec.encodeMethodCall(
          const MethodCall(
            'TextInputClient.ExtendSelectionByCharacterIntent',
            <dynamic>[-1,  true, true],
          ),
        ),
        (ByteData? data) { /* response from framework is discarded */ },
      );
      expect(controller.value, isNot(initialValue));
      expect(controller.text, initialValue.text);
    });

    testWidgets('horizontal caret word movement intents are handled', (WidgetTester tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: editableText,
          ),
        ),
      );
      focusNode.requestFocus();
      await tester.idle();

      TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger.handlePlatformMessage(
        SystemChannels.textInput.name,
        SystemChannels.textInput.codec.encodeMethodCall(
          const MethodCall(
            'TextInputClient.ExtendSelectionToNextWordBoundaryIntent',
            <dynamic>[-1,  true, true],
          ),
        ),
        (ByteData? data) { /* response from framework is discarded */ },
      );
      expect(controller.value, isNot(initialValue));
      expect(controller.text, initialValue.text);
    });

    testWidgets('horizontal caret word movement intents are handled - variant', (WidgetTester tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: editableText,
          ),
        ),
      );
      focusNode.requestFocus();
      await tester.idle();

      TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger.handlePlatformMessage(
        SystemChannels.textInput.name,
        SystemChannels.textInput.codec.encodeMethodCall(
          const MethodCall(
            'TextInputClient.ExtendSelectionToNextWordBoundaryOrCaretLocationIntent',
            <dynamic>[-1,  true, true],
          ),
        ),
        (ByteData? data) { /* response from framework is discarded */ },
      );
      expect(controller.value, isNot(initialValue));
      expect(controller.text, initialValue.text);
    });

    testWidgets('horizontal caret line movement intents are handled', (WidgetTester tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: editableText,
          ),
        ),
      );
      focusNode.requestFocus();
      await tester.idle();

      TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger.handlePlatformMessage(
        SystemChannels.textInput.name,
        SystemChannels.textInput.codec.encodeMethodCall(
          const MethodCall(
            'TextInputClient.ExtendSelectionToLineBreakIntent',
            <dynamic>[-1,  true, true],
          ),
        ),
        (ByteData? data) { /* response from framework is discarded */ },
      );
      expect(controller.value, isNot(initialValue));
      expect(controller.text, initialValue.text);
    });

    testWidgets('vertical caret movement intents are handled', (WidgetTester tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: editableText,
          ),
        ),
      );
      focusNode.requestFocus();
      await tester.idle();

      TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger.handlePlatformMessage(
        SystemChannels.textInput.name,
        SystemChannels.textInput.codec.encodeMethodCall(
          const MethodCall(
            'TextInputClient.ExtendSelectionVerticallyToAdjacentLineIntent',
            <dynamic>[-1,  true, true],
          ),
        ),
        (ByteData? data) { /* response from framework is discarded */ },
      );
      expect(controller.value, isNot(initialValue));
      expect(controller.text, initialValue.text);
    });

    testWidgets('move to document boundary intents are handled', (WidgetTester tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: editableText,
          ),
        ),
      );
      focusNode.requestFocus();
      await tester.idle();

      TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger.handlePlatformMessage(
        SystemChannels.textInput.name,
        SystemChannels.textInput.codec.encodeMethodCall(
          const MethodCall(
            'TextInputClient.ExtendSelectionToDocumentBoundaryIntent',
            <dynamic>[-1,  true, true],
          ),
        ),
        (ByteData? data) { /* response from framework is discarded */ },
      );
      expect(controller.value, isNot(initialValue));
      expect(controller.text, initialValue.text);
    });
  });
}
