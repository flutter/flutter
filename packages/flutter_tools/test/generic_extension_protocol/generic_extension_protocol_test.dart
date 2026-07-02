// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:flutter_tools/generic_extension_protocol.dart';
import 'package:stream_channel/isolate_channel.dart';

import 'package:test/test.dart';

void testExtensionEntryPoint(SendPort hostSendPort) {
  final provider = ToolExtensionProvider(name: 'test', sendPort: hostSendPort);
  Map<String, Object?>? lastNotification;

  provider
    ..notifications.listen((Notification n) {
      lastNotification = <String, Object?>{'method': n.method, 'params': n.params};
      if (n.method == 'ping') {
        provider.sendNotification('pong', n.params);
      }
    })
    ..registerRpc('echo', (Parameters params) {
      return params.asMap;
    })
    ..registerRpc('nullResult', () {
      return null;
    })
    ..registerRpc('error', () {
      throw RpcException(999, 'custom error');
    })
    ..registerRpc('throw', () {
      throw Exception('thrown exception');
    })
    ..registerRpc('slow', () async {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      return 'slow ok';
    })
    ..registerRpc('getLastNotification', () {
      return lastNotification;
    })
    ..registerRpc('transferBytes', (Parameters params) {
      final Object? rawValue = params['data'].value;
      if (rawValue is! TransferableTypedData) {
        throw RpcException(1001, 'Expected TransferableTypedData');
      }
      final Uint8List bytes = rawValue.materialize().asUint8List();
      final modified = Uint8List.fromList(bytes.map((int b) => b + 1).toList());
      return TransferableTypedData.fromList(<Uint8List>[modified]);
    })
    ..initialize();

  // Send a test notification
  provider.sendNotification('ready', const <String, Object?>{'status': 'go'});
}

void slowHandshakeEntryPoint(SendPort hostSendPort) {
  Timer(const Duration(milliseconds: 500), () {
    final provider = ToolExtensionProvider(name: 'slow', sendPort: hostSendPort);
    provider.initialize();
  });
}

class MockPlatformService extends ToolExtensionService {
  @override
  String get namespace => 'platform';

  @override
  Future<Map<String, Function>> initialize() async {
    return <String, Function>{'ping': (Map<String, Object?> params) => 'pong'};
  }

  @override
  Future<void> shutdown() async {}
}

