// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.


import 'dart:convert' show utf8;
import 'dart:convert' show jsonDecode;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TextSelection', () {
    test('The invalid selection is a singleton', () {
      const TextSelection invalidSelection1 = TextSelection(
        baseOffset: -1,
        extentOffset: 0,
        affinity: TextAffinity.downstream,
        isDirectional: true,
      );
      const TextSelection invalidSelection2 = TextSelection(baseOffset: 123,
        extentOffset: -1,
        affinity: TextAffinity.upstream,
        isDirectional: false,
      );
      expect(invalidSelection1, invalidSelection2);
      expect(invalidSelection1.hashCode, invalidSelection2.hashCode);
    });

    test('TextAffinity does not affect equivalence when the selection is not collapsed', () {
      const TextSelection selection1 = TextSelection(
        baseOffset: 1,
        extentOffset: 2,
        affinity: TextAffinity.downstream,
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

      fakeTextChannel.incoming!(const MethodCall('TextInputClient.requestExistingInputState', null));

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

      fakeTextChannel.incoming!(const MethodCall('TextInputClient.requestExistingInputState', null));

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
      expect(configuration.autocorrect, true);
      expect(configuration.actionLabel, null);
      expect(configuration.textCapitalization, TextCapitalization.none);
      expect(configuration.keyboardAppearance, Brightness.light);
    });

    test('text serializes to JSON', () async {
      const TextInputConfiguration configuration = TextInputConfiguration(
        inputType: TextInputType.text,
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
      await ServicesBinding.instance!.defaultBinaryMessenger.handlePlatformMessage(
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
      await ServicesBinding.instance!.defaultBinaryMessenger.handlePlatformMessage(
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
      await ServicesBinding.instance!.defaultBinaryMessenger.handlePlatformMessage(
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
      await ServicesBinding.instance!.defaultBinaryMessenger.handlePlatformMessage(
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
      await ServicesBinding.instance!.defaultBinaryMessenger.handlePlatformMessage(
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
      await ServicesBinding.instance!.defaultBinaryMessenger.handlePlatformMessage(
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
      await ServicesBinding.instance!.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/textinput',
        messageBytes,
        (ByteData? _) {},
      );

      expect(client.latestMethodCall, 'showAutocorrectionPromptRect');
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

  TextInputConfiguration get configuration => const TextInputConfiguration();
}

class FakeTextChannel implements MethodChannel {
  FakeTextChannel(this.outgoing) : assert(outgoing != null);

  Future<dynamic> Function(MethodCall) outgoing;
  Future<void> Function(MethodCall)? incoming;

  List<MethodCall> outgoingCalls = <MethodCall>[];

  @override
  BinaryMessenger get binaryMessenger => throw UnimplementedError();

  @override
  MethodCodec get codec => const JSONMethodCodec();

  @override
  Future<List<T>> invokeListMethod<T>(String method, [dynamic arguments]) => throw UnimplementedError();

  @override
  Future<Map<K, V>> invokeMapMethod<K, V>(String method, [dynamic arguments]) => throw UnimplementedError();

  @override
  Future<T> invokeMethod<T>(String method, [dynamic arguments]) async {
    final MethodCall call = MethodCall(method, arguments);
    outgoingCalls.add(call);
    return await outgoing(call) as T;
  }

  @override
  String get name => 'flutter/textinput';

  @override
  void setMethodCallHandler(Future<void> Function(MethodCall call)? handler) => incoming = handler;

  void validateOutgoingMethodCalls(List<MethodCall> calls) {
    expect(outgoingCalls.length, calls.length);
    bool hasError = false;
    for (int i = 0; i < calls.length; i++) {
      final ByteData outgoingData = codec.encodeMethodCall(outgoingCalls[i]);
      final ByteData expectedData = codec.encodeMethodCall(calls[i]);
      final String outgoingString = utf8.decode(outgoingData.buffer.asUint8List());
      final String expectedString = utf8.decode(expectedData.buffer.asUint8List());

      if (outgoingString != expectedString) {
        print(
          'Index $i did not match:\n'
          '  actual:   $outgoingString\n'
          '  expected: $expectedString',
        );
        hasError = true;
      }
    }
    if (hasError) {
      fail('Calls did not match.');
    }
  }
}
