// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/android_device.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/drive.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:mockito/mockito.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/mocks.dart';

void main() {
  group('drive', () {
    DriveCommand command;
    Device mockDevice;
    Device mockUnsupportedDevice;
    MemoryFileSystem fs;
    Directory tempDir;

    setUpAll(() {
      Cache.disableLocking();
    });

    setUp(() {
      command = DriveCommand();
      applyMocksToCommand(command);
      fs = MemoryFileSystem();
      tempDir = fs.systemTempDirectory.createTempSync('flutter_drive_test.');
      fs.currentDirectory = tempDir;
      fs.directory('test').createSync();
      fs.directory('test_driver').createSync();
      fs.file('pubspec.yaml')..createSync();
      fs.file('.packages').createSync();
      setExitFunctionForTests();
      appStarter = (DriveCommand command) {
        throw 'Unexpected call to appStarter';
      };
      testRunner = (List<String> testArgs, String observatoryUri) {
        throw 'Unexpected call to testRunner';
      };
      appStopper = (DriveCommand command) {
        throw 'Unexpected call to appStopper';
      };
    });

    tearDown(() {
      command = null;
      restoreExitFunction();
      restoreAppStarter();
      restoreAppStopper();
      restoreTestRunner();
      tryToDelete(tempDir);
    });

    testUsingContext('returns 1 when test file is not found', () async {
      testDeviceManager.addDevice(MockDevice());

      final String testApp = fs.path.join(tempDir.path, 'test', 'e2e.dart');
      final String testFile = fs.path.join(tempDir.path, 'test_driver', 'e2e_test.dart');
      fs.file(testApp).createSync(recursive: true);

      final List<String> args = <String>[
        'drive',
        '--target=$testApp',
        '--no-pub',
      ];
      try {
        await createTestCommandRunner(command).run(args);
        fail('Expect exception');
      } on ToolExit catch (e) {
        expect(e.exitCode ?? 1, 1);
        expect(e.message, contains('Test file not found: $testFile'));
      }
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('returns 1 when app fails to run', () async {
      testDeviceManager.addDevice(MockDevice());
      appStarter = expectAsync1((DriveCommand command) async => null);

      final String testApp = fs.path.join(tempDir.path, 'test_driver', 'e2e.dart');
      final String testFile = fs.path.join(tempDir.path, 'test_driver', 'e2e_test.dart');

      final MemoryFileSystem memFs = fs;
      await memFs.file(testApp).writeAsString('main() { }');
      await memFs.file(testFile).writeAsString('main() { }');

      final List<String> args = <String>[
        'drive',
        '--target=$testApp',
        '--no-pub',
      ];
      try {
        await createTestCommandRunner(command).run(args);
        fail('Expect exception');
      } on ToolExit catch (e) {
        expect(e.exitCode, 1);
        expect(e.message, contains('Application failed to start. Will not run test. Quitting.'));
      }
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('returns 1 when app file is outside package', () async {
      final String appFile = fs.path.join(tempDir.dirname, 'other_app', 'app.dart');
      fs.file(appFile).createSync(recursive: true);
      final List<String> args = <String>[
        '--no-wrap',
        'drive',
        '--target=$appFile',
        '--no-pub',
      ];
      try {
        await createTestCommandRunner(command).run(args);
        fail('Expect exception');
      } on ToolExit catch (e) {
        expect(e.exitCode ?? 1, 1);
        expect(testLogger.errorText, contains(
            'Application file $appFile is outside the package directory ${tempDir.path}',
        ));
      }
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('returns 1 when app file is in the root dir', () async {
      final String appFile = fs.path.join(tempDir.path, 'main.dart');
      fs.file(appFile).createSync(recursive: true);
      final List<String> args = <String>[
        '--no-wrap',
        'drive',
        '--target=$appFile',
        '--no-pub',
      ];
      try {
        await createTestCommandRunner(command).run(args);
        fail('Expect exception');
      } on ToolExit catch (e) {
        expect(e.exitCode ?? 1, 1);
        expect(testLogger.errorText, contains(
            'Application file main.dart must reside in one of the '
            'sub-directories of the package structure, not in the root directory.',
        ));
      }
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('returns 0 when test ends successfully', () async {
      testDeviceManager.addDevice(MockDevice());

      final String testApp = fs.path.join(tempDir.path, 'test', 'e2e.dart');
      final String testFile = fs.path.join(tempDir.path, 'test_driver', 'e2e_test.dart');

      appStarter = expectAsync1((DriveCommand command) async {
        return LaunchResult.succeeded();
      });
      testRunner = expectAsync2((List<String> testArgs, String observatoryUri) async {
        expect(testArgs, <String>[testFile]);
        return null;
      });
      appStopper = expectAsync1((DriveCommand command) async {
        return true;
      });

      final MemoryFileSystem memFs = fs;
      await memFs.file(testApp).writeAsString('main() {}');
      await memFs.file(testFile).writeAsString('main() {}');

      final List<String> args = <String>[
        'drive',
        '--target=$testApp',
        '--no-pub',
      ];
      await createTestCommandRunner(command).run(args);
      expect(testLogger.errorText, isEmpty);
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('returns exitCode set by test runner', () async {
      testDeviceManager.addDevice(MockDevice());

      final String testApp = fs.path.join(tempDir.path, 'test', 'e2e.dart');
      final String testFile = fs.path.join(tempDir.path, 'test_driver', 'e2e_test.dart');

      appStarter = expectAsync1((DriveCommand command) async {
        return LaunchResult.succeeded();
      });
      testRunner = (List<String> testArgs, String observatoryUri) async {
        throwToolExit(null, exitCode: 123);
      };
      appStopper = expectAsync1((DriveCommand command) async {
        return true;
      });

      final MemoryFileSystem memFs = fs;
      await memFs.file(testApp).writeAsString('main() {}');
      await memFs.file(testFile).writeAsString('main() {}');

      final List<String> args = <String>[
        'drive',
        '--target=$testApp',
        '--no-pub',
      ];
      try {
        await createTestCommandRunner(command).run(args);
        fail('Expect exception');
      } on ToolExit catch (e) {
        expect(e.exitCode ?? 1, 123);
        expect(e.message, isNull);
      }
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => FakeProcessManager.any(),
    });

    group('findTargetDevice', () {
      testUsingContext('uses specified device', () async {
        testDeviceManager.specifiedDeviceId = '123';
        mockDevice = MockDevice();
        testDeviceManager.addDevice(mockDevice);
        when(mockDevice.name).thenReturn('specified-device');
        when(mockDevice.id).thenReturn('123');

        final Device device = await findTargetDevice();
        expect(device.name, 'specified-device');
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
      });
    });

    void findTargetDeviceOnOperatingSystem(String operatingSystem) {
      Platform platform() => FakePlatform(operatingSystem: operatingSystem);

      testUsingContext('returns null if no devices found', () async {
        expect(await findTargetDevice(), isNull);
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
        Platform: platform,
      });

      testUsingContext('uses existing Android device', () async {
        mockDevice = MockAndroidDevice();
        when(mockDevice.name).thenReturn('mock-android-device');
        testDeviceManager.addDevice(mockDevice);

        final Device device = await findTargetDevice();
        expect(device.name, 'mock-android-device');
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
        Platform: platform,
      });

      testUsingContext('skips unsupported device', () async {
        mockDevice = MockAndroidDevice();
        mockUnsupportedDevice = MockDevice();
        when(mockUnsupportedDevice.isSupportedForProject(any))
            .thenReturn(false);
        when(mockUnsupportedDevice.isSupported())
            .thenReturn(false);
        when(mockUnsupportedDevice.name).thenReturn('mock-web');
        when(mockUnsupportedDevice.id).thenReturn('web-1');
        when(mockUnsupportedDevice.targetPlatform).thenAnswer((_) => Future<TargetPlatform>(() => TargetPlatform.web_javascript));
        when(mockUnsupportedDevice.isLocalEmulator).thenAnswer((_) => Future<bool>(() => false));
        when(mockUnsupportedDevice.sdkNameAndVersion).thenAnswer((_) => Future<String>(() => 'html5'));
        when(mockDevice.name).thenReturn('mock-android-device');
        when(mockDevice.id).thenReturn('mad-28');
        when(mockDevice.isSupported())
            .thenReturn(true);
        when(mockDevice.isSupportedForProject(any))
            .thenReturn(true);
        when(mockDevice.targetPlatform).thenAnswer((_) => Future<TargetPlatform>(() => TargetPlatform.android_x64));
        when(mockDevice.isLocalEmulator).thenAnswer((_) => Future<bool>(() => false));
        when(mockDevice.sdkNameAndVersion).thenAnswer((_) => Future<String>(() => 'sdk-28'));
        testDeviceManager.addDevice(mockDevice);
        testDeviceManager.addDevice(mockUnsupportedDevice);

        final Device device = await findTargetDevice();
        expect(device.name, 'mock-android-device');
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
        Platform: platform,
      });
    }

    group('findTargetDevice on Linux', () {
      findTargetDeviceOnOperatingSystem('linux');
    });

    group('findTargetDevice on Windows', () {
      findTargetDeviceOnOperatingSystem('windows');
    });

    group('findTargetDevice on macOS', () {
      findTargetDeviceOnOperatingSystem('macos');

      Platform macOsPlatform() => FakePlatform(operatingSystem: 'macos');

      testUsingContext('uses existing simulator', () async {
        testDeviceManager.addDevice(mockDevice);
        when(mockDevice.name).thenReturn('mock-simulator');
        when(mockDevice.isLocalEmulator)
            .thenAnswer((Invocation invocation) => Future<bool>.value(true));

        final Device device = await findTargetDevice();
        expect(device.name, 'mock-simulator');
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
        Platform: macOsPlatform,
      });
    });

    group('build arguments', () {
      String testApp, testFile;

      setUp(() {
        restoreAppStarter();
      });

      Future<void> appStarterSetup() async {
        mockDevice = MockDevice();
        testDeviceManager.addDevice(mockDevice);

        final MockDeviceLogReader mockDeviceLogReader = MockDeviceLogReader();
        when(mockDevice.getLogReader()).thenReturn(mockDeviceLogReader);
        final MockLaunchResult mockLaunchResult = MockLaunchResult();
        when(mockLaunchResult.started).thenReturn(true);
        when(mockDevice.startApp(
            null,
            mainPath: anyNamed('mainPath'),
            route: anyNamed('route'),
            debuggingOptions: anyNamed('debuggingOptions'),
            platformArgs: anyNamed('platformArgs'),
            prebuiltApplication: anyNamed('prebuiltApplication'),
        )).thenAnswer((_) => Future<LaunchResult>.value(mockLaunchResult));
        when(mockDevice.isAppInstalled(any)).thenAnswer((_) => Future<bool>.value(false));

        testApp = fs.path.join(tempDir.path, 'test', 'e2e.dart');
        testFile = fs.path.join(tempDir.path, 'test_driver', 'e2e_test.dart');

        testRunner = (List<String> testArgs, String observatoryUri) async {
          throwToolExit(null, exitCode: 123);
        };
        appStopper = expectAsync1(
            (DriveCommand command) async {
              return true;
            },
            count: 2,
        );

        final MemoryFileSystem memFs = fs;
        await memFs.file(testApp).writeAsString('main() {}');
        await memFs.file(testFile).writeAsString('main() {}');
      }

      testUsingContext('does not use pre-built app if no build arg provided', () async {
        await appStarterSetup();

        final List<String> args = <String>[
          'drive',
          '--target=$testApp',
          '--no-pub',
        ];
        try {
          await createTestCommandRunner(command).run(args);
        } on ToolExit catch (e) {
          expect(e.exitCode, 123);
          expect(e.message, null);
        }
        verify(mockDevice.startApp(
                null,
                mainPath: anyNamed('mainPath'),
                route: anyNamed('route'),
                debuggingOptions: anyNamed('debuggingOptions'),
                platformArgs: anyNamed('platformArgs'),
                prebuiltApplication: false,
        ));
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
      });

      testUsingContext('does not use pre-built app if --build arg provided', () async {
        await appStarterSetup();

        final List<String> args = <String>[
          'drive',
          '--build',
          '--target=$testApp',
          '--no-pub',
        ];
        try {
          await createTestCommandRunner(command).run(args);
        } on ToolExit catch (e) {
          expect(e.exitCode, 123);
          expect(e.message, null);
        }
        verify(mockDevice.startApp(
                null,
                mainPath: anyNamed('mainPath'),
                route: anyNamed('route'),
                debuggingOptions: anyNamed('debuggingOptions'),
                platformArgs: anyNamed('platformArgs'),
                prebuiltApplication: false,
        ));
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
      });

      testUsingContext('uses prebuilt app if --no-build arg provided', () async {
        await appStarterSetup();

        final List<String> args = <String>[
          'drive',
          '--no-build',
          '--target=$testApp',
          '--no-pub',
        ];
        try {
          await createTestCommandRunner(command).run(args);
        } on ToolExit catch (e) {
          expect(e.exitCode, 123);
          expect(e.message, null);
        }
        verify(mockDevice.startApp(
                null,
                mainPath: anyNamed('mainPath'),
                route: anyNamed('route'),
                debuggingOptions: anyNamed('debuggingOptions'),
                platformArgs: anyNamed('platformArgs'),
                prebuiltApplication: true,
        ));
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
      });
    });
  });
}

class MockDevice extends Mock implements Device {
  MockDevice() {
    when(isSupported()).thenReturn(true);
  }
}

class MockAndroidDevice extends Mock implements AndroidDevice { }

class MockLaunchResult extends Mock implements LaunchResult { }
