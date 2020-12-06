// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:convert' show utf8;
import 'dart:convert' show jsonDecode;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart' show TestWidgetsFlutterBinding;
import '../flutter_test_alternative.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TextInput message channels', () {
    FakeTextChannel fakeTextChannel;

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

      fakeTextChannel.incoming(const MethodCall('TextInputClient.requestExistingInputState', null));

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
      final FakeTextInputClient client = FakeTextInputClient(null);
      TextInput.attach(client, client.configuration);
      fakeTextChannel.validateOutgoingMethodCalls(<MethodCall>[
        MethodCall('TextInput.setClient', <dynamic>[1, client.configuration.toJson()]),
      ]);

      fakeTextChannel.incoming(const MethodCall('TextInputClient.requestExistingInputState', null));

      expect(fakeTextChannel.outgoingCalls.length, 2);
      fakeTextChannel.validateOutgoingMethodCalls(<MethodCall>[
        // From original attach
        MethodCall('TextInput.setClient', <dynamic>[1, client.configuration.toJson()]),
        // From requestExistingInputState
        MethodCall('TextInput.setClient', <dynamic>[1, client.configuration.toJson()]),
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
      const TextInputType number2 = TextInputType.numberWithOptions();
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
    });

    test('TextInputClient onConnectionClosed method is called', () async {
      // Assemble a TextInputConnection so we can verify its change in state.
      final FakeTextInputClient client = FakeTextInputClient(const TextEditingValue(text: 'test3'));
      const TextInputConfiguration configuration = TextInputConfiguration();
      TextInput.attach(client, configuration);

      expect(client.latestMethodCall, isEmpty);

      // Send onConnectionClosed message.
      final ByteData messageBytes = const JSONMessageCodec().encodeMessage(<String, dynamic>{
        'args': <dynamic>[1],
        'method': 'TextInputClient.onConnectionClosed',
      });
      await ServicesBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/textinput',
        messageBytes,
        (ByteData _) {},
      );

      expect(client.latestMethodCall, 'connectionClosed');
    });

    test('TextInputClient performPrivateCommand method is called', () async {
      // Assemble a TextInputConnection so we can verify its change in state.
      final FakeTextInputClient client = FakeTextInputClient(null);
      const TextInputConfiguration configuration = TextInputConfiguration();
      TextInput.attach(client, configuration);

      expect(client.latestMethodCall, isEmpty);

      // Send performPrivateCommand message.
      final ByteData messageBytes = const JSONMessageCodec().encodeMessage(<String, dynamic>{
        'args': <dynamic>[
          1,
          jsonDecode(
              '{"action": "actionCommand", "data": {\"input_context\" : \"abcdefg\"}}')
        ],
        'method': 'TextInputClient.performPrivateCommand',
      });
      await ServicesBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/textinput',
        messageBytes,
        (ByteData _) {},
      );

      expect(client.latestMethodCall, 'performPrivateCommand');
    });

    test('TextInputClient performPrivateCommand method is called with float',
        () async {
      // Assemble a TextInputConnection so we can verify its change in state.
      final FakeTextInputClient client = FakeTextInputClient(null);
      const TextInputConfiguration configuration = TextInputConfiguration();
      TextInput.attach(client, configuration);

      expect(client.latestMethodCall, isEmpty);

      // Send performPrivateCommand message.
      final ByteData messageBytes = const JSONMessageCodec().encodeMessage(<String, dynamic>{
        'args': <dynamic>[
          1,
          jsonDecode(
              '{"action": "actionCommand", "data": {\"input_context\" : 0.5}}')
        ],
        'method': 'TextInputClient.performPrivateCommand',
      });
      await ServicesBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/textinput',
        messageBytes,
        (ByteData _) {},
      );

      expect(client.latestMethodCall, 'performPrivateCommand');
    });

    test(
        'TextInputClient performPrivateCommand method is called with CharSequence array',
        () async {
      // Assemble a TextInputConnection so we can verify its change in state.
      final FakeTextInputClient client = FakeTextInputClient(null);
      const TextInputConfiguration configuration = TextInputConfiguration();
      TextInput.attach(client, configuration);

      expect(client.latestMethodCall, isEmpty);

      // Send performPrivateCommand message.
      final ByteData messageBytes = const JSONMessageCodec().encodeMessage(<String, dynamic>{
        'args': <dynamic>[
          1,
          jsonDecode(
              '{"action": "actionCommand", "data": {\"input_context\" : ["abc", "efg"]}}')
        ],
        'method': 'TextInputClient.performPrivateCommand',
      });
      await ServicesBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/textinput',
        messageBytes,
        (ByteData _) {},
      );

      expect(client.latestMethodCall, 'performPrivateCommand');
    });

    test(
        'TextInputClient performPrivateCommand method is called with CharSequence',
        () async {
      // Assemble a TextInputConnection so we can verify its change in state.
      final FakeTextInputClient client = FakeTextInputClient(null);
      const TextInputConfiguration configuration = TextInputConfiguration();
      TextInput.attach(client, configuration);

      expect(client.latestMethodCall, isEmpty);

      // Send performPrivateCommand message.
      final ByteData messageBytes =
          const JSONMessageCodec().encodeMessage(<String, dynamic>{
        'args': <dynamic>[
          1,
          jsonDecode(
              '{"action": "actionCommand", "data": {\"input_context\" : "abc"}}')
        ],
        'method': 'TextInputClient.performPrivateCommand',
      });
      await ServicesBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/textinput',
        messageBytes,
        (ByteData _) {},
      );

      expect(client.latestMethodCall, 'performPrivateCommand');
    });

    test(
        'TextInputClient performPrivateCommand method is called with float array',
        () async {
      // Assemble a TextInputConnection so we can verify its change in state.
      final FakeTextInputClient client = FakeTextInputClient(null);
      const TextInputConfiguration configuration = TextInputConfiguration();
      TextInput.attach(client, configuration);

      expect(client.latestMethodCall, isEmpty);

      // Send performPrivateCommand message.
      final ByteData messageBytes =
          const JSONMessageCodec().encodeMessage(<String, dynamic>{
        'args': <dynamic>[
          1,
          jsonDecode(
              '{"action": "actionCommand", "data": {\"input_context\" : [0.5, 0.8]}}')
        ],
        'method': 'TextInputClient.performPrivateCommand',
      });
      await ServicesBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/textinput',
        messageBytes,
        (ByteData _) {},
      );

      expect(client.latestMethodCall, 'performPrivateCommand');
    });

    test('TextInputClient showAutocorrectionPromptRect method is called',
        () async {
      // Assemble a TextInputConnection so we can verify its change in state.
      final FakeTextInputClient client = FakeTextInputClient(null);
      const TextInputConfiguration configuration = TextInputConfiguration();
      TextInput.attach(client, configuration);

      expect(client.latestMethodCall, isEmpty);

      // Send onConnectionClosed message.
      final ByteData messageBytes =
          const JSONMessageCodec().encodeMessage(<String, dynamic>{
        'args': <dynamic>[1, 0, 1],
        'method': 'TextInputClient.showAutocorrectionPromptRect',
      });
      await ServicesBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/textinput',
        messageBytes,
        (ByteData _) {},
      );

      expect(client.latestMethodCall, 'showAutocorrectionPromptRect');
    });
  });

  test('TextEditingValue.isComposingRangeValid', () async {
    // The composing range is empty.
    expect(const TextEditingValue(text: '').isComposingRangeValid, isFalse);

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
  AutofillScope get currentAutofillScope => null;

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
  Future<void> Function(MethodCall) incoming;

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
  void setMethodCallHandler(Future<void> Function(MethodCall call) handler) {
    incoming = handler;
  }

  @override
  bool checkMethodCallHandler(Future<void> Function(MethodCall call) handler) => throw UnimplementedError();


  @override
  void setMockMethodCallHandler(Future<void> Function(MethodCall call) handler)  => throw UnimplementedError();

  @override
  bool checkMockMethodCallHandler(Future<void> Function(MethodCall call) handler) => throw UnimplementedError();

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
          '  actual:   ${outgoingCalls[i]}\n'
          '  expected: ${calls[i]}');
        hasError = true;
      }
    }
    if (hasError) {
      fail('Calls did not match.');
    }
  }
}
