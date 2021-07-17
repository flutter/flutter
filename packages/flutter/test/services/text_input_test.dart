// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.


import 'dart:convert' show utf8;
import 'dart:convert' show jsonDecode;
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  group('TextInputControl', () {
    late FakeTextChannel fakeTextChannel;

    setUp(() {
      fakeTextChannel = FakeTextChannel((MethodCall call) async {});
      TextInput.setChannel(fakeTextChannel);
    });

    tearDown(() {
      TextInput.restorePlatformInputControl();
      TextInputConnection.debugResetId();
      TextInput.setChannel(SystemChannels.textInput);
    });

    test('gets attached and detached', () {
      final FakeTextInputControl control = FakeTextInputControl();
      TextInput.setInputControl(control);

      final FakeTextInputClient client = FakeTextInputClient(TextEditingValue.empty);
      final TextInputConnection connection = TextInput.attach(client, const TextInputConfiguration());

      final List<String> expectedMethodCalls = <String>['attach'];
      expect(control.methodCalls, expectedMethodCalls);

      connection.close();
      expectedMethodCalls.add('detach');
      expect(control.methodCalls, expectedMethodCalls);
    });

    test('receives text input state changes', () {
      final FakeTextInputControl control = FakeTextInputControl();
      TextInput.setInputControl(control);

      final FakeTextInputClient client = FakeTextInputClient(TextEditingValue.empty);
      final TextInputConnection connection = TextInput.attach(client, const TextInputConfiguration());
      control.methodCalls.clear();

      final List<String> expectedMethodCalls = <String>[];

      connection.updateConfig(const TextInputConfiguration());
      expectedMethodCalls.add('updateConfig');
      expect(control.methodCalls, expectedMethodCalls);

      connection.setEditingState(TextEditingValue.empty);
      expectedMethodCalls.add('setEditingState');
      expect(control.methodCalls, expectedMethodCalls);

      connection.close();
      expectedMethodCalls.add('detach');
      expect(control.methodCalls, expectedMethodCalls);
    });

    test('does not interfere with platform text input', () {
      final FakeTextInputControl control = FakeTextInputControl();
      TextInput.setInputControl(control);

      final FakeTextInputClient client = FakeTextInputClient(TextEditingValue.empty);
      TextInput.attach(client, const TextInputConfiguration());

      fakeTextChannel.outgoingCalls.clear();

      fakeTextChannel.incoming!(MethodCall('TextInputClient.updateEditingState', <dynamic>[1, TextEditingValue.empty.toJSON()]));

      expect(client.latestMethodCall, 'updateEditingValue');
      expect(control.methodCalls, <String>['attach', 'setEditingState']);
      expect(fakeTextChannel.outgoingCalls, isEmpty);
    });

    test('both input controls receive requests', () async {
      final FakeTextInputControl control = FakeTextInputControl();
      TextInput.setInputControl(control);

      const TextInputConfiguration textConfig = TextInputConfiguration(inputType: TextInputType.text);
      const TextInputConfiguration numberConfig = TextInputConfiguration(inputType: TextInputType.number);
      const TextInputConfiguration noneConfig = TextInputConfiguration(inputType: TextInputType.none);

      final FakeTextInputClient client = FakeTextInputClient(TextEditingValue.empty);
      final TextInputConnection connection = TextInput.attach(client, textConfig);

      final List<String> expectedMethodCalls = <String>['attach'];
      expect(control.methodCalls, expectedMethodCalls);
      expect(control.inputType, TextInputType.text);
      fakeTextChannel.validateOutgoingMethodCalls(<MethodCall>[
        // When there's a custom text input control installed, the platform text
        // input control receives TextInputType.none
        MethodCall('TextInput.setClient', <dynamic>[1, noneConfig.toJson()]),
      ]);

      connection.show();
      expectedMethodCalls.add('show');
      expect(control.methodCalls, expectedMethodCalls);
      expect(fakeTextChannel.outgoingCalls.length, 2);
      expect(fakeTextChannel.outgoingCalls.last.method, 'TextInput.show');

      connection.updateConfig(numberConfig);
      expectedMethodCalls.add('updateConfig');
      expect(control.methodCalls, expectedMethodCalls);
      expect(control.inputType, TextInputType.number);
      expect(fakeTextChannel.outgoingCalls.length, 3);
      fakeTextChannel.validateOutgoingMethodCalls(<MethodCall>[
        // When there's a custom text input control installed, the platform text
        // input control receives TextInputType.none
        MethodCall('TextInput.setClient', <dynamic>[1, noneConfig.toJson()]),
        const MethodCall('TextInput.show'),
        MethodCall('TextInput.updateConfig', noneConfig.toJson()),
      ]);

      connection.setComposingRect(Rect.zero);
      expectedMethodCalls.add('setComposingRect');
      expect(control.methodCalls, expectedMethodCalls);
      expect(fakeTextChannel.outgoingCalls.length, 4);
      expect(fakeTextChannel.outgoingCalls.last.method, 'TextInput.setMarkedTextRect');

      connection.setCaretRect(Rect.zero);
      expectedMethodCalls.add('setCaretRect');
      expect(control.methodCalls, expectedMethodCalls);
      expect(fakeTextChannel.outgoingCalls.length, 5);
      expect(fakeTextChannel.outgoingCalls.last.method, 'TextInput.setCaretRect');

      connection.setEditableSizeAndTransform(Size.zero, Matrix4.identity());
      expectedMethodCalls.add('setEditableSizeAndTransform');
      expect(control.methodCalls, expectedMethodCalls);
      expect(fakeTextChannel.outgoingCalls.length, 6);
      expect(fakeTextChannel.outgoingCalls.last.method, 'TextInput.setEditableSizeAndTransform');

      connection.setStyle(
        fontFamily: null,
        fontSize: null,
        fontWeight: null,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.left,
      );
      expectedMethodCalls.add('setStyle');
      expect(control.methodCalls, expectedMethodCalls);
      expect(fakeTextChannel.outgoingCalls.length, 7);
      expect(fakeTextChannel.outgoingCalls.last.method, 'TextInput.setStyle');

      connection.close();
      expectedMethodCalls.add('detach');
      expect(control.methodCalls, expectedMethodCalls);
      expect(fakeTextChannel.outgoingCalls.length, 8);
      expect(fakeTextChannel.outgoingCalls.last.method, 'TextInput.clearClient');

      expectedMethodCalls.add('hide');
      final TestWidgetsFlutterBinding binding = TestWidgetsFlutterBinding.ensureInitialized() as TestWidgetsFlutterBinding;
      await binding.runAsync(() async {});
      await expectLater(control.methodCalls, expectedMethodCalls);
      expect(fakeTextChannel.outgoingCalls.length, 9);
      expect(fakeTextChannel.outgoingCalls.last.method, 'TextInput.hide');
    });

    test('notifies changes to the attached client', () async {
      final FakeTextInputControl control = FakeTextInputControl();
      TextInput.setInputControl(control);

      final FakeTextInputClient client = FakeTextInputClient(TextEditingValue.empty);
      final TextInputConnection connection = TextInput.attach(client, const TextInputConfiguration());

      TextInput.setInputControl(null);
      expect(client.latestMethodCall, 'didChangeInputControl');

      connection.show();
      expect(client.latestMethodCall, 'didChangeInputControl');
    });
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

  @override
  void didChangeInputControl(TextInputControl? oldControl, TextInputControl? newControl) {
    latestMethodCall = 'didChangeInputControl';
  }
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

class FakeTextInputControl extends TextInputControl {
  final List<String> methodCalls = <String>[];
  late TextInputType inputType;

  @override
  void attach(TextInputClient client, TextInputConfiguration configuration) {
    methodCalls.add('attach');
    inputType = configuration.inputType;
  }

  @override
  void detach(TextInputClient client) {
    methodCalls.add('detach');
  }

  @override
  void setEditingState(TextEditingValue value) {
    methodCalls.add('setEditingState');
  }

  @override
  void updateConfig(TextInputConfiguration configuration) {
    methodCalls.add('updateConfig');
    inputType = configuration.inputType;
  }

  @override
  void show() {
    methodCalls.add('show');
  }

  @override
  void hide() {
    methodCalls.add('hide');
  }

  @override
  void setComposingRect(Rect rect) {
    methodCalls.add('setComposingRect');
  }

  @override
  void setCaretRect(Rect rect) {
    methodCalls.add('setCaretRect');
  }

  @override
  void setEditableSizeAndTransform(Size editableBoxSize, Matrix4 transform) {
    methodCalls.add('setEditableSizeAndTransform');
  }

  @override
  void setStyle({
    required String? fontFamily,
    required double? fontSize,
    required FontWeight? fontWeight,
    required TextDirection textDirection,
    required TextAlign textAlign,
  }) {
    methodCalls.add('setStyle');
  }

  @override
  void finishAutofillContext({bool shouldSave = true}) {
    methodCalls.add('finishAutofillContext');
  }

  @override
  void requestAutofill() {
    methodCalls.add('requestAutofill');
  }
}