void serviceExtensionEntryPoint(SendPort hostSendPort) {
  final provider = ToolExtensionProvider(name: 'service_test', sendPort: hostSendPort);
  provider.registerService(MockPlatformService());
  provider.initialize();
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
      final ToolExtension extension = await manager.startExtension(testExtensionEntryPoint);
      const params = <String, Object?>{'val': 1};
      final Object? result = await extension.callMethod('echo', params: params);
      expect(result, params);
    });

    test('handshake timeout', () async {
      expect(
        () => manager.startExtension(
          slowHandshakeEntryPoint,
          timeout: const Duration(milliseconds: 100),
        ),
        throwsA(isA<TimeoutException>()),
      );
    });

    test('callMethod success', () async {
      final ToolExtension extension = await manager.startExtension(testExtensionEntryPoint);
      final Object? result = await extension.callMethod(
        'echo',
        params: const <String, Object?>{'foo': 'bar'},
      );
      expect(result, const <String, Object?>{'foo': 'bar'});
    });

    test('callMethod success with null result', () async {
      final ToolExtension extension = await manager.startExtension(testExtensionEntryPoint);
      final Object? result = await extension.callMethod('nullResult');
      expect(result, isNull);
    });

    test('callMethod returns error', () async {
      final ToolExtension extension = await manager.startExtension(testExtensionEntryPoint);
      expect(
        () => extension.callMethod('error'),
        throwsA(
          isA<RpcException>()
              .having((RpcException e) => e.code, 'code', 999)
              .having((RpcException e) => e.message, 'message', 'custom error'),
        ),
      );
    });

    test('callMethod exception in handler returns internal error', () async {
      final ToolExtension extension = await manager.startExtension(testExtensionEntryPoint);
      expect(
        () => extension.callMethod('throw'),
        throwsA(
          isA<RpcException>()
              .having(
                (RpcException e) => e.code,
                'code',
                -32000,
              ) // -32000 is json_rpc.error_code.SERVER_ERROR
              .having((RpcException e) => e.message, 'message', contains('thrown exception')),
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
      addTearDown(sub.cancel);

      await manager.startExtension(testExtensionEntryPoint);
      final Notification n = await notifyCompleter.future.timeout(const Duration(seconds: 2));
      expect(n.method, 'ready');
      expect(n.params, const <String, Object?>{'status': 'go'});
    });

    test('bi-directional notification: tool to extension with pong verification', () async {
      final ToolExtension extension = await manager.startExtension(testExtensionEntryPoint);

      final pongCompleter = Completer<Notification>();
      final StreamSubscription<Notification> sub = manager.notifications.listen((Notification n) {
        if (n.method == 'pong') {
          pongCompleter.complete(n);
        }
      });
      addTearDown(sub.cancel);

      extension.sendNotification('ping', params: const <String, Object?>{'foo': 'bar'});

      final Notification pong = await pongCompleter.future.timeout(const Duration(seconds: 2));
      expect(pong.params, const <String, Object?>{'foo': 'bar'});

      final Object? lastNotification = await extension.callMethod('getLastNotification');
      expect(lastNotification, const <String, Object?>{
        'method': 'ping',
        'params': <String, Object?>{'foo': 'bar'},
      });
    });

    test('callMethod with TransferableTypedData parameter and return value', () async {
      final ToolExtension extension = await manager.startExtension(testExtensionEntryPoint);

      final inputBytes = Uint8List.fromList(<int>[1, 2, 3, 4]);
      final inputData = TransferableTypedData.fromList(<Uint8List>[inputBytes]);

      final Object? result = await extension.callMethod(
        'transferBytes',
        params: <String, Object?>{'data': inputData},
      );

      expect(result, isA<TransferableTypedData>());
      final outputData = result! as TransferableTypedData;
      final Uint8List outputBytes = outputData.materialize().asUint8List();

      expect(outputBytes, Uint8List.fromList(<int>[2, 3, 4, 5]));
    });

    test('register service and discover capabilities', () async {
      final ToolExtension extension = await manager.startExtension(serviceExtensionEntryPoint);

      // Verify capabilities are correctly exposed
      final ToolExtensionCapabilities capabilities = await extension.getCapabilities();
      expect(capabilities.services, const <String>['platform']);

      // Verify namespaced RPC method works
      final Object? result = await extension.callMethod('platform.ping');
      expect(result, 'pong');
    });
  });

  group('ToolExtensionProvider', () {
    late ReceivePort hostReceivePort;
    late StreamQueue<Object?> queue;
    late ToolExtensionProvider provider;

    setUp(() {
      hostReceivePort = ReceivePort();
      queue = StreamQueue<Object?>(hostReceivePort);
      provider = ToolExtensionProvider(name: 'test', sendPort: hostReceivePort.sendPort);
    });

    tearDown(() async {
      await provider.close();
      await queue.cancel(immediate: true);
      hostReceivePort.close();
    });

    test('initialize sends SendPort to host', () async {
      unawaited(provider.initialize());
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
      provider.registerRpc('test.method', (Parameters params) {
        return <String, Object?>{'echo': params['input'].value};
      });

      unawaited(provider.initialize());
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
      unawaited(provider.initialize());
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

      unawaited(provider.initialize());
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
      unawaited(provider.initialize());
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
      unawaited(provider.initialize());
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
      unawaited(provider.initialize());
      final providerSendPort = (await queue.next)! as SendPort;

      final channel = IsolateChannel<Object?>.connectSend(providerSendPort);
      final notificationReceived = Completer<Notification>();
      final StreamSubscription<Notification> sub = provider.notifications.listen(
        notificationReceived.complete,
      );
      addTearDown(sub.cancel);

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

      await channel.sink.close();
    });
  });
}
