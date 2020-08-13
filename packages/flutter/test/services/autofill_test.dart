// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:convert' show utf8;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TextInput message channels', () {
    FakeTextChannel fakeTextChannel;
    FakeAutofillScope scope;

    setUp(() {
      fakeTextChannel = FakeTextChannel((MethodCall call) async {});
      TextInput.setChannel(fakeTextChannel);
      scope ??= FakeAutofillScope();
      scope.clients.clear();
    });

    tearDown(() {
      TextInputConnection.debugResetId();
      TextInput.setChannel(SystemChannels.textInput);
    });

    test('mandatory fields are mandatory', () async {
      AutofillConfiguration config;
      try {
        config = AutofillConfiguration(
          uniqueIdentifier: null,
          autofillHints: const <String>['test'],
          currentEditingValue: const TextEditingValue(),
        );
      } catch (e) {
        expect(e.toString(), contains('uniqueIdentifier != null'));
      }

      expect(config, isNull);

      try {
        config = AutofillConfiguration(
          uniqueIdentifier: 'id',
          autofillHints: null,
          currentEditingValue: const TextEditingValue(),
        );
      } catch (e) {
        expect(e.toString(), contains('autofillHints != null'));
      }

      expect(config, isNull);
    });

    test('throws if the hint list is empty', () async {
      Map<String, dynamic> json;
      try {
        const AutofillConfiguration config = AutofillConfiguration(
          uniqueIdentifier: 'id',
          autofillHints: <String>[],
          currentEditingValue: TextEditingValue(),
        );

        json = config.toJson();
      } catch (e) {
        expect(e.toString(), contains('isNotEmpty'));
      }

      expect(json, isNull);
    });

    test(
      'AutofillClients send the correct configuration to the platform'
      'and responds to updateEditingStateWithTag method correctly',
      () async {
        final FakeAutofillClient client1 = FakeAutofillClient(const TextEditingValue(text: 'test1'));
        final FakeAutofillClient client2 = FakeAutofillClient(const TextEditingValue(text: 'test2'));

        client1.textInputConfiguration = TextInputConfiguration(
          autofillConfiguration: AutofillConfiguration(
            uniqueIdentifier: client1.autofillId,
            autofillHints: const <String>['client1'],
            currentEditingValue: client1.currentTextEditingValue,
          ),
        );

        client2.textInputConfiguration = TextInputConfiguration(
          autofillConfiguration: AutofillConfiguration(
            uniqueIdentifier: client2.autofillId,
            autofillHints: const <String>['client2'],
            currentEditingValue: client2.currentTextEditingValue,
          ),
        );

        scope.register(client1);
        scope.register(client2);
        client1.currentAutofillScope = scope;
        client2.currentAutofillScope = scope;

        scope.attach(client1, client1.textInputConfiguration);

        final Map<String, dynamic> expectedConfiguration = client1.textInputConfiguration.toJson();
        expectedConfiguration['fields'] = <Map<String, dynamic>>[
          client1.textInputConfiguration.toJson(),
          client2.textInputConfiguration.toJson(),
        ];

        fakeTextChannel.validateOutgoingMethodCalls(<MethodCall>[
          MethodCall('TextInput.setClient', <dynamic>[1, expectedConfiguration]),
        ]);

        const TextEditingValue text2 = TextEditingValue(text: 'Text 2');
        fakeTextChannel.incoming(MethodCall(
          'TextInputClient.updateEditingStateWithTag',
          <dynamic>[0, <String, dynamic>{ client2.autofillId : text2.toJSON() }],
        ));

        expect(client2.currentTextEditingValue, text2);
    });
  });
}

class FakeAutofillClient implements TextInputClient, AutofillClient {
  FakeAutofillClient(this.currentTextEditingValue);

  @override
  String get autofillId => hashCode.toString();

  @override
  TextInputConfiguration textInputConfiguration;

  @override
  void updateEditingValue(TextEditingValue newEditingValue) {
    currentTextEditingValue = newEditingValue;
    latestMethodCall = 'updateEditingValue';
  }

  @override
  AutofillScope currentAutofillScope;

  String latestMethodCall = '';

  @override
  TextEditingValue currentTextEditingValue;

  @override
  void performAction(TextInputAction action) {
    latestMethodCall = 'performAction';
  }

  @override
  void performPrivateCommand(String action, Map<String, dynamic> data) {
    latestMethodCall = 'performPrivateCommand';
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
}

class FakeAutofillScope with AutofillScopeMixin implements AutofillScope {
  final Map<String, AutofillClient> clients = <String, AutofillClient>{};

  @override
  Iterable<AutofillClient> get autofillClients => clients.values;

  @override
  AutofillClient getAutofillClient(String autofillId) => clients[autofillId];

  void register(AutofillClient client) {
    clients.putIfAbsent(client.autofillId, () => client);
  }
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
