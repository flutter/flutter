// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;

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
    MemoryFileSystem memoryFileSystem;

    void withMockDevice([Device mock]) {
      mockDevice = mock ?? new MockDevice();
      targetDeviceFinder = () async => mockDevice;
      testDeviceManager.addDevice(mockDevice);
    }

    setUp(() {
      command = new DriveCommand();
      applyMocksToCommand(command);
      memoryFileSystem = new MemoryFileSystem();
      String cwd = '/some/app';
      memoryFileSystem.directory(cwd).createSync(recursive: true);
      memoryFileSystem.currentDirectory = cwd;
      memoryFileSystem.directory('test').createSync();
      memoryFileSystem.directory('test_driver').createSync();
      memoryFileSystem.file('pubspec.yaml').createSync();
      memoryFileSystem.file('.packages').createSync();
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
      List<String> args = <String>[
        'drive',
        '--target=/some/app/test/e2e.dart',
      ];
      try {
        await createTestCommandRunner(command).run(args);
        fail('Expect exception');
      } on ToolExit catch (e) {
        expect(e.exitCode ?? 1, 1);
        expect(e.message, contains('Test file not found: /some/app/test_driver/e2e_test.dart'));
      }
    }, overrides: <Type, Generator>{
      FileSystem: () => memoryFileSystem,
    });

    testUsingContext('returns 1 when app fails to run', () async {
      withMockDevice();
      appStarter = expectAsync((DriveCommand command) async => null);

      String testApp = '/some/app/test_driver/e2e.dart';
      String testFile = '/some/app/test_driver/e2e_test.dart';

      MemoryFileSystem memFs = memoryFileSystem;
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
      FileSystem: () => memoryFileSystem,
    });

    testUsingContext('returns 1 when app file is outside package', () async {
      String appFile = '/not/in/my/app.dart';
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
          'Application file $appFile is outside the package directory /some/app',
        ));
      }
    }, overrides: <Type, Generator>{
      FileSystem: () => memoryFileSystem,
    });

    testUsingContext('returns 1 when app file is in the root dir', () async {
      String appFile = '/some/app/main.dart';
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
      FileSystem: () => memoryFileSystem,
    });

    testUsingContext('returns 0 when test ends successfully', () async {
      withMockDevice();

      String testApp = '/some/app/test/e2e.dart';
      String testFile = '/some/app/test_driver/e2e_test.dart';

      appStarter = expectAsync((DriveCommand command) async {
        return new LaunchResult.succeeded();
      });
      testRunner = expectAsync((List<String> testArgs, String observatoryUri) async {
        expect(testArgs, <String>[testFile]);
        return null;
      });
      appStopper = expectAsync((DriveCommand command) async {
        return true;
      });

      MemoryFileSystem memFs = memoryFileSystem;
      await memFs.file(testApp).writeAsString('main() {}');
      await memFs.file(testFile).writeAsString('main() {}');

      List<String> args = <String>[
        'drive',
        '--target=$testApp',
      ];
      await createTestCommandRunner(command).run(args);
      expect(testLogger.errorText, isEmpty);
    }, overrides: <Type, Generator>{
      FileSystem: () => memoryFileSystem,
    });

    testUsingContext('returns exitCode set by test runner', () async {
      withMockDevice();

      String testApp = '/some/app/test/e2e.dart';
      String testFile = '/some/app/test_driver/e2e_test.dart';

      appStarter = expectAsync((DriveCommand command) async {
        return new LaunchResult.succeeded();
      });
      testRunner = (List<String> testArgs, String observatoryUri) async {
        throwToolExit(null, exitCode: 123);
      };
      appStopper = expectAsync((DriveCommand command) async {
        return true;
      });

      MemoryFileSystem memFs = memoryFileSystem;
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
      FileSystem: () => memoryFileSystem,
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
        FileSystem: () => memoryFileSystem,
      });
    });

    group('findTargetDevice on iOS', () {
      void setOs() {
        when(os.isMacOS).thenReturn(true);
        when(os.isLinux).thenReturn(false);
      }

      testUsingContext('uses existing emulator', () async {
        setOs();
        withMockDevice();
        when(mockDevice.name).thenReturn('mock-simulator');
        when(mockDevice.isLocalEmulator).thenReturn(true);

        Device device = await findTargetDevice();
        expect(device.name, 'mock-simulator');
      }, overrides: <Type, Generator>{
        FileSystem: () => memoryFileSystem,
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
        FileSystem: () => memoryFileSystem,
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
        FileSystem: () => memoryFileSystem,
      });
    });

    group('findTargetDevice on Linux', () {
      void setOs() {
        when(os.isMacOS).thenReturn(false);
        when(os.isLinux).thenReturn(true);
      }

      testUsingContext('returns null if no devices found', () async {
        setOs();
        expect(await findTargetDevice(), isNull);
      }, overrides: <Type, Generator>{
        FileSystem: () => memoryFileSystem,
      });

      testUsingContext('uses existing Android device', () async {
        setOs();
        mockDevice = new MockAndroidDevice();
        when(mockDevice.name).thenReturn('mock-android-device');
        withMockDevice(mockDevice);

        Device device = await findTargetDevice();
        expect(device.name, 'mock-android-device');
      }, overrides: <Type, Generator>{
        FileSystem: () => memoryFileSystem,
      });
    });
  }, skip: io.Platform.isWindows); // TODO(goderbauer): enable when drive command is working
}

class MockDevice extends Mock implements Device {
  MockDevice() {
    when(this.isSupported()).thenReturn(true);
  }
}

class MockAndroidDevice extends Mock implements AndroidDevice { }
