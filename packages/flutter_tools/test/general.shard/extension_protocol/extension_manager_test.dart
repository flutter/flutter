// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:isolate';

import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/experimental/extension_discovery.dart';
import 'package:flutter_tools/src/experimental/extension_manager.dart';
import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_extension/flutter_tools_extension.dart';
import 'package:test/test.dart';

import '../../src/fakes.dart';

final class _FakeDeviceService extends DeviceService {
  @override
  Future<List<TargetDevice>> getDevices() async => const <TargetDevice>[];

  @override
  Future<bool> isSupportedForProject({required String deviceId, required Uri projectRoot}) async =>
      false;

  @override
  Future<bool> launchApp({
    required String deviceId,
    required String executablePath,
    ExtensionDebuggingOptions? debuggingOptions,
  }) async => false;

  @override
  Future<Uri?> getVmServiceUri({required String deviceId}) async => null;

  @override
  Future<bool> stopApp({required String deviceId}) async => false;
}

void _dummyExtensionEntryPoint(SendPort sendPort) {
  ToolExtensionEntryPoint.run(sendPort, <ToolExtensionService>[]);
}

void _deviceExtensionEntryPoint(SendPort sendPort) {
  ToolExtensionEntryPoint.run(sendPort, <ToolExtensionService>[_FakeDeviceService()]);
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

    test(
      'ExtensionManager.ensureInitialized does not permanently memoize an empty pre-pub-get state',
      () async {
        final logger = BufferLogger.test();
        final discovery = ExtensionDiscovery(logger: logger);
        final manager = ExtensionManager(
          hostPlatform: HostPlatform.linux_x64,
          logger: logger,
          discovery: discovery,
          featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
        );

        await manager.ensureInitialized();
        expect(manager.isInitialized, isTrue);
        expect(manager.deviceExtensions, isEmpty);

        final ExtensionConnection connection = await ExtensionConnection.spawn(
          _deviceExtensionEntryPoint,
          logger: logger,
        );
        discovery.registerConnection(connection);

        await manager.ensureInitialized();
        expect(manager.deviceExtensions, hasLength(1));

        await manager.dispose();
      },
    );

    test(
      'ExtensionManager.ensureInitialized is idempotent when connections do not change',
      () async {
        final logger = BufferLogger.test();
        final manager = ExtensionManager(
          hostPlatform: HostPlatform.linux_x64,
          logger: logger,
          entryPoints: <ExtensionEntryPoint>[_dummyExtensionEntryPoint],
          featureFlags: TestFeatureFlags(isToolExtensionsEnabled: true),
        );

        final Future<void> firstInit = manager.ensureInitialized();
        await firstInit;
        expect(manager.connections, hasLength(1));

        final Future<void> secondInit = manager.ensureInitialized();
        expect(identical(firstInit, secondInit), isTrue);

        await manager.dispose();
      },
    );
  });
}
