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
  });
}
