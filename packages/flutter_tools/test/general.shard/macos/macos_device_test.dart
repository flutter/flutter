// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/macos/application_package.dart';
import 'package:flutter_tools/src/macos/macos_device.dart';
import 'package:flutter_tools/src/macos/macos_workflow.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/testbed.dart';

final FakePlatform macOS = FakePlatform(
  operatingSystem: 'macos',
);

final FakePlatform linux = FakePlatform(
  operatingSystem: 'linux',
);

void main() {
  testWithoutContext('default configuration', () async {
    final MacOSDevice device = MacOSDevice(
      processManager: FakeProcessManager.any(),
      logger: BufferLogger.test(),
    );
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

  testUsingContext('Attaches to log reader when running in release mode', () async {
    final Completer<void> completer = Completer<void>();
    final MacOSDevice device = MacOSDevice(
      processManager: FakeProcessManager.list(<FakeCommand>[
        FakeCommand(
          command: const <String>['Example.app'],
          stdout: 'Hello World',
          stderr: 'Goodnight, Moon',
          completer: completer,
        )
      ]),
      logger: BufferLogger.test(),
    );
    final MockMacOSApp mockMacOSApp = MockMacOSApp();
    when(mockMacOSApp.executable(BuildMode.release)).thenReturn('Example.app');

    final LaunchResult result = await device.startApp(
      mockMacOSApp,
      debuggingOptions: DebuggingOptions.disabled(BuildInfo.release),
      prebuiltApplication: true,
    );

    expect(result.started, true);

    final DeviceLogReader logReader = device.getLogReader(app: mockMacOSApp);

    expect(logReader.logLines, emits('Hello WorldGoodnight, Moon'));
    completer.complete();
  }, overrides: <Type, Generator>{
    FileSystem: () => MemoryFileSystem.test(),
    ProcessManager: () => FakeProcessManager.any(),
  });

  testWithoutContext('No devices listed if platform is unsupported', () async {
    expect(await MacOSDevices(
      processManager: FakeProcessManager.any(),
      logger: BufferLogger.test(),
      platform: linux,
      macOSWorkflow: MacOSWorkflow(
        featureFlags: TestFeatureFlags(isMacOSEnabled: true),
        platform: linux,
      ),
    ).devices, isEmpty);
  });

  testWithoutContext('No devices listed if platform is supported and feature is disabled', () async {
    final MacOSDevices macOSDevices = MacOSDevices(
      processManager: FakeProcessManager.any(),
      logger: BufferLogger.test(),
      platform: macOS,
      macOSWorkflow: MacOSWorkflow(
        featureFlags: TestFeatureFlags(isMacOSEnabled: false),
        platform: macOS,
      ),
    );

    expect(await macOSDevices.devices, isEmpty);
  });

  testWithoutContext('devices listed if platform is supported and feature is enabled', () async {
    final MacOSDevices macOSDevices = MacOSDevices(
      processManager: FakeProcessManager.any(),
      logger: BufferLogger.test(),
      platform: macOS,
      macOSWorkflow: MacOSWorkflow(
        featureFlags: TestFeatureFlags(isMacOSEnabled: true),
        platform: macOS,
      ),
    );

    expect(await macOSDevices.devices, hasLength(1));
  });

  testWithoutContext('can discover devices with a provided timeout', () async {
    final MacOSDevices macOSDevices = MacOSDevices(
      processManager: FakeProcessManager.any(),
      logger: BufferLogger.test(),
      platform: macOS,
      macOSWorkflow: MacOSWorkflow(
        featureFlags: TestFeatureFlags(isMacOSEnabled: true),
        platform: macOS,
      ),
    );

    // Timeout ignored.
    final List<Device> devices = await macOSDevices.discoverDevices(timeout: const Duration(seconds: 10));

    expect(devices, hasLength(1));
  });

  testUsingContext('isSupportedForProject is true with editable host app', () async {
    final MacOSDevice device = MacOSDevice(
      logger: BufferLogger.test(),
      processManager: FakeProcessManager.any(),
    );

    globals.fs.file('pubspec.yaml').createSync();
    globals.fs.file('.packages').createSync();
    globals.fs.directory('macos').createSync();
    final FlutterProject flutterProject = FlutterProject.current();

    expect(device.isSupportedForProject(flutterProject), true);
  }, overrides: <Type, Generator>{
    FileSystem: () => MemoryFileSystem.test(),
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('isSupportedForProject is false with no host app', () async {
    final MacOSDevice device = MacOSDevice(
      logger: BufferLogger.test(),
      processManager: FakeProcessManager.any(),
    );
    globals.fs.file('pubspec.yaml').createSync();
    globals.fs.file('.packages').createSync();
    final FlutterProject flutterProject = FlutterProject.current();

    expect(device.isSupportedForProject(flutterProject), false);
  }, overrides: <Type, Generator>{
    FileSystem: () => MemoryFileSystem.test(),
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('executablePathForDevice uses the correct package executable', () async {
    final MockMacOSApp mockApp = MockMacOSApp();
    final MacOSDevice device = MacOSDevice(
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
    FileSystem: () => MemoryFileSystem.test(),
    ProcessManager: () => FakeProcessManager.any(),
  });
}

class MockMacOSApp extends Mock implements MacOSApp {}
