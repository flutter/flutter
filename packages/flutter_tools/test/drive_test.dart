// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/android_device.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/commands/drive.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/ios/simulators.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'src/common.dart';
import 'src/context.dart';
import 'src/mocks.dart';

void main() {
  group('drive', () {
    DriveCommand command;
    Device mockDevice;
    MemoryFileSystem fs;
    Directory cwd;

    void withMockDevice([Device mock]) {
      mockDevice = mock ?? new MockDevice();
      targetDeviceFinder = () async => mockDevice;
      testDeviceManager.addDevice(mockDevice);
    }

    setUp(() {
      command = new DriveCommand();
      applyMocksToCommand(command);
      fs = new MemoryFileSystem();
      cwd = fs.systemTempDirectory.createTempSync('some_app_');
      fs.currentDirectory = cwd;
      fs.directory('test').createSync();
      fs.directory('test_driver').createSync();
      fs.file('pubspec.yaml')..createSync();
      fs.file('.packages').createSync();
      setExitFunctionForTests();
      targetDeviceFinder = () {
        throw 'Unexpected call to targetDeviceFinder';
      };
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
      restoreTargetDeviceFinder();
    });

    testUsingContext('returns 1 when test file is not found', () async {
      withMockDevice();

      String testApp = fs.path.join(cwd.path, 'test', 'e2e.dart');
      String testFile = fs.path.join(cwd.path, 'test_driver', 'e2e_test.dart');

      List<String> args = <String>[
        'drive',
        '--target=$testApp}',
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
    });

    testUsingContext('returns 1 when app fails to run', () async {
      withMockDevice();
      appStarter = expectAsync1((DriveCommand command) async => null);

      String testApp = fs.path.join(cwd.path, 'test_driver', 'e2e.dart');
      String testFile = fs.path.join(cwd.path, 'test_driver', 'e2e_test.dart');

      MemoryFileSystem memFs = fs;
      await memFs.file(testApp).writeAsString('main() { }');
      await memFs.file(testFile).writeAsString('main() { }');

      List<String> args = <String>[
        'drive',
        '--target=$testApp',
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
    });

    testUsingContext('returns 1 when app file is outside package', () async {
      String appFile = fs.path.join(cwd.dirname, 'other_app', 'app.dart');
      List<String> args = <String>[
        'drive',
        '--target=$appFile',
      ];
      try {
        await createTestCommandRunner(command).run(args);
        fail('Expect exception');
      } on ToolExit catch (e) {
        expect(e.exitCode ?? 1, 1);
        expect(testLogger.errorText, contains(
            'Application file $appFile is outside the package directory ${cwd.path}',
        ));
      }
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
    });

    testUsingContext('returns 1 when app file is in the root dir', () async {
      String appFile = fs.path.join(cwd.path, 'main.dart');
      List<String> args = <String>[
        'drive',
        '--target=$appFile',
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
    });

    testUsingContext('returns 0 when test ends successfully', () async {
      withMockDevice();

      String testApp = fs.path.join(cwd.path, 'test', 'e2e.dart');
      String testFile = fs.path.join(cwd.path, 'test_driver', 'e2e_test.dart');

      appStarter = expectAsync1((DriveCommand command) async {
        return new LaunchResult.succeeded();
      });
      testRunner = expectAsync2((List<String> testArgs, String observatoryUri) async {
        expect(testArgs, <String>[testFile]);
        return null;
      });
      appStopper = expectAsync1((DriveCommand command) async {
        return true;
      });

      MemoryFileSystem memFs = fs;
      await memFs.file(testApp).writeAsString('main() {}');
      await memFs.file(testFile).writeAsString('main() {}');

      List<String> args = <String>[
        'drive',
        '--target=$testApp',
      ];
      await createTestCommandRunner(command).run(args);
      expect(testLogger.errorText, isEmpty);
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
    });

    testUsingContext('returns exitCode set by test runner', () async {
      withMockDevice();

      String testApp = fs.path.join(cwd.path, 'test', 'e2e.dart');
      String testFile = fs.path.join(cwd.path, 'test_driver', 'e2e_test.dart');

      appStarter = expectAsync1((DriveCommand command) async {
        return new LaunchResult.succeeded();
      });
      testRunner = (List<String> testArgs, String observatoryUri) async {
        throwToolExit(null, exitCode: 123);
      };
      appStopper = expectAsync1((DriveCommand command) async {
        return true;
      });

      MemoryFileSystem memFs = fs;
      await memFs.file(testApp).writeAsString('main() {}');
      await memFs.file(testFile).writeAsString('main() {}');

      List<String> args = <String>[
        'drive',
        '--target=$testApp',
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
    });

    group('findTargetDevice', () {
      testUsingContext('uses specified device', () async {
        testDeviceManager.specifiedDeviceId = '123';
        withMockDevice();
        when(mockDevice.name).thenReturn('specified-device');
        when(mockDevice.id).thenReturn('123');

        Device device = await findTargetDevice();
        expect(device.name, 'specified-device');
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
      });
    });

    group('findTargetDevice on iOS', () {
      void setOs() {
        when(os.isMacOS).thenReturn(true);
        when(os.isLinux).thenReturn(false);
        when(os.isWindows).thenReturn(false);
      }

      testUsingContext('uses existing emulator', () async {
        setOs();
        withMockDevice();
        when(mockDevice.name).thenReturn('mock-simulator');
        when(mockDevice.isLocalEmulator).thenReturn(true);

        Device device = await findTargetDevice();
        expect(device.name, 'mock-simulator');
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
      });

      testUsingContext('uses existing Android device if and there are no simulators', () async {
        setOs();
        mockDevice = new MockAndroidDevice();
        when(mockDevice.name).thenReturn('mock-android-device');
        when(mockDevice.isLocalEmulator).thenReturn(false);
        withMockDevice(mockDevice);

        Device device = await findTargetDevice();
        expect(device.name, 'mock-android-device');
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
      });

      testUsingContext('launches emulator', () async {
        setOs();
        when(SimControl.instance.boot()).thenReturn(true);
        Device emulator = new MockDevice();
        when(emulator.name).thenReturn('new-simulator');
        when(IOSSimulatorUtils.instance.getAttachedDevices())
            .thenReturn(<Device>[emulator]);

        Device device = await findTargetDevice();
        expect(device.name, 'new-simulator');
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
      });
    });

    void findTargetDeviceOnLinuxOrWindows({bool isWindows: false, bool isLinux: false}) {
      assert(isWindows != isLinux);
      void setOs() {
        when(os.isMacOS).thenReturn(false);
        when(os.isLinux).thenReturn(isLinux);
        when(os.isWindows).thenReturn(isWindows);
      }

      testUsingContext('returns null if no devices found', () async {
        setOs();
        expect(await findTargetDevice(), isNull);
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
      });

      testUsingContext('uses existing Android device', () async {
        setOs();
        mockDevice = new MockAndroidDevice();
        when(mockDevice.name).thenReturn('mock-android-device');
        withMockDevice(mockDevice);

        Device device = await findTargetDevice();
        expect(device.name, 'mock-android-device');
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
      });
    }

    group('findTargetDevice on Linux', () {
      findTargetDeviceOnLinuxOrWindows(isLinux: true);
    });

    group('findTargetDevice on Windows', () {
      findTargetDeviceOnLinuxOrWindows(isWindows: true);
    });
  });
}

class MockDevice extends Mock implements Device {
  MockDevice() {
    when(this.isSupported()).thenReturn(true);
  }
}

class MockAndroidDevice extends Mock implements AndroidDevice { }
