// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:isolate';

import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/experimental/extension_discovery.dart';
import 'package:flutter_tools/src/experimental/extension_manager.dart';
import 'package:flutter_tools_extension/flutter_tools_extension.dart';

import '../../src/common.dart';
import '../../src/fakes.dart';

void _dummyExtensionEntryPoint(SendPort sendPort) {
  ToolExtensionEntryPoint.run(sendPort, <ToolExtensionService>[]);
}

void _linuxOnlyExtensionEntryPoint(SendPort sendPort) {
  ToolExtensionEntryPoint.run(
    sendPort,
    <ToolExtensionService>[],
    supportedPlatforms: const <String>{'linux'},
  );
}

void main() {
  group('ExtensionManager Integration', () {
    testWithoutContext('ExtensionManager loads extension compatible with hostPlatform', () async {
      final logger = BufferLogger.test();
      final manager = ExtensionManager(
        hostPlatform: HostPlatform.linux_x64,
        logger: logger,
        featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
      );
      await manager.initialize(entryPoints: <ExtensionEntryPoint>[_dummyExtensionEntryPoint]);

      expect(manager.connections, hasLength(1));
      await manager.dispose();
      expect(manager.connections, isEmpty);
    });

    testWithoutContext(
      'ExtensionManager filters out extension incompatible with hostPlatform',
      () async {
        final logger = BufferLogger.test();
        final manager = ExtensionManager(
          hostPlatform: HostPlatform.darwin_arm64,
          logger: logger,
          featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
        );
        await manager.initialize(entryPoints: <ExtensionEntryPoint>[_linuxOnlyExtensionEntryPoint]);

        expect(manager.connections, isEmpty);
        await manager.dispose();
      },
    );

    testWithoutContext(
      'ensureInitialized skips spawning when tool extensions are disabled',
      () async {
        final logger = BufferLogger.test();
        var spawned = false;

        final disabledManager = ExtensionManager(
          hostPlatform: HostPlatform.linux_x64,
          logger: logger,
          featureFlags: TestFeatureFlags(),
          entryPoints: <ExtensionEntryPoint>[
            (SendPort sendPort) {
              spawned = true;
              _dummyExtensionEntryPoint(sendPort);
            },
          ],
        );

        await disabledManager.ensureInitialized();
        expect(spawned, isFalse);
        expect(disabledManager.connections, isEmpty);
        await disabledManager.dispose();
      },
    );

    testWithoutContext(
      'disable throws AssertionError when called after initialization has started',
      () async {
        final logger = BufferLogger.test();
        final manager = ExtensionManager(
          hostPlatform: HostPlatform.linux_x64,
          logger: logger,
          featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
        );
        await manager.ensureInitialized();
        expect(() => manager.disable(), throwsA(isA<AssertionError>()));
        await manager.dispose();
      },
    );
  });
}
