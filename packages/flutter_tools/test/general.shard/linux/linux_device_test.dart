// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
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

void main() {

  testWithoutContext('LinuxDevice defaults', () async {
    final LinuxDevice device = LinuxDevice(
      processManager: FakeProcessManager.any(),
      logger: BufferLogger.test(),
    );

    final PrebuiltLinuxApp linuxApp = PrebuiltLinuxApp(executable: 'foo');
    expect(await device.targetPlatform, TargetPlatform.linux_x64);
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
  });

  testWithoutContext('LinuxDevice: no devices listed if platform unsupported', () async {
    expect(await LinuxDevices(
      platform: windows,
      featureFlags: TestFeatureFlags(isLinuxEnabled: true),
      logger: BufferLogger.test(),
      processManager: FakeProcessManager.any(),
    ).devices, <Device>[]);
  });

  testWithoutContext('LinuxDevice: no devices listed if Linux feature flag disabled', () async {
    expect(await LinuxDevices(
      platform: linux,
      featureFlags: TestFeatureFlags(isLinuxEnabled: false),
      logger: BufferLogger.test(),
      processManager: FakeProcessManager.any(),
    ).devices, <Device>[]);
  });

  testWithoutContext('LinuxDevice: devices', () async {
    expect(await LinuxDevices(
      platform: linux,
      featureFlags: TestFeatureFlags(isLinuxEnabled: true),
      logger: BufferLogger.test(),
      processManager: FakeProcessManager.any(),
    ).devices, hasLength(1));
  });

  testWithoutContext('LinuxDevice: discoverDevices', () async {
    // Timeout ignored.
    final List<Device> devices = await LinuxDevices(
      platform: linux,
      featureFlags: TestFeatureFlags(isLinuxEnabled: true),
      logger: BufferLogger.test(),
      processManager: FakeProcessManager.any(),
    ).discoverDevices(timeout: const Duration(seconds: 10));
    expect(devices, hasLength(1));
  });

  testUsingContext('LinuxDevice.isSupportedForProject is true with editable host app', () async {
    globals.fs.file('pubspec.yaml').createSync();
    globals.fs.file('.packages').createSync();
    globals.fs.directory('linux').createSync();
    final FlutterProject flutterProject = FlutterProject.current();

    expect(LinuxDevice(
      logger: BufferLogger.test(),
      processManager: FakeProcessManager.any(),
    ).isSupportedForProject(flutterProject), true);
  }, overrides: <Type, Generator>{
    FileSystem: () => MemoryFileSystem(),
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('LinuxDevice.isSupportedForProject is false with no host app', () async {
    globals.fs.file('pubspec.yaml').createSync();
    globals.fs.file('.packages').createSync();
    final FlutterProject flutterProject = FlutterProject.current();

    expect(LinuxDevice(
      logger: BufferLogger.test(),
      processManager: FakeProcessManager.any(),
    ).isSupportedForProject(flutterProject), false);
  }, overrides: <Type, Generator>{
    FileSystem: () => MemoryFileSystem(),
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('LinuxDevice.executablePathForDevice uses the correct package executable', () async {
    final MockLinuxApp mockApp = MockLinuxApp();
    final LinuxDevice device = LinuxDevice(
      logger: BufferLogger.test(),
      processManager: FakeProcessManager.any(),
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
  }, overrides: <Type, Generator>{
    FileSystem: () => MemoryFileSystem(),
    ProcessManager: () => FakeProcessManager.any(),
  });
}

class MockLinuxApp extends Mock implements LinuxApp {}
