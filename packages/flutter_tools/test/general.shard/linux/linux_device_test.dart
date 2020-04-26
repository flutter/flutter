// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/linux/application_package.dart';
import 'package:flutter_tools/src/linux/linux_device.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/globals.dart' as globals;

import 'package:mockito/mockito.dart';
import 'package:platform/platform.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/testbed.dart';

void main() {
  final LinuxDevice device = LinuxDevice();
  final MockPlatform notLinux = MockPlatform();
  when(notLinux.isLinux).thenReturn(false);

  final MockPlatform mockLinuxPlatform = MockPlatform();
  when(mockLinuxPlatform.isLinux).thenReturn(true);

  testWithoutContext('LinuxDevice defaults', () async {
    final PrebuiltLinuxApp linuxApp = PrebuiltLinuxApp(executable: 'foo');
    expect(await device.targetPlatform, TargetPlatform.linux_x64);
    expect(device.name, 'Linux');
    expect(await device.installApp(linuxApp), true);
    expect(await device.uninstallApp(linuxApp), true);
    expect(await device.isLatestBuildInstalled(linuxApp), true);
    expect(await device.isAppInstalled(linuxApp), true);
    expect(await device.stopApp(linuxApp), true);
    expect(device.category, Category.desktop);
  });

  testWithoutContext('LinuxDevice: no devices listed if platform unsupported', () async {
    expect(await LinuxDevices(
      platform: notLinux,
      featureFlags: TestFeatureFlags(isLinuxEnabled: true),
    ).devices, <Device>[]);
  });

  testWithoutContext('LinuxDevice: no devices listed if Linux feature flag disabled', () async {
    expect(await LinuxDevices(
      platform: mockLinuxPlatform,
      featureFlags: TestFeatureFlags(isLinuxEnabled: false),
    ).devices, <Device>[]);
  });

  testWithoutContext('LinuxDevice: devices', () async {
    expect(await LinuxDevices(
      platform: mockLinuxPlatform,
      featureFlags: TestFeatureFlags(isLinuxEnabled: true),
    ).devices, hasLength(1));
  });

  testWithoutContext('LinuxDevice: discoverDevices', () async {
    // Timeout ignored.
    final List<Device> devices = await LinuxDevices(
      platform: mockLinuxPlatform,
      featureFlags: TestFeatureFlags(isLinuxEnabled: true),
    ).discoverDevices(timeout: const Duration(seconds: 10));
    expect(devices, hasLength(1));
  });

  testUsingContext('LinuxDevice.isSupportedForProject is true with editable host app', () async {
    globals.fs.file('pubspec.yaml').createSync();
    globals.fs.file('.packages').createSync();
    globals.fs.directory('linux').createSync();
    final FlutterProject flutterProject = FlutterProject.current();

    expect(LinuxDevice().isSupportedForProject(flutterProject), true);
  }, overrides: <Type, Generator>{
    FileSystem: () => MemoryFileSystem(),
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('LinuxDevice.isSupportedForProject is false with no host app', () async {
    globals.fs.file('pubspec.yaml').createSync();
    globals.fs.file('.packages').createSync();
    final FlutterProject flutterProject = FlutterProject.current();

    expect(LinuxDevice().isSupportedForProject(flutterProject), false);
  }, overrides: <Type, Generator>{
    FileSystem: () => MemoryFileSystem(),
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('LinuxDevice.executablePathForDevice uses the correct package executable', () async {
    final MockLinuxApp mockApp = MockLinuxApp();
    const String debugPath = 'debug/executable';
    const String profilePath = 'profile/executable';
    const String releasePath = 'release/executable';
    when(mockApp.executable(BuildMode.debug)).thenReturn(debugPath);
    when(mockApp.executable(BuildMode.profile)).thenReturn(profilePath);
    when(mockApp.executable(BuildMode.release)).thenReturn(releasePath);

    expect(LinuxDevice().executablePathForDevice(mockApp, BuildMode.debug), debugPath);
    expect(LinuxDevice().executablePathForDevice(mockApp, BuildMode.profile), profilePath);
    expect(LinuxDevice().executablePathForDevice(mockApp, BuildMode.release), releasePath);
  }, overrides: <Type, Generator>{
    FileSystem: () => MemoryFileSystem(),
    ProcessManager: () => FakeProcessManager.any(),
  });
}

class MockPlatform extends Mock implements Platform {}

class MockLinuxApp extends Mock implements LinuxApp {}
