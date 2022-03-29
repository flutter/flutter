// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:file/memory.dart';
import 'package:flutter_tools/src/application_package.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/drive.dart';
import 'package:flutter_tools/src/dart/pub.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/drive/drive_service.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:package_config/package_config.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/test_flutter_command_runner.dart';

void main() {
  FileSystem fileSystem;
  BufferLogger logger;
  Platform platform;
  FakeDeviceManager fakeDeviceManager;

  setUp(() {
    fileSystem = MemoryFileSystem.test();
    logger = BufferLogger.test();
    platform = FakePlatform();
    fakeDeviceManager = FakeDeviceManager();
  });

  setUpAll(() {
    Cache.disableLocking();
  });

  tearDownAll(() {
    Cache.enableLocking();
  });

  testUsingContext('warns if screenshot is not supported but continues test', () async {
    final DriveCommand command = DriveCommand(fileSystem: fileSystem, logger: logger, platform: platform);
    fileSystem.file('lib/main.dart').createSync(recursive: true);
    fileSystem.file('test_driver/main_test.dart').createSync(recursive: true);
    fileSystem.file('pubspec.yaml').createSync();
    fileSystem.directory('drive_screenshots').createSync();

    final Device screenshotDevice = ThrowingScreenshotDevice()
      ..supportsScreenshot = false;
    fakeDeviceManager.devices = <Device>[screenshotDevice];

    await expectLater(() => createTestCommandRunner(command).run(
      <String>[
        'drive',
        '--no-pub',
        '-d',
        screenshotDevice.id,
        '--screenshot',
        'drive_screenshots',
      ]),
      throwsToolExit(message: 'cannot start app'),
    );

    expect(logger.errorText, contains('Screenshot not supported for FakeDevice'));
    expect(logger.statusText, isEmpty);
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
    Pub: () => FakePub(),
    DeviceManager: () => fakeDeviceManager,
  });

  testUsingContext('takes screenshot and rethrows on drive exception', () async {
    final DriveCommand command = DriveCommand(fileSystem: fileSystem, logger: logger, platform: platform);
    fileSystem.file('lib/main.dart').createSync(recursive: true);
    fileSystem.file('test_driver/main_test.dart').createSync(recursive: true);
    fileSystem.file('pubspec.yaml').createSync();
    fileSystem.directory('drive_screenshots').createSync();

    final Device screenshotDevice = ThrowingScreenshotDevice();
    fakeDeviceManager.devices = <Device>[screenshotDevice];

    await expectLater(() => createTestCommandRunner(command).run(
      <String>[
        'drive',
        '--no-pub',
        '-d',
        screenshotDevice.id,
        '--screenshot',
        'drive_screenshots',
      ]),
      throwsToolExit(message: 'cannot start app'),
    );

    expect(logger.statusText, contains('Screenshot written to drive_screenshots/drive_01.png'));
    expect(logger.statusText, isNot(contains('drive_02.png')));
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
    Pub: () => FakePub(),
    DeviceManager: () => fakeDeviceManager,
  });

  testUsingContext('takes screenshot on drive test failure', () async {
    final DriveCommand command = DriveCommand(
      fileSystem: fileSystem,
      logger: logger,
      platform: platform,
      flutterDriverFactory: FailingFakeFlutterDriverFactory(),
    );

    fileSystem.file('lib/main.dart').createSync(recursive: true);
    fileSystem.file('test_driver/main_test.dart').createSync(recursive: true);
    fileSystem.file('pubspec.yaml').createSync();
    fileSystem.directory('drive_screenshots').createSync();

    final Device screenshotDevice = ScreenshotDevice();
    fakeDeviceManager.devices = <Device>[screenshotDevice];

    await expectLater(() => createTestCommandRunner(command).run(
      <String>[
        'drive',
        '--no-pub',
        '-d',
        screenshotDevice.id,
        '--use-existing-app',
        'http://localhost:8181',
        '--keep-app-running',
        '--screenshot',
        'drive_screenshots',
      ]),
      throwsToolExit(),
    );

    // Takes the screenshot before the application would be killed (if --keep-app-running not passed).
    expect(logger.statusText, contains('Screenshot written to drive_screenshots/drive_01.png\n'
        'Leaving the application running.'));
    expect(logger.statusText, isNot(contains('drive_02.png')));
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
    Pub: () => FakePub(),
    DeviceManager: () => fakeDeviceManager,
  });

  testUsingContext('drive --screenshot errors but does not fail if screenshot fails', () async {
    final DriveCommand command = DriveCommand(fileSystem: fileSystem, logger: logger, platform: platform);
    fileSystem.file('lib/main.dart').createSync(recursive: true);
    fileSystem.file('test_driver/main_test.dart').createSync(recursive: true);
    fileSystem.file('pubspec.yaml').createSync();
    fileSystem.file('drive_screenshots').createSync();

    final Device screenshotDevice = ThrowingScreenshotDevice();
    fakeDeviceManager.devices = <Device>[screenshotDevice];

    await expectLater(() => createTestCommandRunner(command).run(
      <String>[
        'drive',
        '--no-pub',
        '-d',
        screenshotDevice.id,
        '--screenshot',
        'drive_screenshots',
      ]),
      throwsToolExit(message: 'cannot start app'),
    );

    expect(logger.statusText, isEmpty);
    expect(logger.errorText, contains('Error taking screenshot: FileSystemException: Not a directory'));
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
    Pub: () => FakePub(),
    DeviceManager: () => fakeDeviceManager,
  });

  testUsingContext('shouldRunPub is true unless user specifies --no-pub', () async {
    final DriveCommand command = DriveCommand(fileSystem: fileSystem, logger: logger, platform: platform);
    fileSystem.file('lib/main.dart').createSync(recursive: true);
    fileSystem.file('test_driver/main_test.dart').createSync(recursive: true);
    fileSystem.file('pubspec.yaml').createSync();

    try {
      await createTestCommandRunner(command).run(const <String>['drive', '--no-pub']);
    } on Exception {
      // Expected to throw
    }

    expect(command.shouldRunPub, false);

    try {
      await createTestCommandRunner(command).run(const <String>['drive']);
    } on Exception {
      // Expected to throw
    }

    expect(command.shouldRunPub, true);
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
    Pub: () => FakePub(),
  });

  testUsingContext('--enable-impeller flag propagates to debugging options', () async {
    final DriveCommand command = DriveCommand(fileSystem: fileSystem, logger: logger, platform: platform);
    fileSystem.file('lib/main.dart').createSync(recursive: true);
    fileSystem.file('test_driver/main_test.dart').createSync(recursive: true);
    fileSystem.file('pubspec.yaml').createSync();

    await expectLater(() => createTestCommandRunner(command).run(<String>[
      'drive',
      '--enable-impeller',
    ]), throwsToolExit());

    final DebuggingOptions options = await command.createDebuggingOptions(false);

    expect(options.enableImpeller, true);
  }, overrides: <Type, Generator>{
    Cache: () => Cache.test(processManager: FakeProcessManager.any()),
    FileSystem: () => MemoryFileSystem.test(),
    ProcessManager: () => FakeProcessManager.any(),
  });
}

