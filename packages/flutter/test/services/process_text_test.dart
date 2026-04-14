// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ProcessTextService.queryTextActions emits correct method call', () async {
    final log = <MethodCall>[];

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.processText,
      (MethodCall methodCall) async {
        log.add(methodCall);
        return null;
      },
    );

    final ProcessTextService processTextService = DefaultProcessTextService();
    await processTextService.queryTextActions();

    expect(log, hasLength(1));
    expect(log.single, isMethodCall('ProcessText.queryTextActions', arguments: null));
  });

  test('ProcessTextService.processTextAction emits correct method call', () async {
    final log = <MethodCall>[];

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.processText,
      (MethodCall methodCall) async {
        log.add(methodCall);
        return null;
      },
    );

    final ProcessTextService processTextService = DefaultProcessTextService();
    const fakeActionId = 'fakeActivity.fakeAction';
    const textToProcess = 'Flutter';
    await processTextService.processTextAction(fakeActionId, textToProcess, false);

    expect(log, hasLength(1));
    expect(
      log.single,
      isMethodCall(
        'ProcessText.processTextAction',
        arguments: <Object>[fakeActionId, textToProcess, false],
      ),
    );
  });

  test('ProcessTextService handles engine answers over the channel', () async {
    const action1Id = 'fakeActivity.fakeAction1';
    const action2Id = 'fakeActivity.fakeAction2';

    // Fake channel that simulates responses returned from the engine.
    final MethodChannel fakeChannel = FakeProcessTextChannel((MethodCall call) async {
      if (call.method == 'ProcessText.queryTextActions') {
        return <String, String>{action1Id: 'Action1', action2Id: 'Action2'};
      }
      if (call.method == 'ProcessText.processTextAction') {
        final args = call.arguments as List<dynamic>;
        final actionId = args[0] as String;
        final testToProcess = args[1] as String;
        if (actionId == action1Id) {
          // Simulates an action that returns a transformed text.
          return '$testToProcess!!!';
        }
        // Simulates an action that failed or does not transform text.
        return null;
      }
    });

    final processTextService = DefaultProcessTextService();
    processTextService.setChannel(fakeChannel);

    final List<ProcessTextAction> actions = await processTextService.queryTextActions();
    expect(actions, hasLength(2));

    const textToProcess = 'Flutter';
    String? processedText;

    processedText = await processTextService.processTextAction(action1Id, textToProcess, false);
    expect(processedText, 'Flutter!!!');

    processedText = await processTextService.processTextAction(action2Id, textToProcess, false);
    expect(processedText, null);
  });
}

class FakeProcessTextChannel implements MethodChannel {
  FakeProcessTextChannel(this.outgoing);

  Future<dynamic> Function(MethodCall) outgoing;
  Future<void> Function(MethodCall)? incoming;

  List<MethodCall> outgoingCalls = <MethodCall>[];

  @override
  BinaryMessenger get binaryMessenger => throw UnimplementedError();

  @override
  MethodCodec get codec => const StandardMethodCodec();

  @override
  Future<List<T>> invokeListMethod<T>(String method, [dynamic arguments]) =>
      throw UnimplementedError();

  @override
  Future<Map<K, V>> invokeMapMethod<K, V>(String method, [dynamic arguments]) =>
      throw UnimplementedError();

  @override
  Future<T> invokeMethod<T>(String method, [dynamic arguments]) async {
    final call = MethodCall(method, arguments);
    outgoingCalls.add(call);
    return await outgoing(call) as T;
  }

  @override
  String get name => 'flutter/processtext';

  @override
  void setMethodCallHandler(Future<void> Function(MethodCall call)? handler) => incoming = handler;
}
