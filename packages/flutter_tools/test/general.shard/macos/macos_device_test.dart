// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/macos/application_package.dart';
import 'package:flutter_tools/src/macos/macos_device.dart';
import 'package:flutter_tools/src/macos/macos_workflow.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';
import '../../src/fake_process_manager.dart';
import '../../src/fakes.dart';

final macOS = FakePlatform(operatingSystem: 'macos');

final linux = FakePlatform();

void main() {
  testWithoutContext('default configuration', () async {
    final device = MacOSDevice(
      toolContext: FakeToolContext(
        fs: MemoryFileSystem.test(),
        logger: BufferLogger.test(),
        os: FakeOperatingSystemUtils(),
        processManager: FakeProcessManager.any(),
      ),
    );
    final package = FakeMacOSApp();

    expect(await device.targetPlatform, TargetPlatform.darwin);
    expect(device.name, 'macOS');
    expect(await device.installApp(package), true);
    expect(await device.uninstallApp(package), true);
    expect(await device.isLatestBuildInstalled(package), true);
    expect(await device.isAppInstalled(package), true);
    expect(device.category, Category.desktop);

    expect(device.supportsRuntimeMode(BuildMode.debug), true);
    expect(device.supportsRuntimeMode(BuildMode.profile), true);
    expect(device.supportsRuntimeMode(BuildMode.release), true);
    expect(device.supportsRuntimeMode(BuildMode.jitRelease), false);
  });

  testWithoutContext('Attaches to log reader when running in release mode', () async {
    final completer = Completer<void>();
    final device = MacOSDevice(
      toolContext: FakeToolContext(
        fs: MemoryFileSystem.test(),
        logger: BufferLogger.test(),
        os: FakeOperatingSystemUtils(),
        processManager: FakeProcessManager.list(<FakeCommand>[
          FakeCommand(
            command: const <String>['release/executable'],
            stdout: 'Hello World\n',
            stderr: 'Goodnight, Moon\n',
            completer: completer,
          ),
        ]),
      ),
    );
    final package = FakeMacOSApp();

    final LaunchResult result = await device.startApp(
      package,
      debuggingOptions: DebuggingOptions.disabled(BuildInfo.release),
      prebuiltApplication: true,
    );

    expect(result.started, true);

    final DeviceLogReader logReader = device.getLogReader(app: package);

    expect(logReader.logLines, emitsInAnyOrder(<String>['Hello World', 'Goodnight, Moon']));
    completer.complete();
  });

  testWithoutContext('No devices listed if platform is unsupported', () async {
    expect(
      await MacOSDevices(
        macOSWorkflow: MacOSWorkflow(
          featureFlags: TestFeatureFlags(isMacOSEnabled: true),
          platform: linux,
        ),
        toolContext: FakeToolContext(
          fs: MemoryFileSystem.test(),
          logger: BufferLogger.test(),
          os: FakeOperatingSystemUtils(),
          platform: linux,
          processManager: FakeProcessManager.any(),
        ),
      ).devices(),
      isEmpty,
    );
  });

  testWithoutContext(
    'No devices listed if platform is supported and feature is disabled',
    () async {
      final macOSDevices = MacOSDevices(
        macOSWorkflow: MacOSWorkflow(featureFlags: TestFeatureFlags(), platform: macOS),
        toolContext: FakeToolContext(
          fs: MemoryFileSystem.test(),
          logger: BufferLogger.test(),
          os: FakeOperatingSystemUtils(),
          platform: macOS,
          processManager: FakeProcessManager.any(),
        ),
      );

      expect(await macOSDevices.devices(), isEmpty);
    },
  );

  testWithoutContext('devices listed if platform is supported and feature is enabled', () async {
    final macOSDevices = MacOSDevices(
      macOSWorkflow: MacOSWorkflow(
        featureFlags: TestFeatureFlags(isMacOSEnabled: true),
        platform: macOS,
      ),
      toolContext: FakeToolContext(
        fs: MemoryFileSystem.test(),
        logger: BufferLogger.test(),
        os: FakeOperatingSystemUtils(),
        platform: macOS,
        processManager: FakeProcessManager.any(),
      ),
    );

    expect(await macOSDevices.devices(), hasLength(1));
  });

  testWithoutContext('has a well known device id macos', () async {
    final macOSDevices = MacOSDevices(
      macOSWorkflow: MacOSWorkflow(
        featureFlags: TestFeatureFlags(isMacOSEnabled: true),
        platform: macOS,
      ),
      toolContext: FakeToolContext(
        fs: MemoryFileSystem.test(),
        logger: BufferLogger.test(),
        os: FakeOperatingSystemUtils(),
        platform: macOS,
        processManager: FakeProcessManager.any(),
      ),
    );

    expect(macOSDevices.wellKnownIds, <String>['macos']);
  });

  testWithoutContext('can discover devices with a provided timeout', () async {
    final macOSDevices = MacOSDevices(
      macOSWorkflow: MacOSWorkflow(
        featureFlags: TestFeatureFlags(isMacOSEnabled: true),
        platform: macOS,
      ),
      toolContext: FakeToolContext(
        fs: MemoryFileSystem.test(),
        logger: BufferLogger.test(),
        os: FakeOperatingSystemUtils(),
        platform: macOS,
        processManager: FakeProcessManager.any(),
      ),
    );

    // Timeout ignored.
    final List<Device> devices = await macOSDevices.discoverDevices(
      timeout: const Duration(seconds: 10),
    );

    expect(devices, hasLength(1));
  });

  testWithoutContext('isSupportedForProject is true with editable host app', () async {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final device = MacOSDevice(
      toolContext: FakeToolContext(
        fs: MemoryFileSystem.test(),
        logger: BufferLogger.test(),
        os: FakeOperatingSystemUtils(),
        processManager: FakeProcessManager.any(),
      ),
    );

    fileSystem.file('pubspec.yaml').createSync();
    fileSystem.directory('macos').createSync();
    final FlutterProject flutterProject = setUpFlutterProject(fileSystem.currentDirectory);

    expect(device.isSupportedForProject(flutterProject), true);
  });

  testWithoutContext('target platform display name on x86_64', () async {
    final fakeOperatingSystemUtils = FakeOperatingSystemUtils();
    fakeOperatingSystemUtils.hostPlatform = HostPlatform.darwin_x64;
    final device = MacOSDevice(
      toolContext: FakeToolContext(
        fs: MemoryFileSystem.test(),
        logger: BufferLogger.test(),
        os: fakeOperatingSystemUtils,
        processManager: FakeProcessManager.any(),
      ),
    );

    expect(await device.targetPlatformDisplayName, 'darwin-x64');
  });

  testWithoutContext('target platform display name on ARM', () async {
    final fakeOperatingSystemUtils = FakeOperatingSystemUtils();
    fakeOperatingSystemUtils.hostPlatform = HostPlatform.darwin_arm64;
    final device = MacOSDevice(
      toolContext: FakeToolContext(
        fs: MemoryFileSystem.test(),
        logger: BufferLogger.test(),
        os: fakeOperatingSystemUtils,
        processManager: FakeProcessManager.any(),
      ),
    );

    expect(await device.targetPlatformDisplayName, 'darwin-arm64');
  });

  testWithoutContext('isSupportedForProject is false with no host app', () async {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final device = MacOSDevice(
      toolContext: FakeToolContext(
        fs: fileSystem,
        logger: BufferLogger.test(),
        os: FakeOperatingSystemUtils(),
        processManager: FakeProcessManager.any(),
      ),
    );
    fileSystem.file('pubspec.yaml').createSync();
    final FlutterProject flutterProject = setUpFlutterProject(fileSystem.currentDirectory);

    expect(device.isSupportedForProject(flutterProject), false);
  });

  testWithoutContext('executablePathForDevice uses the correct package executable', () async {
    final package = FakeMacOSApp();
    final device = MacOSDevice(
      toolContext: FakeToolContext(
        fs: MemoryFileSystem.test(),
        logger: BufferLogger.test(),
        os: FakeOperatingSystemUtils(),
        processManager: FakeProcessManager.any(),
      ),
    );
    const debugPath = 'debug/executable';
    const profilePath = 'profile/executable';
    const releasePath = 'release/executable';

    expect(device.executablePathForDevice(package, BuildInfo.debug), debugPath);
    expect(device.executablePathForDevice(package, BuildInfo.profile), profilePath);
    expect(device.executablePathForDevice(package, BuildInfo.release), releasePath);
  });
}

FlutterProject setUpFlutterProject(Directory directory) {
  final flutterProjectFactory = FlutterProjectFactory(
    fileSystem: directory.fileSystem,
    logger: BufferLogger.test(),
  );
  return flutterProjectFactory.fromDirectory(directory);
}

class FakeMacOSApp extends Fake implements MacOSApp {
  @override
  String executable(BuildInfo buildInfo) {
    return switch (buildInfo) {
      BuildInfo.debug => 'debug/executable',
      BuildInfo.profile => 'profile/executable',
      BuildInfo.release => 'release/executable',
      _ => throw StateError(''),
    };
  }
}
