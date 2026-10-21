// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';

import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/experimental/extension_discovery.dart';
import 'package:flutter_tools_extension/flutter_tools_extension.dart';
import 'package:test/test.dart';

void _dummyExtensionEntryPoint(SendPort sendPort) {
  unawaited(ToolExtensionEntryPoint.run(sendPort, <ToolExtensionService>[]));
}

void _failingExtensionEntryPoint(SendPort sendPort) {
  // Throws during isolate initialization before handshake.
  throw StateError('Simulated isolate startup failure');
}

void _failingServiceInitEntryPoint(SendPort sendPort) {
  unawaited(ToolExtensionEntryPoint.run(sendPort, <ToolExtensionService>[_FailingInitService()]));
}

void _duplicateRpcEntryPoint(SendPort sendPort) {
  unawaited(
    ToolExtensionEntryPoint.run(sendPort, <ToolExtensionService>[
      _DummyService('test', 'ping'),
      _DummyService('test', 'ping'),
    ]),
  );
}

class _DummyService extends ToolExtensionService {
  _DummyService(this.namespace, this.methodName);

  @override
  final String namespace;
  final String methodName;

  @override
  Future<Map<String, ExtensionRpcHandler>> initialize() async {
    return <String, ExtensionRpcHandler>{methodName: (Map<String, Object?> params) => 'ok'};
  }
}

class _FailingInitService extends ToolExtensionService {
  @override
  String get namespace => 'failing';

  @override
  Future<Map<String, ExtensionRpcHandler>> initialize() async {
    throw StateError('Simulated service initialize failure');
  }
}

class _NotificationTestService extends ToolExtensionService {
  _NotificationTestService({this.cancelEventsSendPort});

  final SendPort? cancelEventsSendPort;
  final _stallCompleters = <String, Completer<Object?>>{};

  @override
  String get namespace => 'notify';

  @override
  Future<Map<String, ExtensionRpcHandler>> initialize() async {
    return <String, ExtensionRpcHandler>{
      'emitCustom': (Map<String, Object?> params) {
        sendNotification('notify.customEvent', <String, Object?>{'payload': params['payload']});
        return 'emitted';
      },
      'longRunningWithProgress': (Map<String, Object?> _) async {
        final completer = Completer<String>();
        var ticks = 0;
        Timer.periodic(const Duration(milliseconds: 25), (Timer timer) {
          ticks++;
          if (ticks == 1) {
            reportProgress(
              requestId: 'notify.longRunningWithProgress',
              message: 'Step 1',
              progress: 0.5,
            );
          } else if (ticks == 2) {
            sendNotification(ToolExtensionService.heartbeatNotificationMethod, <String, Object?>{
              ToolExtensionService.requestIdKey: 'notify.longRunningWithProgress',
            });
          } else if (ticks == 3) {
            reportProgress(
              requestId: 'notify.longRunningWithProgress',
              message: 'Step 2',
              progress: 1.0,
            );
          } else {
            timer.cancel();
            completer.complete('completed-after-progress');
          }
        });
        return completer.future;
      },
      'stalledTask': (Map<String, Object?> _) {
        final completer = Completer<Object?>();
        _stallCompleters['notify.stalledTask'] = completer;
        return completer.future;
      },
    };
  }

  @override
  Future<void> onCancelRequest(Object requestId) async {
    cancelEventsSendPort?.send(requestId);
    final Completer<Object?>? completer = _stallCompleters.remove(requestId);
    if (completer != null && !completer.isCompleted) {
      completer.complete('cancelled');
    }
  }
}

void _notificationExtensionEntryPoint(SendPort sendPort) {
  unawaited(
    ToolExtensionEntryPoint.run(sendPort, <ToolExtensionService>[_NotificationTestService()]),
  );
}

