// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/base/time.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/config.dart';
import 'package:flutter_tools/src/doctor.dart';
import 'package:flutter_tools/src/experimental/extension_discovery.dart';
import 'package:flutter_tools/src/experimental/extension_manager.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools_extension_linux_prototype/flutter_tools_extension_linux_prototype.dart';

import '../../src/context.dart';
import '../../src/fakes.dart';
import '../../src/test_flutter_command_runner.dart';

void main() {
  setUpAll(() {
    Cache.disableLocking();
  });

  group('Tool Extensions Integration - Disabled', () {
    testUsingContext(
      'ExtensionManager.ensureInitialized() is a no-op when feature flag disabled',
      () async {
        final featureFlags = TestFeatureFlags();
        final manager = ExtensionManager(
          hostPlatform: HostPlatform.linux_x64,
          logger: testLogger,
          entryPoints: <ExtensionEntryPoint>[linuxExtensionEntryPoint],
          featureFlags: featureFlags,
        );

        await manager.ensureInitialized();
        expect(manager.connections, isEmpty);
        await manager.dispose();
      },
      overrides: <Type, Generator>{FeatureFlags: () => TestFeatureFlags()},
    );

    testUsingContext(
      'ConfigCommand does not output Extension Settings when feature flag disabled',
      () async {
        final featureFlags = TestFeatureFlags();
        final manager = ExtensionManager(
          hostPlatform: HostPlatform.linux_x64,
          logger: testLogger,
          entryPoints: <ExtensionEntryPoint>[linuxExtensionEntryPoint],
          featureFlags: featureFlags,
        );
        final configCommand = ConfigCommand(
          androidContext: FakeAndroidContext(),
          toolContext: FakeToolContext(logger: testLogger),
          featureFlags: featureFlags,
          extensionManager: manager,
        );
        final CommandRunner<void> commandRunner = createTestCommandRunner(configCommand);

        await commandRunner.run(<String>['config', '--list']);
        expect(testLogger.statusText, isNot(contains('Extension Settings:')));

        await manager.dispose();
      },
      overrides: <Type, Generator>{FeatureFlags: () => TestFeatureFlags()},
    );

    testUsingContext(
      'Doctor.diagnose does not execute extension validators when feature flag disabled',
      () async {
        final featureFlags = TestFeatureFlags();
        final manager = ExtensionManager(
          hostPlatform: HostPlatform.linux_x64,
          logger: testLogger,
          entryPoints: <ExtensionEntryPoint>[linuxExtensionEntryPoint],
          featureFlags: featureFlags,
        );
        final doctor = Doctor(logger: testLogger, clock: const SystemClock());

        await doctor.diagnose(extensionManager: manager);
        expect(testLogger.statusText, isNot(contains('Linux Custom Extension Prototype')));

        await manager.dispose();
      },
      overrides: <Type, Generator>{FeatureFlags: () => TestFeatureFlags()},
    );
  });

  group('Tool Extensions Integration - Enabled', () {
    testUsingContext(
      'ExtensionManager.ensureInitialized() initializes connections when feature flag enabled',
      () async {
        final featureFlags = TestFeatureFlags(isToolExtensionsEnabled: true);
        final manager = ExtensionManager(
          hostPlatform: HostPlatform.linux_x64,
          logger: testLogger,
          entryPoints: <ExtensionEntryPoint>[linuxExtensionEntryPoint],
          featureFlags: featureFlags,
        );

        await manager.ensureInitialized();
        expect(manager.connections, isNotEmpty);
        await manager.dispose();
      },
      overrides: <Type, Generator>{
        FeatureFlags: () => TestFeatureFlags(isToolExtensionsEnabled: true),
      },
    );

    testUsingContext(
      'ConfigCommand outputs Extension Settings when feature flag enabled',
      () async {
        final featureFlags = TestFeatureFlags(isToolExtensionsEnabled: true);
        final manager = ExtensionManager(
          hostPlatform: HostPlatform.linux_x64,
          logger: testLogger,
          entryPoints: <ExtensionEntryPoint>[linuxExtensionEntryPoint],
          featureFlags: featureFlags,
        );
        final configCommand = ConfigCommand(
          androidContext: FakeAndroidContext(),
          toolContext: FakeToolContext(logger: testLogger),
          featureFlags: featureFlags,
          extensionManager: manager,
        );
        final CommandRunner<void> commandRunner = createTestCommandRunner(configCommand);

        await commandRunner.run(<String>['config', '--list']);
        expect(testLogger.statusText, contains('Extension Settings:'));

        await manager.dispose();
      },
      overrides: <Type, Generator>{
        FeatureFlags: () => TestFeatureFlags(isToolExtensionsEnabled: true),
      },
    );

    testUsingContext(
      'Doctor.diagnose executes extension validators when feature flag enabled',
      () async {
        final featureFlags = TestFeatureFlags(isToolExtensionsEnabled: true);
        final manager = ExtensionManager(
          hostPlatform: HostPlatform.linux_x64,
          logger: testLogger,
          entryPoints: <ExtensionEntryPoint>[linuxExtensionEntryPoint],
          featureFlags: featureFlags,
        );
        final doctor = Doctor(logger: testLogger, clock: const SystemClock());

        await doctor.diagnose(extensionManager: manager);
        expect(testLogger.statusText, contains('[✓] Linux Custom Extension Prototype'));

        await manager.dispose();
      },
      overrides: <Type, Generator>{
        FeatureFlags: () => TestFeatureFlags(isToolExtensionsEnabled: true),
      },
    );
  });
}
