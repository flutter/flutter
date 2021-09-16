// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert' show utf8;
import 'dart:convert' show jsonDecode;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DeltaTextInputClient', () {
    late FakeTextChannel fakeTextChannel;

    setUp(() {
      fakeTextChannel = FakeTextChannel((MethodCall call) async {});
      TextInput.setChannel(fakeTextChannel);
    });

    tearDown(() {
      TextInputConnection.debugResetId();
      TextInput.setChannel(SystemChannels.textInput);
    });

    test(
      'DeltaTextInputClient send the correct configuration to the platform and responds to updateEditingValueWithDeltas method correctly',
      () async {
        // Assemble a TextInputConnection so we can verify its change in state.
        final FakeDeltaTextInputClient client = FakeDeltaTextInputClient(TextEditingValue.empty);
        const TextInputConfiguration configuration = TextInputConfiguration(enableDeltaModel: true);
        TextInput.attach(client, configuration);
        expect(client.configuration.enableDeltaModel, true);

        expect(client.latestMethodCall, isEmpty);

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

        // Send updateEditingValueWithDeltas message.
        final ByteData? messageBytes = const JSONMessageCodec().encodeMessage(<String, dynamic>{
          'args': <dynamic>[
            1,
            jsonDecode('{"deltas": [$jsonDelta]}'),
          ],
          'method': 'TextInputClient.updateEditingStateWithDeltas',
        });
        await ServicesBinding.instance!.defaultBinaryMessenger.handlePlatformMessage(
          'flutter/textinput',
          messageBytes,
              (ByteData? _) {},
        );

        expect(client.latestMethodCall, 'updateEditingValueWithDeltas');
      },
    );
  });
}

class FakeDeltaTextInputClient implements DeltaTextInputClient {
  FakeDeltaTextInputClient(this.currentTextEditingValue);

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
  void updateEditingValueWithDeltas(List<TextEditingDelta> textEditingDeltas) {
    latestMethodCall = 'updateEditingValueWithDeltas';
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

  TextInputConfiguration get configuration => const TextInputConfiguration(enableDeltaModel: true);
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
