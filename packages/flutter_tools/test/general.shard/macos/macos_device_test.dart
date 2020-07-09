// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/macos/application_package.dart';
import 'package:flutter_tools/src/macos/macos_device.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/testbed.dart';

void main() {
  group(MacOSDevice, () {
    final MacOSDevice device = MacOSDevice();
    final MockProcessManager mockProcessManager = MockProcessManager();

    final MockPlatform notMac = MockPlatform();
    when(notMac.isMacOS).thenReturn(false);
    when(notMac.environment).thenReturn(const <String, String>{});

    final MockPlatform mockMacPlatform = MockPlatform();
    when(mockMacPlatform.isMacOS).thenReturn(true);

    when(mockProcessManager.run(any)).thenAnswer((Invocation invocation) async {
      return ProcessResult(0, 1, '', '');
    });

    testUsingContext('defaults', () async {
      final MockMacOSApp mockMacOSApp = MockMacOSApp();
      expect(await device.targetPlatform, TargetPlatform.darwin_x64);
      expect(device.name, 'macOS');
      expect(await device.installApp(mockMacOSApp), true);
      expect(await device.uninstallApp(mockMacOSApp), true);
      expect(await device.isLatestBuildInstalled(mockMacOSApp), true);
      expect(await device.isAppInstalled(mockMacOSApp), true);
      expect(device.category, Category.desktop);

      expect(device.supportsRuntimeMode(BuildMode.debug), true);
      expect(device.supportsRuntimeMode(BuildMode.profile), true);
      expect(device.supportsRuntimeMode(BuildMode.release), true);
      expect(device.supportsRuntimeMode(BuildMode.jitRelease), false);
    });

    testUsingContext('No devices listed if platform unsupported', () async {
      expect(await MacOSDevices().devices, <Device>[]);
    }, overrides: <Type, Generator>{
      Platform: () => notMac,
    });

    testUsingContext('devices', () async {
      expect(await MacOSDevices().devices, hasLength(1));
    }, overrides: <Type, Generator>{
      Platform: () => mockMacPlatform,
      FeatureFlags: () => TestFeatureFlags(isMacOSEnabled: true),
    });

    testUsingContext('discoverDevices', () async {
      // Timeout ignored.
      final List<Device> devices = await MacOSDevices().discoverDevices(timeout: const Duration(seconds: 10));
      expect(devices, hasLength(1));
    }, overrides: <Type, Generator>{
      Platform: () => mockMacPlatform,
      FeatureFlags: () => TestFeatureFlags(isMacOSEnabled: true),
    });

    testUsingContext('isSupportedForProject is true with editable host app', () async {
      globals.fs.file('pubspec.yaml').createSync();
      globals.fs.file('.packages').createSync();
      globals.fs.directory('macos').createSync();
      final FlutterProject flutterProject = FlutterProject.current();

      expect(MacOSDevice().isSupportedForProject(flutterProject), true);
    }, overrides: <Type, Generator>{
      FileSystem: () => MemoryFileSystem(),
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('isSupportedForProject is false with no host app', () async {
      globals.fs.file('pubspec.yaml').createSync();
      globals.fs.file('.packages').createSync();
      final FlutterProject flutterProject = FlutterProject.current();

      expect(MacOSDevice().isSupportedForProject(flutterProject), false);
    }, overrides: <Type, Generator>{
      FileSystem: () => MemoryFileSystem(),
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('executablePathForDevice uses the correct package executable', () async {
      final MockMacOSApp mockApp = MockMacOSApp();
      const String debugPath = 'debug/executable';
      const String profilePath = 'profile/executable';
      const String releasePath = 'release/executable';
      when(mockApp.executable(BuildMode.debug)).thenReturn(debugPath);
      when(mockApp.executable(BuildMode.profile)).thenReturn(profilePath);
      when(mockApp.executable(BuildMode.release)).thenReturn(releasePath);

      expect(MacOSDevice().executablePathForDevice(mockApp, BuildMode.debug), debugPath);
      expect(MacOSDevice().executablePathForDevice(mockApp, BuildMode.profile), profilePath);
      expect(MacOSDevice().executablePathForDevice(mockApp, BuildMode.release), releasePath);
    }, overrides: <Type, Generator>{
      FileSystem: () => MemoryFileSystem(),
      ProcessManager: () => FakeProcessManager.any(),
    });
  });
}

class MockPlatform extends Mock implements Platform {}

class MockMacOSApp extends Mock implements MacOSApp {}

class MockProcessManager extends Mock implements ProcessManager {}
