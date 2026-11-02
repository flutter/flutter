// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/signals.dart';
import 'package:flutter_tools/src/experimental/extension_discovery.dart';
import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_extension/flutter_tools_extension.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

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
  @override
  String get namespace => 'notify';

  @override
  Future<Map<String, ExtensionRpcHandler>> initialize() async {
    return <String, ExtensionRpcHandler>{
      'emitCustom': (Map<String, Object?> params) {
        sendNotification('notify.customEvent', <String, Object?>{'payload': params['payload']});
        return 'emitted';
      },
    };
  }
}

void _notificationExtensionEntryPoint(SendPort sendPort) {
  unawaited(
    ToolExtensionEntryPoint.run(sendPort, <ToolExtensionService>[_NotificationTestService()]),
  );
}

class _ExitingService extends ToolExtensionService {
  @override
  String get namespace => 'exit';

  @override
  Future<Map<String, ExtensionRpcHandler>> initialize() async {
    return <String, ExtensionRpcHandler>{
      'triggerExit': (Map<String, Object?> _) {
        Isolate.exit();
      },
    };
  }
}

void _exitingExtensionEntryPoint(SendPort sendPort) {
  unawaited(ToolExtensionEntryPoint.run(sendPort, <ToolExtensionService>[_ExitingService()]));
}

class _AsyncErrorService extends ToolExtensionService {
  @override
  String get namespace => 'error';

  @override
  Future<Map<String, ExtensionRpcHandler>> initialize() async {
    return <String, ExtensionRpcHandler>{
      'triggerUnhandledError': (Map<String, Object?> _) {
        Timer.run(() {
          throw StateError('Simulated unhandled async error');
        });
        return Completer<Object?>().future;
      },
    };
  }
}

