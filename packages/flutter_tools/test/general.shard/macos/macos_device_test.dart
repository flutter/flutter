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
import 'package:flutter_tools/src/convert.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/macos/application_package.dart';
import 'package:flutter_tools/src/macos/macos_device.dart';
import 'package:flutter_tools/src/macos/macos_workflow.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';
import '../../src/fake_process_manager.dart' hide FakeProcess;
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

  group('MacOSLogReader', () {
    testWithoutContext(
      'detects privacy crash with key name and prints diagnostic with bundle path',
      () {
        final logger = BufferLogger.test();
        final reader = MacOSLogReader(logger: logger)..bundlePath = '/path/to/MyFlutterApp.app';

        const crashLine =
            'This app has crashed because it attempted to access privacy-sensitive data '
            "without a usage description.  The app's Info.plist must supply an "
            'NSSpeechRecognitionUsageDescription key with a string value explaining to the user '
            'how the app uses this data.';

        reader.handleStderrLine(crashLine);

        expect(logger.errorText, contains('macOS Privacy Permission Crash Detected'));
        expect(logger.errorText, contains('requiring NSSpeechRecognitionUsageDescription'));
        expect(
          logger.errorText,
          contains('Even if NSSpeechRecognitionUsageDescription is already present'),
        );
        expect(logger.errorText, contains('open "/path/to/MyFlutterApp.app"'));
        expect(logger.errorText, contains('https://github.com/flutter/flutter/issues/70374'));
      },
    );

    testWithoutContext(
      'detects privacy crash with alternative phrasing and fallback bundle path',
      () {
        final logger = BufferLogger.test();
        final reader = MacOSLogReader(logger: logger);

        const crashLine =
            'This app has crashed because it attempted to access privacy-sensitive data '
            "without a usage description. The app's Info.plist must contain an "
            'NSPhotoLibraryUsageDescription key with a string value explaining to the user '
            'how the app uses this data.';

        reader.handleStderrLine(crashLine);

        expect(logger.errorText, contains('macOS Privacy Permission Crash Detected'));
        expect(logger.errorText, contains('requiring NSPhotoLibraryUsageDescription'));
        expect(logger.errorText, contains('open <path-to-app-bundle>'));
      },
    );

    testWithoutContext('detects privacy crash without key name and prints fallback diagnostic', () {
      final logger = BufferLogger.test();
      final reader = MacOSLogReader(logger: logger);

      const crashLine =
          'This app has crashed because it attempted to access privacy-sensitive data '
          'without a usage description.';

      reader.handleStderrLine(crashLine);

      expect(logger.errorText, contains('macOS Privacy Permission Crash Detected'));
      expect(logger.errorText, contains('access to privacy-sensitive data.'));
      expect(logger.errorText, isNot(contains('requiring')));
      expect(
        logger.errorText,
        contains('Even if the usage description key is already present in macos/Runner/Info.plist'),
      );
    });

    testWithoutContext(
      'handles multi-byte UTF-8, split chunks, and unflushed trailing line',
      () async {
        final logger = BufferLogger.test();
        final reader = MacOSLogReader(logger: logger);

        final stderrController = StreamController<List<int>>();
        final process = FakeProcess(stderr: stderrController.stream);
        reader.listenToProcessOutput(process);

        // Multi-byte UTF-8 character '€' (0xE2, 0x82, 0xAC) split across chunks.
        const part1 = 'This app has crashed because it attempted to access privacy-sensitive data ';
        const part2 =
            "without a usage description. The app's Info.plist must contain an NSCameraUsageDescription key. €";

        final List<int> bytes1 = utf8.encode(part1);
        final List<int> bytes2 = utf8.encode(part2);

        stderrController.add(bytes1);
        stderrController.add(bytes2.sublist(0, bytes2.length - 2));
        await pumpEventQueue();
        expect(logger.errorText, isEmpty);

        // Send remaining bytes of multi-byte character and complete stream without trailing newline.
        stderrController.add(bytes2.sublist(bytes2.length - 2));
        await stderrController.close();
        await pumpEventQueue();

        expect(logger.errorText, contains('macOS Privacy Permission Crash Detected'));
        expect(logger.errorText, contains('requiring NSCameraUsageDescription'));
      },
    );

    testWithoutContext('does not trigger diagnostic on unrelated stderr lines', () {
      final logger = BufferLogger.test();
      final reader = MacOSLogReader(logger: logger);

      reader.handleStderrLine('Some standard stderr error message');
      reader.handleStderrLine('Another line');

      expect(logger.errorText, isEmpty);
    });

    testWithoutContext('only prints diagnostic once even if multiple crash lines are received', () {
      final logger = BufferLogger.test();
      final reader = MacOSLogReader(logger: logger);

      const crashLine =
          'This app has crashed because it attempted to access privacy-sensitive data '
          "without a usage description. The app's Info.plist must supply an "
          'NSMicrophoneUsageDescription key.';

      reader.handleStderrLine(crashLine);
      reader.handleStderrLine(crashLine);

      final Iterable<RegExpMatch> matches = RegExp(
        'macOS Privacy Permission Crash Detected',
      ).allMatches(logger.errorText);
      expect(matches.length, 1);
    });
  });

  testWithoutContext('startApp sets bundlePath on macosLogReader', () async {
    final fileSystem = MemoryFileSystem.test();
    final logger = BufferLogger.test();
    final device = MacOSDevice(
      fileSystem: fileSystem,
      logger: logger,
      operatingSystemUtils: FakeOperatingSystemUtils(),
      processManager: FakeProcessManager.list(<FakeCommand>[
        const FakeCommand(command: <String>['release/executable']),
      ]),
    );
    final package = FakeMacOSApp(bundlePath: '/path/to/CustomBundle.app');

    await device.startApp(
      package,
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.release),
      prebuiltApplication: true,
    );

    expect(device.macosLogReader.bundlePath, '/path/to/CustomBundle.app');
  });

  testWithoutContext('startApp clears stale bundlePath from previous launch', () async {
    final fileSystem = MemoryFileSystem.test();
    final logger = BufferLogger.test();
    final device = MacOSDevice(
      fileSystem: fileSystem,
      logger: logger,
      operatingSystemUtils: FakeOperatingSystemUtils(),
      processManager: FakeProcessManager.list(<FakeCommand>[
        const FakeCommand(command: <String>['release/executable']),
        const FakeCommand(command: <String>['release/executable']),
      ]),
    );

    final packageWithBundle = FakeMacOSApp(bundlePath: '/path/to/First.app');
    await device.startApp(
      packageWithBundle,
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.release),
      prebuiltApplication: true,
    );
    expect(device.macosLogReader.bundlePath, '/path/to/First.app');

    final packageWithoutBundle = FakeMacOSApp(bundlePath: null);
    await device.startApp(
      packageWithoutBundle,
      debuggingOptions: DebuggingOptions.enabled(BuildInfo.release),
      prebuiltApplication: true,
    );
    expect(device.macosLogReader.bundlePath, isNull);
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
  FakeMacOSApp({this.bundlePath = 'release/bundle.app'});

  final String? bundlePath;

  @override
  String? applicationBundle(BuildInfo buildInfo) => bundlePath;

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
