// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.


import 'dart:convert' show jsonDecode;
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'text_input_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TextSelection', () {
    test('The invalid selection is a singleton', () {
      const TextSelection invalidSelection1 = TextSelection(
        baseOffset: -1,
        extentOffset: 0,
        isDirectional: true,
      );
      const TextSelection invalidSelection2 = TextSelection(baseOffset: 123,
        extentOffset: -1,
        affinity: TextAffinity.upstream,
      );
      expect(invalidSelection1, invalidSelection2);
      expect(invalidSelection1.hashCode, invalidSelection2.hashCode);
    });

    test('TextAffinity does not affect equivalence when the selection is not collapsed', () {
      const TextSelection selection1 = TextSelection(
        baseOffset: 1,
        extentOffset: 2,
      );
      const TextSelection selection2 = TextSelection(
        baseOffset: 1,
        extentOffset: 2,
        affinity: TextAffinity.upstream,
      );
      expect(selection1, selection2);
      expect(selection1.hashCode, selection2.hashCode);
    });
  });

  group('TextEditingValue', () {
    group('replaced', () {
      const String testText = 'From a false proposition, anything follows.';

      test('selection deletion', () {
        const TextSelection selection = TextSelection(baseOffset: 5, extentOffset: 13);
        expect(
          const TextEditingValue(text: testText, selection: selection).replaced(selection, ''),
          const TextEditingValue(text:  'From proposition, anything follows.', selection: TextSelection.collapsed(offset: 5)),
        );
      });

      test('reversed selection deletion', () {
        const TextSelection selection = TextSelection(baseOffset: 13, extentOffset: 5);
        expect(
          const TextEditingValue(text: testText, selection: selection).replaced(selection, ''),
          const TextEditingValue(text:  'From proposition, anything follows.', selection: TextSelection.collapsed(offset: 5)),
        );
      });

      test('insert', () {
        const TextSelection selection = TextSelection.collapsed(offset: 5);
        expect(
          const TextEditingValue(text: testText, selection: selection).replaced(selection, 'AA'),
          const TextEditingValue(
            text:  'From AAa false proposition, anything follows.',
            // The caret moves to the end of the text inserted.
            selection: TextSelection.collapsed(offset: 7),
          ),
        );
      });

      test('replace before selection', () {
        const TextSelection selection = TextSelection(baseOffset: 13, extentOffset: 5);
        expect(
          // From |a false |proposition, anything follows.
          // Replace the first whitespace with "AA".
          const TextEditingValue(text: testText, selection: selection).replaced(const TextRange(start: 4, end: 5), 'AA'),
          const TextEditingValue(text:  'FromAAa false proposition, anything follows.', selection: TextSelection(baseOffset: 14, extentOffset: 6)),
        );
      });

      test('replace after selection', () {
        const TextSelection selection = TextSelection(baseOffset: 13, extentOffset: 5);
        expect(
          // From |a false |proposition, anything follows.
          // replace the first "p" with "AA".
          const TextEditingValue(text: testText, selection: selection).replaced(const TextRange(start: 13, end: 14), 'AA'),
          const TextEditingValue(text:  'From a false AAroposition, anything follows.', selection: selection),
        );
      });

      test('replace inside selection - start boundary', () {
        const TextSelection selection = TextSelection(baseOffset: 13, extentOffset: 5);
        expect(
          // From |a false |proposition, anything follows.
          // replace the first "a" with "AA".
          const TextEditingValue(text: testText, selection: selection).replaced(const TextRange(start: 5, end: 6), 'AA'),
          const TextEditingValue(text:  'From AA false proposition, anything follows.', selection: TextSelection(baseOffset: 14, extentOffset: 5)),
        );
      });

      test('replace inside selection - end boundary', () {
        const TextSelection selection = TextSelection(baseOffset: 13, extentOffset: 5);
        expect(
          // From |a false |proposition, anything follows.
          // replace the second whitespace with "AA".
          const TextEditingValue(text: testText, selection: selection).replaced(const TextRange(start: 12, end: 13), 'AA'),
          const TextEditingValue(text:  'From a falseAAproposition, anything follows.', selection: TextSelection(baseOffset: 14, extentOffset: 5)),
        );
      });

      test('delete after selection', () {
        const TextSelection selection = TextSelection(baseOffset: 13, extentOffset: 5);
        expect(
          // From |a false |proposition, anything follows.
          // Delete the first "p".
          const TextEditingValue(text: testText, selection: selection).replaced(const TextRange(start: 13, end: 14), ''),
          const TextEditingValue(text:  'From a false roposition, anything follows.', selection: selection),
        );
      });

      test('delete inside selection - start boundary', () {
        const TextSelection selection = TextSelection(baseOffset: 13, extentOffset: 5);
        expect(
          // From |a false |proposition, anything follows.
          // Delete the first "a".
          const TextEditingValue(text: testText, selection: selection).replaced(const TextRange(start: 5, end: 6), ''),
          const TextEditingValue(text:  'From  false proposition, anything follows.', selection: TextSelection(baseOffset: 12, extentOffset: 5)),
        );
      });

      test('delete inside selection - end boundary', () {
        const TextSelection selection = TextSelection(baseOffset: 13, extentOffset: 5);
        expect(
          // From |a false |proposition, anything follows.
          // Delete the second whitespace.
          const TextEditingValue(text: testText, selection: selection).replaced(const TextRange(start: 12, end: 13), ''),
          const TextEditingValue(text:  'From a falseproposition, anything follows.', selection: TextSelection(baseOffset: 12, extentOffset: 5)),
        );
      });
    });
  });

  group('TextInput message channels', () {
    late FakeTextChannel fakeTextChannel;

    setUp(() {
      fakeTextChannel = FakeTextChannel((MethodCall call) async {});
      TextInput.setChannel(fakeTextChannel);
    });

    tearDown(() {
      TextInputConnection.debugResetId();
      TextInput.setChannel(SystemChannels.textInput);
    });

    test('text input client handler responds to reattach with setClient', () async {
      final FakeTextInputClient client = FakeTextInputClient(const TextEditingValue(text: 'test1'));
      TextInput.attach(client, client.configuration);
      fakeTextChannel.validateOutgoingMethodCalls(<MethodCall>[
        MethodCall('TextInput.setClient', <dynamic>[1, client.configuration.toJson()]),
      ]);

      fakeTextChannel.incoming!(const MethodCall('TextInputClient.requestExistingInputState'));

      expect(fakeTextChannel.outgoingCalls.length, 3);
      fakeTextChannel.validateOutgoingMethodCalls(<MethodCall>[
        // From original attach
        MethodCall('TextInput.setClient', <dynamic>[1, client.configuration.toJson()]),
        // From requestExistingInputState
        MethodCall('TextInput.setClient', <dynamic>[1, client.configuration.toJson()]),
        MethodCall('TextInput.setEditingState', client.currentTextEditingValue.toJSON()),
      ]);
    });

    test('text input client handler responds to reattach with setClient (null TextEditingValue)', () async {
      final FakeTextInputClient client = FakeTextInputClient(TextEditingValue.empty);
      TextInput.attach(client, client.configuration);
      fakeTextChannel.validateOutgoingMethodCalls(<MethodCall>[
        MethodCall('TextInput.setClient', <dynamic>[1, client.configuration.toJson()]),
      ]);

      fakeTextChannel.incoming!(const MethodCall('TextInputClient.requestExistingInputState'));

      expect(fakeTextChannel.outgoingCalls.length, 3);
      fakeTextChannel.validateOutgoingMethodCalls(<MethodCall>[
        // From original attach
        MethodCall('TextInput.setClient', <dynamic>[1, client.configuration.toJson()]),
        // From original attach
        MethodCall('TextInput.setClient', <dynamic>[1, client.configuration.toJson()]),
        // From requestExistingInputState
        const MethodCall(
          'TextInput.setEditingState',
          <String, dynamic>{
            'text': '',
            'selectionBase': -1,
            'selectionExtent': -1,
            'selectionAffinity': 'TextAffinity.downstream',
            'selectionIsDirectional': false,
            'composingBase': -1,
            'composingExtent': -1,
          },
        ),
      ]);
    });
  });

  group('TextInputConfiguration', () {
    tearDown(() {
      TextInputConnection.debugResetId();
    });

    test('sets expected defaults', () {
      const TextInputConfiguration configuration = TextInputConfiguration();
      expect(configuration.inputType, TextInputType.text);
      expect(configuration.readOnly, false);
      expect(configuration.obscureText, false);
      expect(configuration.enableDeltaModel, false);
      expect(configuration.autocorrect, true);
      expect(configuration.actionLabel, null);
      expect(configuration.textCapitalization, TextCapitalization.none);
      expect(configuration.keyboardAppearance, Brightness.light);
    });

    test('text serializes to JSON', () async {
      const TextInputConfiguration configuration = TextInputConfiguration(
        readOnly: true,
        obscureText: true,
        autocorrect: false,
        actionLabel: 'xyzzy',
      );
      final Map<String, dynamic> json = configuration.toJson();
      expect(json['inputType'], <String, dynamic>{
        'name': 'TextInputType.text',
        'signed': null,
        'decimal': null,
      });
      expect(json['readOnly'], true);
      expect(json['obscureText'], true);
      expect(json['autocorrect'], false);
      expect(json['actionLabel'], 'xyzzy');
    });

    test('number serializes to JSON', () async {
      const TextInputConfiguration configuration = TextInputConfiguration(
        inputType: TextInputType.numberWithOptions(decimal: true),
        obscureText: true,
        autocorrect: false,
        actionLabel: 'xyzzy',
      );
      final Map<String, dynamic> json = configuration.toJson();
      expect(json['inputType'], <String, dynamic>{
        'name': 'TextInputType.number',
        'signed': false,
        'decimal': true,
      });
      expect(json['readOnly'], false);
      expect(json['obscureText'], true);
      expect(json['autocorrect'], false);
      expect(json['actionLabel'], 'xyzzy');
    });

    test('basic structure', () async {
      const TextInputType text = TextInputType.text;
      const TextInputType number = TextInputType.number;
      const TextInputType number2 = TextInputType.number;
      const TextInputType signed = TextInputType.numberWithOptions(signed: true);
      const TextInputType signed2 = TextInputType.numberWithOptions(signed: true);
      const TextInputType decimal = TextInputType.numberWithOptions(decimal: true);
      const TextInputType signedDecimal =
        TextInputType.numberWithOptions(signed: true, decimal: true);

      expect(text.toString(), 'TextInputType(name: TextInputType.text, signed: null, decimal: null)');
      expect(number.toString(), 'TextInputType(name: TextInputType.number, signed: false, decimal: false)');
      expect(signed.toString(), 'TextInputType(name: TextInputType.number, signed: true, decimal: false)');
      expect(decimal.toString(), 'TextInputType(name: TextInputType.number, signed: false, decimal: true)');
      expect(signedDecimal.toString(), 'TextInputType(name: TextInputType.number, signed: true, decimal: true)');
      expect(TextInputType.multiline.toString(), 'TextInputType(name: TextInputType.multiline, signed: null, decimal: null)');
      expect(TextInputType.phone.toString(), 'TextInputType(name: TextInputType.phone, signed: null, decimal: null)');
      expect(TextInputType.datetime.toString(), 'TextInputType(name: TextInputType.datetime, signed: null, decimal: null)');
      expect(TextInputType.emailAddress.toString(), 'TextInputType(name: TextInputType.emailAddress, signed: null, decimal: null)');
      expect(TextInputType.url.toString(), 'TextInputType(name: TextInputType.url, signed: null, decimal: null)');
      expect(TextInputType.visiblePassword.toString(), 'TextInputType(name: TextInputType.visiblePassword, signed: null, decimal: null)');
      expect(TextInputType.name.toString(), 'TextInputType(name: TextInputType.name, signed: null, decimal: null)');
      expect(TextInputType.streetAddress.toString(), 'TextInputType(name: TextInputType.address, signed: null, decimal: null)');
      expect(TextInputType.none.toString(), 'TextInputType(name: TextInputType.none, signed: null, decimal: null)');

      expect(text == number, false);
      expect(number == number2, true);
      expect(number == signed, false);
      expect(signed == signed2, true);
      expect(signed == decimal, false);
      expect(signed == signedDecimal, false);
      expect(decimal == signedDecimal, false);

      expect(text.hashCode == number.hashCode, false);
      expect(number.hashCode == number2.hashCode, true);
      expect(number.hashCode == signed.hashCode, false);
      expect(signed.hashCode == signed2.hashCode, true);
      expect(signed.hashCode == decimal.hashCode, false);
      expect(signed.hashCode == signedDecimal.hashCode, false);
      expect(decimal.hashCode == signedDecimal.hashCode, false);

      expect(TextInputType.text.index, 0);
      expect(TextInputType.multiline.index, 1);
      expect(TextInputType.number.index, 2);
      expect(TextInputType.phone.index, 3);
      expect(TextInputType.datetime.index, 4);
      expect(TextInputType.emailAddress.index, 5);
      expect(TextInputType.url.index, 6);
      expect(TextInputType.visiblePassword.index, 7);
      expect(TextInputType.name.index, 8);
      expect(TextInputType.streetAddress.index, 9);
      expect(TextInputType.none.index, 10);

      expect(TextEditingValue.empty.toString(),
          'TextEditingValue(text: \u2524\u251C, selection: ${const TextSelection.collapsed(offset: -1)}, composing: ${TextRange.empty})');
      expect(const TextEditingValue(text: 'Sample Text').toString(),
          'TextEditingValue(text: \u2524Sample Text\u251C, selection: ${const TextSelection.collapsed(offset: -1)}, composing: ${TextRange.empty})');
    });

    test('TextInputClient onConnectionClosed method is called', () async {
      // Assemble a TextInputConnection so we can verify its change in state.
      final FakeTextInputClient client = FakeTextInputClient(const TextEditingValue(text: 'test3'));
      const TextInputConfiguration configuration = TextInputConfiguration();
      TextInput.attach(client, configuration);

      expect(client.latestMethodCall, isEmpty);

      // Send onConnectionClosed message.
      final ByteData? messageBytes = const JSONMessageCodec().encodeMessage(<String, dynamic>{
        'args': <dynamic>[1],
        'method': 'TextInputClient.onConnectionClosed',
      });
      await ServicesBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/textinput',
        messageBytes,
        (ByteData? _) {},
      );

      expect(client.latestMethodCall, 'connectionClosed');
    });

    test('TextInputClient performPrivateCommand method is called', () async {
      // Assemble a TextInputConnection so we can verify its change in state.
      final FakeTextInputClient client = FakeTextInputClient(TextEditingValue.empty);
      const TextInputConfiguration configuration = TextInputConfiguration();
      TextInput.attach(client, configuration);

      expect(client.latestMethodCall, isEmpty);

      // Send performPrivateCommand message.
      final ByteData? messageBytes = const JSONMessageCodec().encodeMessage(<String, dynamic>{
        'args': <dynamic>[
          1,
          jsonDecode('{"action": "actionCommand", "data": {"input_context" : "abcdefg"}}'),
        ],
        'method': 'TextInputClient.performPrivateCommand',
      });
      await ServicesBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/textinput',
        messageBytes,
        (ByteData? _) {},
      );

      expect(client.latestMethodCall, 'performPrivateCommand');
    });

    test('TextInputClient performPrivateCommand method is called with float', () async {
      // Assemble a TextInputConnection so we can verify its change in state.
      final FakeTextInputClient client = FakeTextInputClient(TextEditingValue.empty);
      const TextInputConfiguration configuration = TextInputConfiguration();
      TextInput.attach(client, configuration);

      expect(client.latestMethodCall, isEmpty);

      // Send performPrivateCommand message.
      final ByteData? messageBytes = const JSONMessageCodec().encodeMessage(<String, dynamic>{
        'args': <dynamic>[
          1,
          jsonDecode('{"action": "actionCommand", "data": {"input_context" : 0.5}}'),
        ],
        'method': 'TextInputClient.performPrivateCommand',
      });
      await ServicesBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/textinput',
        messageBytes,
        (ByteData? _) {},
      );

      expect(client.latestMethodCall, 'performPrivateCommand');
    });

    test('TextInputClient performPrivateCommand method is called with CharSequence array', () async {
      // Assemble a TextInputConnection so we can verify its change in state.
      final FakeTextInputClient client = FakeTextInputClient(TextEditingValue.empty);
      const TextInputConfiguration configuration = TextInputConfiguration();
      TextInput.attach(client, configuration);

      expect(client.latestMethodCall, isEmpty);

      // Send performPrivateCommand message.
      final ByteData? messageBytes = const JSONMessageCodec().encodeMessage(<String, dynamic>{
        'args': <dynamic>[
          1,
          jsonDecode('{"action": "actionCommand", "data": {"input_context" : ["abc", "efg"]}}'),
        ],
        'method': 'TextInputClient.performPrivateCommand',
      });
      await ServicesBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/textinput',
        messageBytes,
        (ByteData? _) {},
      );

      expect(client.latestMethodCall, 'performPrivateCommand');
    });

    test('TextInputClient performPrivateCommand method is called with CharSequence', () async {
      // Assemble a TextInputConnection so we can verify its change in state.
      final FakeTextInputClient client = FakeTextInputClient(TextEditingValue.empty);
      const TextInputConfiguration configuration = TextInputConfiguration();
      TextInput.attach(client, configuration);

      expect(client.latestMethodCall, isEmpty);

      // Send performPrivateCommand message.
      final ByteData? messageBytes =
          const JSONMessageCodec().encodeMessage(<String, dynamic>{
        'args': <dynamic>[
          1,
          jsonDecode('{"action": "actionCommand", "data": {"input_context" : "abc"}}'),
        ],
        'method': 'TextInputClient.performPrivateCommand',
      });
      await ServicesBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/textinput',
        messageBytes,
        (ByteData? _) {},
      );

      expect(client.latestMethodCall, 'performPrivateCommand');
    });

    test('TextInputClient performPrivateCommand method is called with float array', () async {
      // Assemble a TextInputConnection so we can verify its change in state.
      final FakeTextInputClient client = FakeTextInputClient(TextEditingValue.empty);
      const TextInputConfiguration configuration = TextInputConfiguration();
      TextInput.attach(client, configuration);

      expect(client.latestMethodCall, isEmpty);

      // Send performPrivateCommand message.
      final ByteData? messageBytes =
          const JSONMessageCodec().encodeMessage(<String, dynamic>{
        'args': <dynamic>[
          1,
          jsonDecode('{"action": "actionCommand", "data": {"input_context" : [0.5, 0.8]}}'),
        ],
        'method': 'TextInputClient.performPrivateCommand',
      });
      await ServicesBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/textinput',
        messageBytes,
        (ByteData? _) {},
      );

      expect(client.latestMethodCall, 'performPrivateCommand');
    });

    test('TextInputClient showAutocorrectionPromptRect method is called', () async {
      // Assemble a TextInputConnection so we can verify its change in state.
      final FakeTextInputClient client = FakeTextInputClient(TextEditingValue.empty);
      const TextInputConfiguration configuration = TextInputConfiguration();
      TextInput.attach(client, configuration);

      expect(client.latestMethodCall, isEmpty);

      // Send onConnectionClosed message.
      final ByteData? messageBytes =
          const JSONMessageCodec().encodeMessage(<String, dynamic>{
        'args': <dynamic>[1, 0, 1],
        'method': 'TextInputClient.showAutocorrectionPromptRect',
      });
      await ServicesBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/textinput',
        messageBytes,
        (ByteData? _) {},
      );

      expect(client.latestMethodCall, 'showAutocorrectionPromptRect');
    });

    test('TextInputClient showToolbar method is called', () async {
      // Assemble a TextInputConnection so we can verify its change in state.
      final FakeTextInputClient client = FakeTextInputClient(TextEditingValue.empty);
      const TextInputConfiguration configuration = TextInputConfiguration();
      TextInput.attach(client, configuration);

      expect(client.latestMethodCall, isEmpty);

      // Send showToolbar message.
      final ByteData? messageBytes =
          const JSONMessageCodec().encodeMessage(<String, dynamic>{
        'args': <dynamic>[1, 0, 1],
        'method': 'TextInputClient.showToolbar',
      });
      await ServicesBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/textinput',
        messageBytes,
        (ByteData? _) {},
      );

      expect(client.latestMethodCall, 'showToolbar');
    });
  });

  group('Scribble interactions', () {
    tearDown(() {
      TextInputConnection.debugResetId();
    });

    test('TextInputClient scribbleInteractionBegan and scribbleInteractionFinished', () async {
      // Assemble a TextInputConnection so we can verify its change in state.
      final FakeTextInputClient client = FakeTextInputClient(TextEditingValue.empty);
      const TextInputConfiguration configuration = TextInputConfiguration();
      final TextInputConnection connection = TextInput.attach(client, configuration);

      expect(connection.scribbleInProgress, false);

      // Send scribbleInteractionBegan message.
      ByteData? messageBytes =
          const JSONMessageCodec().encodeMessage(<String, dynamic>{
        'args': <dynamic>[1, 0, 1],
        'method': 'TextInputClient.scribbleInteractionBegan',
      });
      await ServicesBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/textinput',
        messageBytes,
        (ByteData? _) {},
      );

      expect(connection.scribbleInProgress, true);

      // Send scribbleInteractionFinished message.
      messageBytes =
          const JSONMessageCodec().encodeMessage(<String, dynamic>{
        'args': <dynamic>[1, 0, 1],
        'method': 'TextInputClient.scribbleInteractionFinished',
      });
      await ServicesBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/textinput',
        messageBytes,
        (ByteData? _) {},
      );

      expect(connection.scribbleInProgress, false);
    });

    test('TextInputClient focusElement', () async {
      // Assemble a TextInputConnection so we can verify its change in state.
      final FakeTextInputClient client = FakeTextInputClient(TextEditingValue.empty);
      const TextInputConfiguration configuration = TextInputConfiguration();
      TextInput.attach(client, configuration);

      final FakeScribbleElement targetElement = FakeScribbleElement(elementIdentifier: 'target');
      TextInput.registerScribbleElement(targetElement.elementIdentifier, targetElement);
      final FakeScribbleElement otherElement = FakeScribbleElement(elementIdentifier: 'other');
      TextInput.registerScribbleElement(otherElement.elementIdentifier, otherElement);

      expect(targetElement.latestMethodCall, isEmpty);
      expect(otherElement.latestMethodCall, isEmpty);

      // Send focusElement message.
      final ByteData? messageBytes =
          const JSONMessageCodec().encodeMessage(<String, dynamic>{
        'args': <dynamic>[targetElement.elementIdentifier, 0.0, 0.0],
        'method': 'TextInputClient.focusElement',
      });
      await ServicesBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/textinput',
        messageBytes,
        (ByteData? _) {},
      );

      TextInput.unregisterScribbleElement(targetElement.elementIdentifier);
      TextInput.unregisterScribbleElement(otherElement.elementIdentifier);

      expect(targetElement.latestMethodCall, 'onScribbleFocus');
      expect(otherElement.latestMethodCall, isEmpty);
    });

    test('TextInputClient requestElementsInRect', () async {
      // Assemble a TextInputConnection so we can verify its change in state.
      final FakeTextInputClient client = FakeTextInputClient(TextEditingValue.empty);
      const TextInputConfiguration configuration = TextInputConfiguration();
      TextInput.attach(client, configuration);

      final List<FakeScribbleElement> targetElements = <FakeScribbleElement>[
        FakeScribbleElement(elementIdentifier: 'target1', bounds: const Rect.fromLTWH(0.0, 0.0, 100.0, 100.0)),
        FakeScribbleElement(elementIdentifier: 'target2', bounds: const Rect.fromLTWH(0.0, 100.0, 100.0, 100.0)),
      ];
      final List<FakeScribbleElement> otherElements = <FakeScribbleElement>[
        FakeScribbleElement(elementIdentifier: 'other1', bounds: const Rect.fromLTWH(100.0, 0.0, 100.0, 100.0)),
        FakeScribbleElement(elementIdentifier: 'other2', bounds: const Rect.fromLTWH(100.0, 100.0, 100.0, 100.0)),
      ];

      void registerElements(FakeScribbleElement element) => TextInput.registerScribbleElement(element.elementIdentifier, element);
      void unregisterElements(FakeScribbleElement element) => TextInput.unregisterScribbleElement(element.elementIdentifier);

      <FakeScribbleElement>[...targetElements, ...otherElements].forEach(registerElements);

      // Send requestElementsInRect message.
      final ByteData? messageBytes =
          const JSONMessageCodec().encodeMessage(<String, dynamic>{
        'args': <dynamic>[0.0, 50.0, 50.0, 100.0],
        'method': 'TextInputClient.requestElementsInRect',
      });
      ByteData? responseBytes;
      await ServicesBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/textinput',
        messageBytes,
        (ByteData? response) {
          responseBytes = response;
        },
      );

      <FakeScribbleElement>[...targetElements, ...otherElements].forEach(unregisterElements);

      final List<List<dynamic>> responses = (const JSONMessageCodec().decodeMessage(responseBytes) as List<dynamic>).cast<List<dynamic>>();
      expect(responses.first.length, 2);
      expect(responses.first.first, containsAllInOrder(<dynamic>[targetElements.first.elementIdentifier, 0.0, 0.0, 100.0, 100.0]));
      expect(responses.first.last, containsAllInOrder(<dynamic>[targetElements.last.elementIdentifier, 0.0, 100.0, 100.0, 100.0]));
    });
  });

  test('TextEditingValue.isComposingRangeValid', () async {
    // The composing range is empty.
    expect(TextEditingValue.empty.isComposingRangeValid, isFalse);

    expect(
      const TextEditingValue(text: 'test', composing: TextRange(start: 1, end: 0)).isComposingRangeValid,
      isFalse,
    );

    // The composing range is out of range for the text.
    expect(
      const TextEditingValue(text: 'test', composing: TextRange(start: 1, end: 5)).isComposingRangeValid,
      isFalse,
    );

    // The composing range is out of range for the text.
    expect(
      const TextEditingValue(text: 'test', composing: TextRange(start: -1, end: 4)).isComposingRangeValid,
      isFalse,
    );

    expect(
      const TextEditingValue(text: 'test', composing: TextRange(start: 1, end: 4)).isComposingRangeValid,
      isTrue,
    );
  });
}