void main() {
  group('ExtensionDiscovery & Connection Base', () {
    test('ExtensionConnection completes isolate handshake and retrieves capabilities', () async {
      final logger = BufferLogger.test();
      final ExtensionConnection connection = await ExtensionConnection.spawn(
        _dummyExtensionEntryPoint,
        logger: logger,
      );
      expect(connection.capabilities, isA<ToolExtensionCapabilities>());

      final discovery = ExtensionDiscovery(logger: logger);
      discovery.registerConnection(connection);
      expect(discovery.connections, hasLength(1));

      await discovery.dispose();
      expect(discovery.connections, isEmpty);
    });

    test('ExtensionConnection.spawn throws and cleans up on isolate startup failure', () async {
      final logger = BufferLogger.test();
      await expectLater(
        ExtensionConnection.spawn(_failingExtensionEntryPoint, logger: logger),
        throwsA(isA<StateError>()),
      );
    });

    test('ExtensionConnection.spawn throws when service initialize throws', () async {
      final logger = BufferLogger.test();
      await expectLater(
        ExtensionConnection.spawn(_failingServiceInitEntryPoint, logger: logger),
        throwsA(
          isA<StateError>().having(
            (StateError e) => e.message,
            'message',
            contains('Simulated service initialize failure'),
          ),
        ),
      );
    });

    test('ExtensionConnection.spawn throws when service registers duplicate RPC method', () async {
      final logger = BufferLogger.test();
      await expectLater(
        ExtensionConnection.spawn(_duplicateRpcEntryPoint, logger: logger),
        throwsA(
          isA<StateError>().having(
            (StateError e) => e.message,
            'message',
            contains('Duplicate RPC method registered: "test.ping"'),
          ),
        ),
      );
    });

    test('ExtensionDiscovery registers multiple connections and disposes them', () async {
      final logger = BufferLogger.test();
      final ExtensionConnection connection1 = await ExtensionConnection.spawn(
        _dummyExtensionEntryPoint,
        logger: logger,
      );
      final ExtensionConnection connection2 = await ExtensionConnection.spawn(
        _dummyExtensionEntryPoint,
        logger: logger,
      );

      final discovery = ExtensionDiscovery(logger: logger);
      discovery.registerConnections(<ExtensionConnection>[connection1, connection2]);

      expect(discovery.connections, hasLength(2));
      await discovery.dispose();
      expect(discovery.connections, isEmpty);
    });

    test(
      'ToolExtensionCapabilities.fromJson eagerly deserializes lists and normalizes platforms',
      () {
        final capabilities = ToolExtensionCapabilities.fromJson(const <String, Object?>{
          'services': <Object?>['diagnostics', 'config'],
          'supportedPlatforms': <Object?>['Linux', 'MacOS'],
        });

        expect(capabilities.services, const <String>['diagnostics', 'config']);
        expect(capabilities.supportedPlatforms, const <String>{'linux', 'macos'});
        expect(capabilities.supportsHostPlatform('LINUX'), isTrue);
        expect(capabilities.supportsHostPlatform('windows'), isFalse);

        final defaultPlatformsCapabilities = ToolExtensionCapabilities.fromJson(
          const <String, Object?>{
            'services': <Object?>['diagnostics'],
          },
        );
        expect(defaultPlatformsCapabilities.supportedPlatforms, isEmpty);
      },
    );

    test('ToolExtensionCapabilities.fromJson throws FormatException on invalid field types', () {
      expect(
        () => ToolExtensionCapabilities.fromJson(const <String, Object?>{
          ToolExtensionCapabilities.extensionNameKey: 42,
        }),
        throwsFormatException,
      );
      expect(
        () => ToolExtensionCapabilities.fromJson(const <String, Object?>{
          ToolExtensionCapabilities.servicesKey: 'not-a-list',
        }),
        throwsFormatException,
      );
      expect(
        () => ToolExtensionCapabilities.fromJson(const <String, Object?>{
          ToolExtensionCapabilities.supportedPlatformsKey: <Object?>[123],
        }),
        throwsFormatException,
      );
    });

    test('ToolExtensionEntryPoint.run rejects duplicate RPC method registration', () async {
      final service1 = _DummyService('test', 'ping');
      final service2 = _DummyService('test', 'ping');

      final receivePort = ReceivePort();
      addTearDown(receivePort.close);
      final messages = <Object?>[];
      final StreamSubscription<Object?> subscription = receivePort.listen(messages.add);
      addTearDown(subscription.cancel);

      await expectLater(
        ToolExtensionEntryPoint.run(receivePort.sendPort, <ToolExtensionService>[
          service1,
          service2,
        ]),
        throwsA(
          isA<StateError>().having(
            (StateError e) => e.message,
            'message',
            contains('Duplicate RPC method registered: "test.ping"'),
          ),
        ),
      );
      await pumpEventQueue();
      expect(messages, isEmpty);

      for (final reservedMethod in const <String>[
        'getCapabilities',
        'progress',
        'heartbeat',
        'cancelRequest',
      ]) {
        await expectLater(
          ToolExtensionEntryPoint.run(receivePort.sendPort, <ToolExtensionService>[
            _DummyService('extension', reservedMethod),
          ]),
          throwsA(
            isA<StateError>().having(
              (StateError e) => e.message,
              'message',
              contains('Reserved RPC method registered: "extension.$reservedMethod"'),
            ),
          ),
        );
        await pumpEventQueue();
        expect(messages, isEmpty);
      }
    });

    test('ToolExtensionService.sendNotification throws StateError before peer attachment', () {
      final service = _DummyService('test', 'ping');
      expect(
        () => service.sendNotification('test.event', const <String, Object?>{}),
        throwsStateError,
      );
    });

    test('sendNotification and onNotification deliver notifications round-trip', () async {
      final logger = BufferLogger.test();
      final ExtensionConnection connection = await ExtensionConnection.spawn(
        _notificationExtensionEntryPoint,
        logger: logger,
      );
      addTearDown(connection.dispose);

      final receivedEvents = <Map<String, Object?>>[];
      final StreamSubscription<Map<String, Object?>> subscription = connection
          .onNotification('notify.customEvent')
          .listen(receivedEvents.add);
      addTearDown(subscription.cancel);

      final Object? response = await connection.sendRequest(
        'notify.emitCustom',
        params: const <String, Object?>{'payload': 'hello-host'},
      );
      expect(response, 'emitted');

      await pumpEventQueue();
      expect(receivedEvents, <Map<String, Object?>>[
        const <String, Object?>{'payload': 'hello-host'},
      ]);
    });

    test('sendLongRunningRequest resets sliding inactivity timer on progress and heartbeat notifications', () async {
      final logger = BufferLogger.test();
      final ExtensionConnection connection = await ExtensionConnection.spawn(
        _notificationExtensionEntryPoint,
        logger: logger,
      );
      addTearDown(connection.dispose);

      final progressUpdates = <(String?, double?)>[];
      final Object? result = await connection.sendLongRunningRequest(
        'notify.longRunningWithProgress',
        inactivityTimeout: const Duration(milliseconds: 60),
        onProgress: (String? message, double? progress) {
          progressUpdates.add((message, progress));
        },
      );

      expect(result, 'completed-after-progress');
      expect(progressUpdates, const <(String?, double?)>[('Step 1', 0.5), ('Step 2', 1.0)]);
    });

    test('sendLongRunningRequest times out when no heartbeat arrives and sends extension.cancelRequest', () async {
      final logger = BufferLogger.test();
      final cancelPort = ReceivePort();
      addTearDown(cancelPort.close);
      final SendPort cancelSendPort = cancelPort.sendPort;

      void entryPointWithCancelPort(SendPort sendPort) {
        unawaited(
          ToolExtensionEntryPoint.run(sendPort, <ToolExtensionService>[
            _NotificationTestService(cancelEventsSendPort: cancelSendPort),
          ]),
        );
      }

      final ExtensionConnection connection = await ExtensionConnection.spawn(
        entryPointWithCancelPort,
        logger: logger,
      );
      addTearDown(connection.dispose);

      await expectLater(
        connection.sendLongRunningRequest(
          'notify.stalledTask',
          inactivityTimeout: const Duration(milliseconds: 40),
        ),
        throwsA(
          isA<TimeoutException>().having(
            (TimeoutException e) => e.message,
            'message',
            contains('Request "notify.stalledTask" timed out'),
          ),
        ),
      );

      final Object? cancelledRequestId = await cancelPort.first;
      expect(cancelledRequestId, 'notify.stalledTask');
    });
  });
}