// Unfortunately Device, despite not being immutable, has an `operator ==`.
// Until we fix that, we have to also ignore related lints here.
// ignore: avoid_implementing_value_types
class ThrowingScreenshotDevice extends ScreenshotDevice {
  @override
  Future<LaunchResult> startApp(
    ApplicationPackage package, {
      String mainPath,
      String route,
      DebuggingOptions debuggingOptions,
      Map<String, dynamic> platformArgs,
      bool prebuiltApplication = false,
      bool usesTerminalUi = true,
      bool ipv6 = false,
      String userIdentifier,
    }) async {
    throwToolExit('cannot start app');
  }
}

// Unfortunately Device, despite not being immutable, has an `operator ==`.
// Until we fix that, we have to also ignore related lints here.
// ignore: avoid_implementing_value_types
class ScreenshotDevice extends Fake implements Device {
  @override
  final String name = 'FakeDevice';

  @override
  final Category category = Category.mobile;

  @override
  final String id = 'fake_device';

  @override
  Future<TargetPlatform> get targetPlatform async => TargetPlatform.android;

  @override
  bool supportsScreenshot = true;

  @override
  Future<LaunchResult> startApp(
    ApplicationPackage package, {
      String mainPath,
      String route,
      DebuggingOptions debuggingOptions,
      Map<String, dynamic> platformArgs,
      bool prebuiltApplication = false,
      bool usesTerminalUi = true,
      bool ipv6 = false,
      String userIdentifier,
    }) async => LaunchResult.succeeded();

  @override
  Future<void> takeScreenshot(File outputFile) async {}
}

class FakePub extends Fake implements Pub {
  @override
  Future<void> get({
    PubContext context,
    String directory,
    bool skipIfAbsent = false,
    bool upgrade = false,
    bool offline = false,
    bool generateSyntheticPackage = false,
    String flutterRootOverride,
    bool checkUpToDate = false,
    bool shouldSkipThirdPartyGenerator = true,
    bool printProgress = true,
  }) async { }
}

class FakeDeviceManager extends Fake implements DeviceManager {
  List<Device> devices = <Device>[];

  @override
  String specifiedDeviceId;

  @override
  Future<List<Device>> getDevices() async => devices;

  @override
  Future<List<Device>> findTargetDevices(FlutterProject flutterProject, {Duration timeout}) async => devices;
}

class FailingFakeFlutterDriverFactory extends Fake implements FlutterDriverFactory {
  @override
  DriverService createDriverService(bool web) => FailingFakeDriverService();
}

class FailingFakeDriverService extends Fake implements DriverService {
  @override
  Future<void> reuseApplication(Uri vmServiceUri, Device device, DebuggingOptions debuggingOptions, bool ipv6) async { }

  @override
  Future<int> startTest(
    String testFile,
    List<String> arguments,
    Map<String, String> environment,
    PackageConfig packageConfig, {
      bool headless,
      String chromeBinary,
      String browserName,
      bool androidEmulator,
      int driverPort,
      List<String> browserDimension,
      String profileMemory,
    }) async => 1;
}