void _asyncErrorExtensionEntryPoint(SendPort sendPort) {
  unawaited(ToolExtensionEntryPoint.run(sendPort, <ToolExtensionService>[_AsyncErrorService()]));
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

      await expectLater(
        ToolExtensionEntryPoint.run(receivePort.sendPort, <ToolExtensionService>[
          _DummyService('extension', 'getCapabilities'),
        ]),
        throwsA(
          isA<StateError>().having(
            (StateError e) => e.message,
            'message',
            contains('Reserved RPC method registered: "extension.getCapabilities"'),
          ),
        ),
      );
      await pumpEventQueue();
      expect(messages, isEmpty);
    });

    test('ToolExtensionEntryPoint.run validates SendPort message', () async {
      await expectLater(
        ToolExtensionEntryPoint.run('not-a-send-port', <ToolExtensionService>[]),
        throwsArgumentError,
      );
    });

    test('ExtensionConnection.spawnUri spawns extension script and completes handshake', () async {
      final logger = BufferLogger.test();
      final Uri? libUri = await Isolate.resolvePackageUri(
        Uri.parse(
          'package:flutter_tools_extension_linux_prototype/flutter_tools_extension_linux_prototype.dart',
        ),
      );
      expect(libUri, isNotNull);
      final Uri entrypointUri = libUri!.resolve(
        '../bin/flutter_tools_extension_linux_prototype.dart',
      );
      final Uri? packageConfigUri = await Isolate.packageConfig;
      expect(packageConfigUri, isNotNull);

      final fs = LocalFileSystem.test(signals: LocalSignals.instance);
      addTearDown(fs.dispose);
      final Uri configUri = libUri.resolve('../extension/flutter_tools/config.yaml');
      final rawYaml = loadYaml(fs.file(configUri).readAsStringSync()) as YamlMap;
      final expectedConfig = ExtensionPackageConfig.fromMap(
        rawYaml.cast<String, Object?>(),
        packageName: 'flutter_tools_extension_linux_prototype',
      );

      final ExtensionConnection connection = await ExtensionConnection.spawnUri(
        entrypointUri,
        expectedConfig: expectedConfig,
        logger: logger,
        packageConfigUri: packageConfigUri!,
        extensionName: 'flutter_tools_extension_linux_prototype',
      );
      addTearDown(connection.dispose);

      expect(connection.extensionName, 'flutter_tools_extension_linux_prototype');
      expect(
        connection.capabilities.services,
        containsAll(const <String>['diagnostics', 'config', 'build', 'template']),
      );
    });

    test('ExtensionConnection.spawnUri throws StateError when expectedConfig does not match capabilities', () async {
      final logger = BufferLogger.test();
      final Uri? libUri = await Isolate.resolvePackageUri(
        Uri.parse(
          'package:flutter_tools_extension_linux_prototype/flutter_tools_extension_linux_prototype.dart',
        ),
      );
      expect(libUri, isNotNull);
      final Uri entrypointUri = libUri!.resolve(
        '../bin/flutter_tools_extension_linux_prototype.dart',
      );
      final Uri? packageConfigUri = await Isolate.packageConfig;
      expect(packageConfigUri, isNotNull);

      await expectLater(
        ExtensionConnection.spawnUri(
          entrypointUri,
          expectedConfig: ExtensionPackageConfig(
            name: 'flutter_tools_extension_linux_prototype',
            hostPlatforms: const <String>{'linux'},
            services: const <String>{'diagnostics'},
          ),
          logger: logger,
          packageConfigUri: packageConfigUri!,
        ),
        throwsA(
          isA<StateError>().having(
            (StateError e) => e.message,
            'message',
            contains(
              'capabilities mismatch: extension/flutter_tools/config.yaml declares services',
            ),
          ),
        ),
      );

      await expectLater(
        ExtensionConnection.spawnUri(
          entrypointUri,
          expectedConfig: ExtensionPackageConfig(
            name: 'flutter_tools_extension_linux_prototype',
            hostPlatforms: const <String>{'macos'},
            services: const <String>{
              'diagnostics',
              'config',
              'template',
              'device',
              'build',
              'clean',
            },
          ),
          logger: logger,
          packageConfigUri: packageConfigUri,
        ),
        throwsA(
          isA<StateError>().having(
            (StateError e) => e.message,
            'message',
            contains(
              'capabilities mismatch: extension/flutter_tools/config.yaml declares host_platforms',
            ),
          ),
        ),
      );
    });

    test('ToolExtensionService.sendNotification throws StateError before peer attachment', () {
      final service = _DummyService('test', 'ping');
      expect(
        () => service.sendNotification('test.event', const <String, Object?>{}),
        throwsA(
          isA<StateError>().having(
            (StateError e) => e.message,
            'message',
            contains('is not attached to an active peer'),
          ),
        ),
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

    test('onNotification supports multiple listeners on broadcast stream', () async {
      final logger = BufferLogger.test();
      final ExtensionConnection connection = await ExtensionConnection.spawn(
        _notificationExtensionEntryPoint,
        logger: logger,
      );
      addTearDown(connection.dispose);

      final listener1Events = <Map<String, Object?>>[];
      final listener2Events = <Map<String, Object?>>[];

      final Stream<Map<String, Object?>> stream = connection.onNotification('notify.customEvent');
      final StreamSubscription<Map<String, Object?>> sub1 = stream.listen(listener1Events.add);
      final StreamSubscription<Map<String, Object?>> sub2 = stream.listen(listener2Events.add);
      addTearDown(sub1.cancel);
      addTearDown(sub2.cancel);

      await connection.sendRequest(
        'notify.emitCustom',
        params: const <String, Object?>{'payload': 'broadcast'},
      );

      await pumpEventQueue();
      expect(listener1Events, <Map<String, Object?>>[
        const <String, Object?>{'payload': 'broadcast'},
      ]);
      expect(listener2Events, <Map<String, Object?>>[
        const <String, Object?>{'payload': 'broadcast'},
      ]);
    });

    test('onNotification throws StateError after dispose', () async {
      final logger = BufferLogger.test();
      final ExtensionConnection connection = await ExtensionConnection.spawn(
        _dummyExtensionEntryPoint,
        logger: logger,
      );
      await connection.dispose();

      expect(
        () => connection.onNotification('notify.customEvent'),
        throwsA(
          isA<StateError>().having(
            (StateError e) => e.message,
            'message',
            contains('ExtensionConnection has been disposed.'),
          ),
        ),
      );
    });

    test(
      'sendRequest with timeout: null completes with StateError when isolate exits unexpectedly',
      () async {
        final logger = BufferLogger.test();
        final ExtensionConnection connection = await ExtensionConnection.spawn(
          _exitingExtensionEntryPoint,
          logger: logger,
        );
        addTearDown(connection.dispose);

        final Stream<Map<String, Object?>> notificationStream = connection.onNotification(
          'notify.customEvent',
        );
        final Future<void> streamDone = expectLater(notificationStream, emitsDone);

        await expectLater(
          connection.sendRequest('exit.triggerExit', timeout: null),
          throwsA(
            isA<StateError>().having(
              (StateError e) => e.message,
              'message',
              contains('The client closed with pending request "exit.triggerExit"'),
            ),
          ),
        );
        await streamDone;
      },
    );

    test('sendRequest with timeout: null completes with StateError when isolate throws unhandled async error', () async {
      final logger = BufferLogger.test();
      final ExtensionConnection connection = await ExtensionConnection.spawn(
        _asyncErrorExtensionEntryPoint,
        logger: logger,
      );
      addTearDown(connection.dispose);

      await expectLater(
        connection.sendRequest('error.triggerUnhandledError', timeout: null),
        throwsA(
          isA<StateError>().having(
            (StateError e) => e.message,
            'message',
            contains('The client closed with pending request "error.triggerUnhandledError"'),
          ),
        ),
      );
      expect(logger.errorText, contains('Simulated unhandled async error'));
    });
  });
}
