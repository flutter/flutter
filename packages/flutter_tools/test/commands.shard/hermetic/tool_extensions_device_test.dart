// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/devices.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/experimental/extension_device_manager.dart';
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

  group('Tool Extensions Device Integration - Disabled', () {
    testUsingContext(
      'ExtensionDeviceDiscovery returns empty device list when feature flag disabled',
      () async {
        final featureFlags = TestFeatureFlags();
        final manager = ExtensionManager(
          hostPlatform: HostPlatform.linux_x64,
          logger: testLogger,
          entryPoints: <ExtensionEntryPoint>[linuxExtensionEntryPoint],
          featureFlags: featureFlags,
        );
        final discovery = ExtensionDeviceDiscovery(extensionManager: manager, logger: testLogger);

        final List<Device> devices = await discovery.devices();
        expect(devices, isEmpty);

        await manager.dispose();
      },
      overrides: <Type, Generator>{FeatureFlags: () => TestFeatureFlags()},
    );

    ExtensionManager? disabledManager;
    testUsingContext(
      'DevicesCommand output does not include custom extension devices when feature flag disabled',
      () async {
        final featureFlags = TestFeatureFlags();
        disabledManager = ExtensionManager(
          hostPlatform: HostPlatform.linux_x64,
          logger: testLogger,
          entryPoints: <ExtensionEntryPoint>[linuxExtensionEntryPoint],
          featureFlags: featureFlags,
        );
        final devicesCommand = DevicesCommand();
        final CommandRunner<void> commandRunner = createTestCommandRunner(devicesCommand);

        await commandRunner.run(<String>['devices']);
        expect(testLogger.statusText, isNot(contains('Linux Custom Extension Prototype Device')));

        await disabledManager?.dispose();
      },
      overrides: <Type, Generator>{
        FeatureFlags: () => TestFeatureFlags(),
        ExtensionManager: () => disabledManager,
        DeviceManager: () => TestDeviceManager(),
      },
    );
  });

  group('Tool Extensions Device Integration - Enabled', () {
    testUsingContext(
      'ExtensionDeviceDiscovery discovers custom device when feature flag enabled',
      () async {
        final featureFlags = TestFeatureFlags(isToolExtensionsEnabled: true);
        final manager = ExtensionManager(
          hostPlatform: HostPlatform.linux_x64,
          logger: testLogger,
          entryPoints: <ExtensionEntryPoint>[linuxExtensionEntryPoint],
          featureFlags: featureFlags,
        );
        final discovery = ExtensionDeviceDiscovery(extensionManager: manager, logger: testLogger);

        final List<Device> devices = await discovery.devices();
        expect(devices, hasLength(1));
        expect(devices.first.id, equals('custom_linux_device'));
        expect(devices.first.name, equals('Linux Custom Extension Prototype Device'));
        expect(devices.first.category, equals(Category.desktop));
        expect(devices.first.platformType, equals(PlatformType.custom));
        expect(await devices.first.targetPlatform, equals(TargetPlatform.linux_x64));
        expect(await devices.first.sdkNameAndVersion, equals('Custom Linux 1.0.0'));
        expect(await devices.first.isSupported(), isTrue);

        await manager.dispose();
      },
      overrides: <Type, Generator>{
        FeatureFlags: () => TestFeatureFlags(isToolExtensionsEnabled: true),
      },
    );

    ExtensionManager? enabledManager;
    testUsingContext(
      'DevicesCommand output includes custom extension device when feature flag enabled',
      () async {
        final featureFlags = TestFeatureFlags(isToolExtensionsEnabled: true);
        enabledManager = ExtensionManager(
          hostPlatform: HostPlatform.linux_x64,
          logger: testLogger,
          entryPoints: <ExtensionEntryPoint>[linuxExtensionEntryPoint],
          featureFlags: featureFlags,
        );
        final devicesCommand = DevicesCommand();
        final CommandRunner<void> commandRunner = createTestCommandRunner(devicesCommand);

        await commandRunner.run(<String>['devices']);
        expect(testLogger.statusText, contains('Linux Custom Extension Prototype Device'));

        await enabledManager?.dispose();
      },
      overrides: <Type, Generator>{
        FeatureFlags: () => TestFeatureFlags(isToolExtensionsEnabled: true),
        ExtensionManager: () => enabledManager,
        DeviceManager: () => TestDeviceManager(),
      },
    );
  });
}

class TestDeviceManager extends DeviceManager {
  TestDeviceManager({List<DeviceDiscovery>? discoverers, ExtensionManager? extensionManager})
    : deviceDiscoverers =
          discoverers ??
          <DeviceDiscovery>[
            if (extensionManager ?? context.get<ExtensionManager>()
                case final ExtensionManager manager)
              ExtensionDeviceDiscovery(extensionManager: manager, logger: testLogger),
          ],
      super(logger: testLogger);

  @override
  final List<DeviceDiscovery> deviceDiscoverers;
}
