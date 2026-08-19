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
import '../../src/context.dart';
import '../../src/fakes.dart';

final macOS = FakePlatform(operatingSystem: 'macos');

final linux = FakePlatform();

void main() {
  testWithoutContext('default configuration', () async {
    final device = MacOSDevice(
      processManager: FakeProcessManager.any(),
      logger: BufferLogger.test(),
      fileSystem: MemoryFileSystem.test(),
      operatingSystemUtils: FakeOperatingSystemUtils(),
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
      fileSystem: MemoryFileSystem.test(),
      processManager: FakeProcessManager.list(<FakeCommand>[
        FakeCommand(
          command: const <String>['release/executable'],
          stdout: 'Hello World\n',
          stderr: 'Goodnight, Moon\n',
          completer: completer,
        ),
      ]),
      logger: BufferLogger.test(),
      operatingSystemUtils: FakeOperatingSystemUtils(),
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
        fileSystem: MemoryFileSystem.test(),
        processManager: FakeProcessManager.any(),
        logger: BufferLogger.test(),
        platform: linux,
        operatingSystemUtils: FakeOperatingSystemUtils(),
        macOSWorkflow: MacOSWorkflow(
          featureFlags: TestFeatureFlags(isMacOSEnabled: true),
          platform: linux,
        ),
      ).devices(),
      isEmpty,
    );
  });

  testWithoutContext(
    'No devices listed if platform is supported and feature is disabled',
    () async {
      final macOSDevices = MacOSDevices(
        fileSystem: MemoryFileSystem.test(),
        processManager: FakeProcessManager.any(),
        logger: BufferLogger.test(),
        platform: macOS,
        operatingSystemUtils: FakeOperatingSystemUtils(),
        macOSWorkflow: MacOSWorkflow(featureFlags: TestFeatureFlags(), platform: macOS),
      );

      expect(await macOSDevices.devices(), isEmpty);
    },
  );

  testWithoutContext('devices listed if platform is supported and feature is enabled', () async {
    final macOSDevices = MacOSDevices(
      fileSystem: MemoryFileSystem.test(),
      processManager: FakeProcessManager.any(),
      logger: BufferLogger.test(),
      platform: macOS,
      operatingSystemUtils: FakeOperatingSystemUtils(),
      macOSWorkflow: MacOSWorkflow(
        featureFlags: TestFeatureFlags(isMacOSEnabled: true),
        platform: macOS,
      ),
    );

    expect(await macOSDevices.devices(), hasLength(1));
  });

  testWithoutContext('has a well known device id macos', () async {
    final macOSDevices = MacOSDevices(
      fileSystem: MemoryFileSystem.test(),
      processManager: FakeProcessManager.any(),
      logger: BufferLogger.test(),
      platform: macOS,
      operatingSystemUtils: FakeOperatingSystemUtils(),
      macOSWorkflow: MacOSWorkflow(
        featureFlags: TestFeatureFlags(isMacOSEnabled: true),
        platform: macOS,
      ),
    );

    expect(macOSDevices.wellKnownIds, <String>['macos']);
  });

  testWithoutContext('can discover devices with a provided timeout', () async {
    final macOSDevices = MacOSDevices(
      fileSystem: MemoryFileSystem.test(),
      processManager: FakeProcessManager.any(),
      logger: BufferLogger.test(),
      platform: macOS,
      operatingSystemUtils: FakeOperatingSystemUtils(),
      macOSWorkflow: MacOSWorkflow(
        featureFlags: TestFeatureFlags(isMacOSEnabled: true),
        platform: macOS,
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
      fileSystem: MemoryFileSystem.test(),
      logger: BufferLogger.test(),
      processManager: FakeProcessManager.any(),
      operatingSystemUtils: FakeOperatingSystemUtils(),
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
      fileSystem: MemoryFileSystem.test(),
      logger: BufferLogger.test(),
      processManager: FakeProcessManager.any(),
      operatingSystemUtils: fakeOperatingSystemUtils,
    );

    expect(await device.targetPlatformDisplayName, 'darwin-x64');
  });

  testWithoutContext('target platform display name on ARM', () async {
    final fakeOperatingSystemUtils = FakeOperatingSystemUtils();
    fakeOperatingSystemUtils.hostPlatform = HostPlatform.darwin_arm64;
    final device = MacOSDevice(
      fileSystem: MemoryFileSystem.test(),
      logger: BufferLogger.test(),
      processManager: FakeProcessManager.any(),
      operatingSystemUtils: fakeOperatingSystemUtils,
    );

    expect(await device.targetPlatformDisplayName, 'darwin-arm64');
  });

  testWithoutContext('isSupportedForProject is false with no host app', () async {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final device = MacOSDevice(
      fileSystem: fileSystem,
      logger: BufferLogger.test(),
      processManager: FakeProcessManager.any(),
      operatingSystemUtils: FakeOperatingSystemUtils(),
    );
    fileSystem.file('pubspec.yaml').createSync();
    final FlutterProject flutterProject = setUpFlutterProject(fileSystem.currentDirectory);

    expect(device.isSupportedForProject(flutterProject), false);
  });

  testWithoutContext('executablePathForDevice uses the correct package executable', () async {
    final package = FakeMacOSApp();
    final device = MacOSDevice(
      fileSystem: MemoryFileSystem.test(),
      logger: BufferLogger.test(),
      processManager: FakeProcessManager.any(),
      operatingSystemUtils: FakeOperatingSystemUtils(),
    );
    const debugPath = 'debug/executable';
    const profilePath = 'profile/executable';
    const releasePath = 'release/executable';

    expect(device.executablePathForDevice(package, BuildInfo.debug), debugPath);
    expect(device.executablePathForDevice(package, BuildInfo.profile), profilePath);
    expect(device.executablePathForDevice(package, BuildInfo.release), releasePath);
  });

  testUsingContext('startApp in debug mode launches via open and parses VM Service URI', () async {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final completer = Completer<void>();

    final device = MacOSDevice(
      fileSystem: fileSystem,
      processManager: FakeProcessManager.list(<FakeCommand>[
        FakeCommand(
          command: <Pattern>[
            'open',
            '-a',
            'release/bundle.app',
            '--args',
            '--enable-dart-profiling=true',
            '--enable-checked-mode=true',
            '--verify-entry-points=true',
            RegExp(r'^--write-service-info=(.*)$'),
          ],
          onRun: (List<String> command) {
            final String writeServiceInfoArg = command.firstWhere(
              (String arg) => arg.startsWith('--write-service-info='),
            );
            final String filePath = writeServiceInfoArg.substring('--write-service-info='.length);
            fileSystem
                .file(filePath)
                .writeAsStringSync('{"uri":"http://127.0.0.1:12345/auth_code/"}');
            completer.complete();
          },
        ),
      ]),
      logger: BufferLogger.test(),
      operatingSystemUtils: FakeOperatingSystemUtils(),
    );

    final package = FakeMacOSApp();

    final LaunchResult result = await device.startApp(
      package,
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.debug),
      prebuiltApplication: true,
    );

    expect(result.started, true);
    expect(result.vmServiceUri, Uri.parse('http://127.0.0.1:12345/auth_code/'));

    await completer.future;
  });

  testWithoutContext('stopApp uses pkill for all build modes', () async {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final device = MacOSDevice(
      fileSystem: fileSystem,
      processManager: FakeProcessManager.list(<FakeCommand>[
        const FakeCommand(command: <String>['pkill', '-f', 'debug/executable']),
      ]),
      logger: BufferLogger.test(),
      operatingSystemUtils: FakeOperatingSystemUtils(),
    );

    final package = FakeMacOSApp();
    fileSystem.file('debug/executable').createSync(recursive: true);

    final bool result = await device.stopApp(package);

    expect(result, true);
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
  String get name => 'app';

  @override
  String? applicationBundle(BuildInfo buildInfo) {
    return 'release/bundle.app';
  }

  @override
  String executable(BuildInfo buildInfo) {
    return switch (buildInfo.mode) {
      BuildMode.debug => 'debug/executable',
      BuildMode.profile => 'profile/executable',
      BuildMode.release => 'release/executable',
      BuildMode.jitRelease => 'jitRelease/executable',
    };
  }
}
