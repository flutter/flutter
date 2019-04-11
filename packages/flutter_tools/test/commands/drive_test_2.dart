// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/android_device.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
//import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/drive.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:mockito/mockito.dart';

import '../src/common.dart';
import '../src/context.dart';
import '../src/mocks.dart';

void main() {
  group('AppStarter', () {
    DriveCommand command;
    Device mockDevice;
    MemoryFileSystem fs;
    Directory tempDir;

    void withMockDevice([ Device mock ]) {
      mockDevice = mock ?? MockDevice();
      targetDeviceFinder = () async => mockDevice;
      testDeviceManager.addDevice(mockDevice);
    }

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
      targetDeviceFinder = () {
        throw 'Unexpected call to targetDeviceFinder';
      };
      //appStarter = (DriveCommand command) {
      //  throw 'Unexpected call to appStarter';
      //};
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
      tryToDelete(tempDir);
    });

    testUsingContext('--build', () async {
      withMockDevice();

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
              usesTerminalUi: false,
      )).thenAnswer((_) => Future<LaunchResult>.value(mockLaunchResult));

      final String testApp = fs.path.join(tempDir.path, 'test', 'e2e.dart');
      final String testFile = fs.path.join(tempDir.path, 'test_driver', 'e2e_test.dart');

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

      final List<String> args = <String>[
        'drive',
        '--no-build',
        '--target=$testApp',
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
              usesTerminalUi: false,
      ));

    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
    });
  });
}

class MockDevice extends Mock implements Device {
  MockDevice() {
    when(isSupported()).thenReturn(true);
  }
}

class MockStream extends Mock implements Stream<String> { }

class MockLaunchResult extends Mock implements LaunchResult { }

class MockAndroidDevice extends Mock implements AndroidDevice { }
