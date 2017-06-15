// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io' show ProcessResult;

import 'package:file/file.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/ios/devices.dart';
import 'package:flutter_tools/src/ios/mac.dart';
import 'package:mockito/mockito.dart';
import 'package:platform/platform.dart';
import 'package:process/process.dart';
import 'package:test/test.dart';

import '../src/context.dart';

class MockProcessManager extends Mock implements ProcessManager {}
class MockIMobileDevice extends Mock implements IMobileDevice {}
class MockFile extends Mock implements File {}

void main() {
  final FakePlatform osx = new FakePlatform.fromPlatform(const LocalPlatform());
  osx.operatingSystem = 'macos';

  group('getAttachedDevices', () {
    MockIMobileDevice mockIMobileDevice;

    setUp(() {
      mockIMobileDevice = new MockIMobileDevice();
    });

    testUsingContext('return no devices if libimobiledevice is not installed', () async {
      when(mockIMobileDevice.isInstalled).thenReturn(false);
      expect(IOSDevice.getAttachedDevices(), isEmpty);
    }, overrides: <Type, Generator>{
      IMobileDevice: () => mockIMobileDevice,
    });

    testUsingContext('returns no devices if none are attached', () async {
      when(mockIMobileDevice.isInstalled).thenReturn(true);
      when(mockIMobileDevice.getAttachedDeviceIDs()).thenReturn(<String>[]);
      final List<IOSDevice> devices = IOSDevice.getAttachedDevices();
      expect(devices, isEmpty);
    }, overrides: <Type, Generator>{
      IMobileDevice: () => mockIMobileDevice,
    });

    testUsingContext('returns attached devices', () async {
      when(mockIMobileDevice.isInstalled).thenReturn(true);
      when(mockIMobileDevice.getAttachedDeviceIDs()).thenReturn(<String>[
        '98206e7a4afd4aedaff06e687594e089dede3c44',
        'f577a7903cc54959be2e34bc4f7f80b7009efcf4',
      ]);
      when(mockIMobileDevice.getInfoForDevice('98206e7a4afd4aedaff06e687594e089dede3c44', 'DeviceName'))
          .thenReturn('La tele me regarde');
      when(mockIMobileDevice.getInfoForDevice('f577a7903cc54959be2e34bc4f7f80b7009efcf4', 'DeviceName'))
          .thenReturn('Puits sans fond');
      final List<IOSDevice> devices = IOSDevice.getAttachedDevices();
      expect(devices, hasLength(2));
      expect(devices[0].id, '98206e7a4afd4aedaff06e687594e089dede3c44');
      expect(devices[0].name, 'La tele me regarde');
      expect(devices[1].id, 'f577a7903cc54959be2e34bc4f7f80b7009efcf4');
      expect(devices[1].name, 'Puits sans fond');
    }, overrides: <Type, Generator>{
      IMobileDevice: () => mockIMobileDevice,
    });
  });

  group('screenshot', () {
    MockProcessManager mockProcessManager;
    MockFile mockOutputFile;
    IOSDevice iosDeviceUnderTest;

    setUp(() {
      mockProcessManager = new MockProcessManager();
      mockOutputFile = new MockFile();
    });

    testUsingContext('error if idevicescreenshot is not installed', () async {
      when(mockOutputFile.path).thenReturn(fs.path.join('some', 'test', 'path', 'image.png'));
      // Let everything else return exit code 0 so process.dart doesn't crash.
      // The matcher order is important.
      when(
        mockProcessManager.run(any, environment: null, workingDirectory:  null)
      ).thenReturn(
        new Future<ProcessResult>.value(new ProcessResult(2, 0, '', ''))
      );
      // Let `which idevicescreenshot` fail with exit code 1.
      when(
        mockProcessManager.runSync(
          <String>['which', 'idevicescreenshot'], environment: null, workingDirectory: null)
      ).thenReturn(
        new ProcessResult(1, 1, '', '')
      );

      iosDeviceUnderTest = new IOSDevice('1234');
      await iosDeviceUnderTest.takeScreenshot(mockOutputFile);
      verify(mockProcessManager.runSync(
        <String>['which', 'idevicescreenshot'], environment: null, workingDirectory: null));
      verifyNever(mockProcessManager.run(
        <String>['idevicescreenshot', fs.path.join('some', 'test', 'path', 'image.png')],
        environment: null,
        workingDirectory: null
      ));
      expect(testLogger.errorText, contains('brew install ideviceinstaller'));
    },
    overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
      Platform: () => osx,
    });

    testUsingContext('idevicescreenshot captures and returns screenshot', () async {
      when(mockOutputFile.path).thenReturn(fs.path.join('some', 'test', 'path', 'image.png'));
      // Let everything else return exit code 0.
      // The matcher order is important.
      when(
        mockProcessManager.run(any, environment: null, workingDirectory:  null)
      ).thenReturn(
        new Future<ProcessResult>.value(new ProcessResult(4, 0, '', ''))
      );
      // Let there be idevicescreenshot in the PATH.
      when(
        mockProcessManager.runSync(
          <String>['which', 'idevicescreenshot'], environment: null, workingDirectory: null)
      ).thenReturn(
        new ProcessResult(3, 0, fs.path.join('some', 'path', 'to', 'iscreenshot'), '')
      );

      iosDeviceUnderTest = new IOSDevice('1234');
      await iosDeviceUnderTest.takeScreenshot(mockOutputFile);
      verify(mockProcessManager.runSync(
        <String>['which', 'idevicescreenshot'], environment: null, workingDirectory: null));
      verify(mockProcessManager.run(
        <String>[
          fs.path.join('some', 'path', 'to', 'iscreenshot'),
          fs.path.join('some', 'test', 'path', 'image.png')
        ],
        environment: null,
        workingDirectory: null
      ));
    }, overrides: <Type, Generator>{ProcessManager: () => mockProcessManager});
  });
}
