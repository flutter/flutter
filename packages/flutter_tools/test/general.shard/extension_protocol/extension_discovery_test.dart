// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:isolate';

import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/experimental/extension_discovery.dart';
import 'package:flutter_tools_extension/flutter_tools_extension.dart';
import 'package:test/test.dart';

void _dummyExtensionEntryPoint(SendPort sendPort) {
  ToolExtensionEntryPoint.run(sendPort, <ToolExtensionService>[]);
}

void _failingExtensionEntryPoint(SendPort sendPort) {
  // Throws during isolate initialization before handshake.
  throw StateError('Simulated isolate startup failure');
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

    test('ExtensionDiscovery spawnAll manages multiple extensions', () async {
      final logger = BufferLogger.test();
      final discovery = ExtensionDiscovery(logger: logger);
      final List<ExtensionConnection> connections = await discovery.spawnAll(<ExtensionEntryPoint>[
        _dummyExtensionEntryPoint,
        _dummyExtensionEntryPoint,
      ]);

      expect(connections, hasLength(2));
      expect(discovery.connections, hasLength(2));

      await discovery.dispose();
      expect(discovery.connections, isEmpty);
    });

    test(
      'ExtensionDiscovery spawnAll handles individual failure without failing entire batch',
      () async {
        final logger = BufferLogger.test();
        final discovery = ExtensionDiscovery(logger: logger);
        final List<ExtensionConnection> connections = await discovery.spawnAll(
          <ExtensionEntryPoint>[_dummyExtensionEntryPoint, _failingExtensionEntryPoint],
        );

        expect(connections, hasLength(1));
        expect(discovery.connections, hasLength(1));
        expect(logger.errorText, contains('Failed to spawn extension'));

        await discovery.dispose();
        expect(discovery.connections, isEmpty);
      },
    );

    test('ToolExtensionCapabilities.fromJson eagerly deserializes lists', () {
      final capabilities = ToolExtensionCapabilities.fromJson(const <String, Object?>{
        'services': <Object?>['diagnostics', 'config'],
        'supportedPlatforms': <Object?>['linux', 'macos'],
      });

      expect(capabilities.services, const <String>['diagnostics', 'config']);
      expect(capabilities.supportedPlatforms, const <String>['linux', 'macos']);
    });

    test('ToolExtensionEntryPoint.run rejects duplicate RPC method registration', () async {
      final service1 = _DummyService('test', 'ping');
      final service2 = _DummyService('test', 'ping');

      final receivePort = ReceivePort();
      addTearDown(receivePort.close);

      expect(
        () => ToolExtensionEntryPoint.run(receivePort.sendPort, <ToolExtensionService>[
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
    });
  });
}
