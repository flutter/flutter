// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';

import 'package:flutter_tools/extension_protocol.dart';
import 'package:test/test.dart';

void testExtensionEntryPoint(SendPort hostSendPort) {
  final provider = ToolExtensionProvider(hostSendPort);
  Map<String, Object?>? lastNotification;

  provider
    ..notifications.listen((Notification n) {
      lastNotification = <String, Object?>{'method': n.method, 'params': n.params};
      if (n.method == 'ping') {
        provider.sendNotification(Notification(method: 'pong', params: n.params));
      }
    })
    ..registerRpc('echo', (Map<String, Object?> params) {
      return Response.result(result: params);
    })
    ..registerRpc('nullResult', (Map<String, Object?> params) {
      return const Response.result(result: null);
    })
    ..registerRpc('error', (Map<String, Object?> params) {
      return const Response.error(error: RpcError(code: 999, message: 'custom error'));
    })
    ..registerRpc('throw', (Map<String, Object?> params) {
      throw Exception('thrown exception');
    })
    ..registerRpc('slow', (Map<String, Object?> params) async {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      return const Response.result(result: 'slow ok');
    })
    ..registerRpc('getLastNotification', (Map<String, Object?> params) {
      return Response.result(result: lastNotification);
    })
    ..initialize();

  // Send a test notification
  provider.sendNotification(
    Notification(method: 'ready', params: const <String, Object?>{'status': 'go'}),
  );
}

void slowHandshakeEntryPoint(SendPort hostSendPort) {
  Timer(const Duration(milliseconds: 500), () {
    final provider = ToolExtensionProvider(hostSendPort);
    provider.initialize();
  });
}

void main() {
  group('ToolExtensionManager', () {
    late ToolExtensionManager manager;

    setUp(() {
      manager = ToolExtensionManager();
    });

    tearDown(() async {
      await manager.dispose();
    });

    test('start and handshake success', () async {
      await manager.start(testExtensionEntryPoint);
      const params = <String, Object?>{'val': 1};
      final Object? result = await manager.callMethod('echo', params: params);
      expect(result, params);
    });

    test('handshake timeout', () async {
      expect(
        () => manager.start(slowHandshakeEntryPoint, timeout: const Duration(milliseconds: 100)),
        throwsA(isA<TimeoutException>()),
      );
    });

    test('callMethod success', () async {
      await manager.start(testExtensionEntryPoint);
      final Object? result = await manager.callMethod(
        'echo',
        params: const <String, Object?>{'foo': 'bar'},
      );
      expect(result, const <String, Object?>{'foo': 'bar'});
    });

    test('callMethod success with null result', () async {
      await manager.start(testExtensionEntryPoint);
      final Object? result = await manager.callMethod('nullResult');
      expect(result, isNull);
    });

    test('callMethod returns error', () async {
      await manager.start(testExtensionEntryPoint);
      expect(
        () => manager.callMethod('error'),
        throwsA(
          isA<RpcException>()
              .having((RpcException e) => e.error.code, 'code', 999)
              .having((RpcException e) => e.error.message, 'message', 'custom error'),
        ),
      );
    });

    test('callMethod exception in handler returns internal error', () async {
      await manager.start(testExtensionEntryPoint);
      expect(
        () => manager.callMethod('throw'),
        throwsA(
          isA<RpcException>()
              .having((RpcException e) => e.error.code, 'code', RpcError.internalErrorCode)
              .having((RpcException e) => e.error.message, 'message', contains('thrown exception')),
        ),
      );
    });

    test('notifications stream receives notifications', () async {
      final notifyCompleter = Completer<Notification>();
      final StreamSubscription<Notification> sub = manager.notifications.listen((Notification n) {
        if (!notifyCompleter.isCompleted && n.method == 'ready') {
          notifyCompleter.complete(n);
        }
      });

      await manager.start(testExtensionEntryPoint);
      final Notification n = await notifyCompleter.future.timeout(const Duration(seconds: 2));
      expect(n.method, 'ready');
      expect(n.params, const <String, Object?>{'status': 'go'});

      await sub.cancel();
    });

    test('bi-directional notification: tool to extension with pong verification', () async {
      await manager.start(testExtensionEntryPoint);

      final pongCompleter = Completer<Notification>();
      final StreamSubscription<Notification> sub = manager.notifications.listen((Notification n) {
        if (n.method == 'pong') {
          pongCompleter.complete(n);
        }
      });

      manager.sendNotification('ping', params: const <String, Object?>{'foo': 'bar'});

      final Notification pong = await pongCompleter.future.timeout(const Duration(seconds: 2));
      expect(pong.params, const <String, Object?>{'foo': 'bar'});

      final Object? lastNotification = await manager.callMethod('getLastNotification');
      expect(lastNotification, const <String, Object?>{
        'method': 'ping',
        'params': <String, Object?>{'foo': 'bar'},
      });

      await sub.cancel();
    });
  });
}
