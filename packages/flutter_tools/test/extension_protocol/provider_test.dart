// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';

import 'package:async/async.dart';
import 'package:flutter_tools/extension_protocol.dart';
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
      provider.close();
      await queue.cancel(immediate: true);
      hostReceivePort.close();
    });

    test('initialize sends SendPort to host', () async {
      provider.initialize();
      final Object? message = await queue.next;
      expect(message, isA<SendPort>());
    });

    test('registerRpc and dispatcher success', () async {
      provider.initialize();
      final providerSendPort = (await queue.next)! as SendPort;

      provider.registerRpc('test.method', (Map<String, Object?> params) {
        return Response.result(id: '', result: <String, Object?>{'echo': params['input']});
      });

      final request = Request(
        id: 1,
        method: 'test.method',
        params: const <String, Object?>{'input': 'hello'},
      );
      providerSendPort.send(request.toMap());

      final Object? responseMsg = await queue.next;
      expect(responseMsg, isA<Map<String, Object?>>());
      final response = Message.fromMap(responseMsg! as Map<String, Object?>) as Response;

      expect(response.id, 1);
      expect(response.result, const <String, Object?>{'echo': 'hello'});
      expect(response.error, isNull);
    });

    test('handler not found sends error', () async {
      provider.initialize();
      final providerSendPort = (await queue.next)! as SendPort;

      final request = Request(id: 42, method: 'unknown.method');
      providerSendPort.send(request.toMap());

      final Object? responseMsg = await queue.next;
      final response = Message.fromMap(responseMsg! as Map<String, Object?>) as Response;

      expect(response.id, 42);
      expect(response.result, isNull);
      expect(response.error, isNotNull);
      expect(response.error!.code, -32601);
    });

    test('duplicate registration throws StateError', () {
      provider.registerRpc(
        'foo',
        (Map<String, Object?> params) => const Response.result(id: '', result: 'bar'),
      );
      expect(
        () => provider.registerRpc(
          'foo',
          (Map<String, Object?> params) => const Response.result(id: '', result: 'baz'),
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('handler throwing exception sends internal error', () async {
      provider.initialize();
      final providerSendPort = (await queue.next)! as SendPort;

      provider.registerRpc('fail', (Map<String, Object?> params) {
        throw Exception('something went wrong');
      });

      final request = Request(id: 100, method: 'fail');
      providerSendPort.send(request.toMap());

      final Object? responseMsg = await queue.next;
      final response = Message.fromMap(responseMsg! as Map<String, Object?>) as Response;

      expect(response.id, 100);
      expect(response.result, isNull);
      expect(response.error, isNotNull);
      expect(response.error!.code, -32603);
      expect(response.error!.message, contains('Exception: something went wrong'));
    });

    test('sendNotification pushes notification to host', () async {
      provider.initialize();
      // Consume the handshake SendPort
      await queue.next;

      final notification = Notification(
        method: 'test.notify',
        params: const <String, Object?>{'data': 123},
      );
      provider.sendNotification(notification);

      final Object? notifyMsg = await queue.next;
      expect(notifyMsg, isA<Map<String, Object?>>());
      final parsed = Message.fromMap(notifyMsg! as Map<String, Object?>) as Notification;
      expect(parsed.method, 'test.notify');
      expect(parsed.params, const <String, Object?>{'data': 123});
    });

    test('receiving notification from host pushes to notifications stream', () async {
      provider.initialize();
      final providerSendPort = (await queue.next)! as SendPort;

      final notificationReceived = Completer<Notification>();
      final StreamSubscription<Notification> sub = provider.notifications.listen(
        notificationReceived.complete,
      );

      final hostNotification = Notification(
        method: 'host.event',
        params: const <String, Object?>{'x': 1},
      );
      providerSendPort.send(hostNotification.toMap());

      final Notification received = await notificationReceived.future.timeout(
        const Duration(seconds: 1),
      );
      expect(received.method, 'host.event');
      expect(received.params, const <String, Object?>{'x': 1});

      await sub.cancel();
    });
  });
}
