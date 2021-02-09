// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/linux/application_package.dart';
import 'package:flutter_tools/src/linux/linux_device.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:mockito/mockito.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/testbed.dart';

final FakePlatform linux = FakePlatform(
  operatingSystem: 'linux',
);
final FakePlatform windows = FakePlatform(
  operatingSystem: 'windows',
);

final List<HostPlatform> hostPlatforms = <HostPlatform>[
  HostPlatform.linux_x64,
  HostPlatform.linux_arm64,
];

void main() {

  testWithoutContext('LinuxDevice defaults', () async {
    for (final HostPlatform hostPlatform in hostPlatforms) {
      final LinuxDevice device = LinuxDevice(
        processManager: FakeProcessManager.any(),
        logger: BufferLogger.test(),
        fileSystem: MemoryFileSystem.test(),
        operatingSystemUtils: FakeOperatingSystemUtils(hostPlatform: hostPlatform),
      );

      final PrebuiltLinuxApp linuxApp = PrebuiltLinuxApp(executable: 'foo');
      expect(
          await device.targetPlatform,
          hostPlatform == HostPlatform.linux_x64
              ? TargetPlatform.linux_x64
              : TargetPlatform.linux_arm64);
      expect(device.name, 'Linux');
      expect(await device.installApp(linuxApp), true);
      expect(await device.uninstallApp(linuxApp), true);
      expect(await device.isLatestBuildInstalled(linuxApp), true);
      expect(await device.isAppInstalled(linuxApp), true);
      expect(await device.stopApp(linuxApp), true);
      expect(device.category, Category.desktop);

      expect(device.supportsRuntimeMode(BuildMode.debug), true);
      expect(device.supportsRuntimeMode(BuildMode.profile), true);
      expect(device.supportsRuntimeMode(BuildMode.release), true);
      expect(device.supportsRuntimeMode(BuildMode.jitRelease), false);
    }
  });

  testWithoutContext('LinuxDevice: no devices listed if platform unsupported', () async {
    for (final HostPlatform hostPlatform in hostPlatforms) {
      expect(await LinuxDevices(
        fileSystem: MemoryFileSystem.test(),
        platform: windows,
        featureFlags: TestFeatureFlags(isLinuxEnabled: true),
        logger: BufferLogger.test(),
        processManager: FakeProcessManager.any(),
        operatingSystemUtils: FakeOperatingSystemUtils(hostPlatform: hostPlatform),
      ).devices, <Device>[]);
    }
  });

  testWithoutContext('LinuxDevice: no devices listed if Linux feature flag disabled', () async {
    for (final HostPlatform hostPlatform in hostPlatforms) {
      expect(await LinuxDevices(
        fileSystem: MemoryFileSystem.test(),
        platform: linux,
        featureFlags: TestFeatureFlags(isLinuxEnabled: false),
        logger: BufferLogger.test(),
        processManager: FakeProcessManager.any(),
        operatingSystemUtils: FakeOperatingSystemUtils(hostPlatform: hostPlatform),
      ).devices, <Device>[]);
    }
  });

  testWithoutContext('LinuxDevice: devices', () async {
    for (final HostPlatform hostPlatform in hostPlatforms) {
      expect(await LinuxDevices(
        fileSystem: MemoryFileSystem.test(),
        platform: linux,
        featureFlags: TestFeatureFlags(isLinuxEnabled: true),
        logger: BufferLogger.test(),
        processManager: FakeProcessManager.any(),
        operatingSystemUtils: FakeOperatingSystemUtils(hostPlatform: hostPlatform),
      ).devices, hasLength(1));
    }
  });

  testWithoutContext('LinuxDevice: discoverDevices', () async {
    // Timeout ignored.
    for (final HostPlatform hostPlatform in hostPlatforms) {
      final List<Device> devices = await LinuxDevices(
        fileSystem: MemoryFileSystem.test(),
        platform: linux,
        featureFlags: TestFeatureFlags(isLinuxEnabled: true),
        logger: BufferLogger.test(),
        processManager: FakeProcessManager.any(),
        operatingSystemUtils: FakeOperatingSystemUtils(hostPlatform: hostPlatform),
      ).discoverDevices(timeout: const Duration(seconds: 10));
      expect(devices, hasLength(1));
    }
  });

  testWithoutContext('LinuxDevice.isSupportedForProject is true with editable host app', () async {
    for (final HostPlatform hostPlatform in hostPlatforms) {
      final FileSystem fileSystem = MemoryFileSystem.test();
      fileSystem.file('pubspec.yaml').createSync();
      fileSystem.file('.packages').createSync();
      fileSystem.directory('linux').createSync();
      final FlutterProject flutterProject = setUpFlutterProject(fileSystem.currentDirectory);

      expect(LinuxDevice(
        logger: BufferLogger.test(),
        processManager: FakeProcessManager.any(),
        fileSystem: fileSystem,
        operatingSystemUtils: FakeOperatingSystemUtils(hostPlatform: hostPlatform),
      ).isSupportedForProject(flutterProject), true);
    }
  });

  testWithoutContext('LinuxDevice.isSupportedForProject is false with no host app', () async {
    for (final HostPlatform hostPlatform in hostPlatforms) {
      final FileSystem fileSystem = MemoryFileSystem.test();
      fileSystem.file('pubspec.yaml').createSync();
      fileSystem.file('.packages').createSync();
      final FlutterProject flutterProject = setUpFlutterProject(fileSystem.currentDirectory);

      expect(LinuxDevice(
        logger: BufferLogger.test(),
        processManager: FakeProcessManager.any(),
        fileSystem: fileSystem,
        operatingSystemUtils: FakeOperatingSystemUtils(hostPlatform: hostPlatform),
      ).isSupportedForProject(flutterProject), false);
    }
  });

  testWithoutContext('LinuxDevice.executablePathForDevice uses the correct package executable', () async {
    for (final HostPlatform hostPlatform in hostPlatforms) {
      final MockLinuxApp mockApp = MockLinuxApp();
      final LinuxDevice device = LinuxDevice(
        logger: BufferLogger.test(),
        processManager: FakeProcessManager.any(),
        fileSystem: MemoryFileSystem.test(),
        operatingSystemUtils: FakeOperatingSystemUtils(hostPlatform: hostPlatform),
      );
      const String debugPath = 'debug/executable';
      const String profilePath = 'profile/executable';
      const String releasePath = 'release/executable';
      when(mockApp.executable(BuildMode.debug)).thenReturn(debugPath);
      when(mockApp.executable(BuildMode.profile)).thenReturn(profilePath);
      when(mockApp.executable(BuildMode.release)).thenReturn(releasePath);

      expect(device.executablePathForDevice(mockApp, BuildMode.debug), debugPath);
      expect(device.executablePathForDevice(mockApp, BuildMode.profile), profilePath);
      expect(device.executablePathForDevice(mockApp, BuildMode.release), releasePath);
    }
  });
}

FlutterProject setUpFlutterProject(Directory directory) {
  final FlutterProjectFactory flutterProjectFactory = FlutterProjectFactory(
    fileSystem: directory.fileSystem,
    logger: BufferLogger.test(),
  );
  return flutterProjectFactory.fromDirectory(directory);
}

class MockLinuxApp extends Mock implements LinuxApp {}
class FakeOperatingSystemUtils extends Fake implements OperatingSystemUtils {
  FakeOperatingSystemUtils({
    HostPlatform hostPlatform = HostPlatform.linux_x64
  })  : _hostPlatform = hostPlatform;

  final HostPlatform _hostPlatform;

  @override
  String get name => 'Linux';

  @override
  HostPlatform get hostPlatform => _hostPlatform;
}
