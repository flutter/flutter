// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:isolate';

import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/experimental/extension_discovery.dart';
import 'package:flutter_tools/src/experimental/extension_manager.dart';
import 'package:flutter_tools_extension/flutter_tools_extension.dart';
import 'package:test/test.dart';

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
    test('ExtensionManager loads extension compatible with hostPlatform', () async {
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

    test('ExtensionManager filters out extension incompatible with hostPlatform', () async {
      final logger = BufferLogger.test();
      final manager = ExtensionManager(
        hostPlatform: HostPlatform.darwin_arm64,
        logger: logger,
        featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
      );
      await manager.initialize(entryPoints: <ExtensionEntryPoint>[_linuxOnlyExtensionEntryPoint]);

      expect(manager.connections, isEmpty);
      await manager.dispose();
    });

    test('isSafeMode and FLUTTER_NO_EXTENSIONS=1 bypass discovery and spawning', () async {
      final logger = BufferLogger.test();
      var spawned = false;

      final safeModeManager = ExtensionManager(
        hostPlatform: HostPlatform.linux_x64,
        logger: logger,
        featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
        platform: FakePlatform(environment: const <String, String>{'FLUTTER_NO_EXTENSIONS': '1'}),
        entryPoints: <ExtensionEntryPoint>[
          (SendPort sendPort) {
            spawned = true;
            _dummyExtensionEntryPoint(sendPort);
          },
        ],
      );

      expect(safeModeManager.isSafeMode, isTrue);
      await safeModeManager.ensureInitialized();
      expect(spawned, isFalse);
      expect(safeModeManager.connections, isEmpty);
      await safeModeManager.dispose();
    });
  });
}
