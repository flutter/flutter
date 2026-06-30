// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';

import 'package:async/async.dart';
import 'package:flutter_tools/extension_protocol.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as rpc;
import 'package:stream_channel/isolate_channel.dart';
import 'package:test/test.dart';

void main() {
  group('ToolExtensionProvider', () {
    late ReceivePort hostReceivePort;
    late StreamQueue<Object?> queue;
    late ToolExtensionProvider provider;

    setUp(() {
      hostReceivePort = ReceivePort();
      queue = StreamQueue<Object?>(hostReceivePort);
      provider = ToolExtensionProvider(hostReceivePort.sendPort);
    });

    tearDown(() async {
      await provider.close();
      await queue.cancel(immediate: true);
      hostReceivePort.close();
    });

    test('initialize sends SendPort to host', () async {
      provider.initialize();
      final Object? message = await queue.next;
      expect(message, isA<SendPort>());

      // Send a dummy SendPort back to satisfy connectReceive's handshake
      // and prevent "Source stream already set" error on close/teardown.
      final dummyReceivePort = ReceivePort();
      (message! as SendPort).send(dummyReceivePort.sendPort);
      // Yield to the event loop so the message is processed.
      await Future<void>.delayed(Duration.zero);
      dummyReceivePort.close();
    });

    test('registerRpc and dispatcher success', () async {
      provider.registerRpc('test.method', (rpc.Parameters params) {
        return <String, Object?>{'echo': params['input'].value};
      });

      provider.initialize();
      final providerSendPort = (await queue.next)! as SendPort;

      final channel = IsolateChannel<Object?>.connectSend(providerSendPort);
      final request = <String, Object?>{
        'jsonrpc': '2.0',
        'id': 1,
        'method': 'test.method',
        'params': const <String, Object?>{'input': 'hello'},
      };
      channel.sink.add(request);

      final Object? responseMsg = await channel.stream.first;
      expect(responseMsg, isA<Map<Object?, Object?>>());
      final Map<String, Object?> response = (responseMsg! as Map<Object?, Object?>)
          .cast<String, Object?>();

      expect(response['id'], 1);
      expect(response['result'], const <String, Object?>{'echo': 'hello'});
      expect(response['error'], isNull);
      await channel.sink.close();
    });

    test('handler not found sends error', () async {
      provider.initialize();
      final providerSendPort = (await queue.next)! as SendPort;

      final channel = IsolateChannel<Object?>.connectSend(providerSendPort);
      final request = <String, Object?>{'jsonrpc': '2.0', 'id': 42, 'method': 'unknown.method'};
      channel.sink.add(request);

      final Object? responseMsg = await channel.stream.first;
      expect(responseMsg, isA<Map<Object?, Object?>>());
      final Map<String, Object?> response = (responseMsg! as Map<Object?, Object?>)
          .cast<String, Object?>();

      expect(response['id'], 42);
      expect(response['result'], isNull);
      expect(response['error'], isNotNull);
      final error = response['error']! as Map<Object?, Object?>;
      expect(error['code'], -32601);
      expect(error['message'], 'Unknown method "unknown.method".');
      await channel.sink.close();
    });

    test('duplicate registration throws StateError', () {
      provider.registerRpc('foo', () => 'bar');
      expect(() => provider.registerRpc('foo', () => 'baz'), throwsA(isA<StateError>()));
    });

    test('handler throwing exception sends internal error', () async {
      provider.registerRpc('fail', () {
        throw Exception('something went wrong');
      });

      provider.initialize();
      final providerSendPort = (await queue.next)! as SendPort;

      final channel = IsolateChannel<Object?>.connectSend(providerSendPort);
      final request = <String, Object?>{'jsonrpc': '2.0', 'id': 100, 'method': 'fail'};
      channel.sink.add(request);

      final Object? responseMsg = await channel.stream.first;
      expect(responseMsg, isA<Map<Object?, Object?>>());
      final Map<String, Object?> response = (responseMsg! as Map<Object?, Object?>)
          .cast<String, Object?>();

      expect(response['id'], 100);
      expect(response['result'], isNull);
      expect(response['error'], isNotNull);
      final error = response['error']! as Map<Object?, Object?>;
      expect(error['code'], -32000);
      expect(error['message'], contains('something went wrong'));
      await channel.sink.close();
    });

    test('invalid request map from host sends parse error', () async {
      provider.initialize();
      final providerSendPort = (await queue.next)! as SendPort;

      final channel = IsolateChannel<Object?>.connectSend(providerSendPort);
      final invalidMap = <String, Object?>{'jsonrpc': '2.0', 'id': 123};
      channel.sink.add(invalidMap);

      final Object? responseMsg = await channel.stream.first;
      expect(responseMsg, isA<Map<Object?, Object?>>());
      final Map<String, Object?> response = (responseMsg! as Map<Object?, Object?>)
          .cast<String, Object?>();

      expect(response['id'], 123);
      expect(response['result'], isNull);
      expect(response['error'], isNotNull);
      final error = response['error']! as Map<Object?, Object?>;
      expect(error['code'], -32600);
      expect(error['message'], startsWith('Request must contain'));
      await channel.sink.close();
    });

    test('sendNotification pushes notification to host', () async {
      provider.initialize();
      final providerSendPort = (await queue.next)! as SendPort;

      final channel = IsolateChannel<Object?>.connectSend(providerSendPort);
      provider.sendNotification('test.notify', const <String, Object?>{'data': 123});

      final Object? notifyMsg = await channel.stream.first;
      expect(notifyMsg, isA<Map<Object?, Object?>>());
      final Map<String, Object?> response = (notifyMsg! as Map<Object?, Object?>)
          .cast<String, Object?>();

      expect(response['jsonrpc'], '2.0');
      expect(response['method'], 'test.notify');
      expect(response['params'], const <String, Object?>{'data': 123});
      expect(response['id'], isNull);
      await channel.sink.close();
    });

    test('receiving notification from host pushes to notifications stream', () async {
      provider.initialize();
      final providerSendPort = (await queue.next)! as SendPort;

      final channel = IsolateChannel<Object?>.connectSend(providerSendPort);
      final notificationReceived = Completer<Notification>();
      final StreamSubscription<Notification> sub = provider.notifications.listen(
        notificationReceived.complete,
      );

      final hostNotification = <String, Object?>{
        'jsonrpc': '2.0',
        'method': 'host.event',
        'params': const <String, Object?>{'x': 1},
      };
      channel.sink.add(hostNotification);

      final Notification received = await notificationReceived.future.timeout(
        const Duration(seconds: 1),
      );
      expect(received.method, 'host.event');
      expect(received.params, const <String, Object?>{'x': 1});

      await sub.cancel();
      await channel.sink.close();
    });
  });
}
