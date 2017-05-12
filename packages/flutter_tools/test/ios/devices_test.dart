// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io' show ProcessResult;

import 'package:file/file.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/ios/devices.dart';
import 'package:mockito/mockito.dart';
import 'package:platform/platform.dart';
import 'package:process/process.dart';
import 'package:test/test.dart';

import '../src/context.dart';

class MockProcessManager extends Mock implements ProcessManager {}
class MockFile extends Mock implements File {}

void main() {
  final FakePlatform osx = new FakePlatform.fromPlatform(const LocalPlatform());
  osx.operatingSystem = 'macos';

  group('test screenshot', () {
    MockProcessManager mockProcessManager;
    MockFile mockOutputFile;
    IOSDevice iosDeviceUnderTest;

    setUp(() {
      mockProcessManager = new MockProcessManager();
      mockOutputFile = new MockFile();
    });

    testUsingContext(
      'screenshot without ideviceinstaller error',
      () async {
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
      }
    );

    testUsingContext(
      'screenshot with ideviceinstaller gets command',
      () async {
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
      },
      overrides: <Type, Generator>{ProcessManager: () => mockProcessManager}
    );
  });
}