class FakeTextInputClient implements TextInputClient {
  FakeTextInputClient(this.currentTextEditingValue);

  String latestMethodCall = '';

  @override
  TextEditingValue currentTextEditingValue;

  @override
  AutofillScope? get currentAutofillScope => null;

  @override
  void performAction(TextInputAction action) {
    latestMethodCall = 'performAction';
  }

  @override
  void performPrivateCommand(String action, Map<String, dynamic> data) {
    latestMethodCall = 'performPrivateCommand';
  }

  @override
  void updateEditingValue(TextEditingValue value) {
    latestMethodCall = 'updateEditingValue';
  }

  @override
  void updateFloatingCursor(RawFloatingCursorPoint point) {
    latestMethodCall = 'updateFloatingCursor';
  }

  @override
  void connectionClosed() {
    latestMethodCall = 'connectionClosed';
  }

  @override
  void showAutocorrectionPromptRect(int start, int end) {
    latestMethodCall = 'showAutocorrectionPromptRect';
  }

  @override
  void showToolbar() {
    latestMethodCall = 'showToolbar';
  }

  TextInputConfiguration get configuration => const TextInputConfiguration();

  @override
  void insertTextPlaceholder(Size size) {
    latestMethodCall = 'insertTextPlaceholder';
  }

  @override
  void removeTextPlaceholder() {
    latestMethodCall = 'removeTextPlaceholder';
  }
}
