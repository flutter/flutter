// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/android_device.dart';
import 'package:flutter_tools/src/android/android_sdk.dart';
import 'package:flutter_tools/src/application_package.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:mockito/mockito.dart';

import '../../src/common.dart';
import '../../src/context.dart';

const FakeCommand kAdbVersionCommand = FakeCommand(
  command: <String>['adb', 'version'],
  stdout: 'Android Debug Bridge version 1.0.39',
);
const FakeCommand kAdbStartServerCommand = FakeCommand(
  command: <String>['adb', 'start-server']
);
const FakeCommand kInstallCommand = FakeCommand(
  command: <String>['adb', '-s', '1234', 'install', '-t', '-r', 'app.apk'],
);
const FakeCommand kStoreShaCommand = FakeCommand(
  command: <String>['adb', '-s', '1234', 'shell', 'echo', '-n', '', '>', '/data/local/tmp/sky.app.sha1']
);

void main() {
  testUsingContext('Cannot install app on API level below 16', () async {
    final File apk = globals.fs.file('app.apk')..createSync();
    final AndroidApk androidApk = AndroidApk(
      file: apk,
      id: 'app',
      versionCode: 22,
      launchActivity: 'Main',
    );
    final AndroidDevice androidDevice = AndroidDevice('1234');
    when(globals.androidSdk.adbPath).thenReturn('adb');
    final FakeProcessManager processManager = globals.processManager as FakeProcessManager;

    expect(await androidDevice.installApp(androidApk), false);
    expect(processManager.hasRemainingExpectations, false);
  }, overrides: <Type, Generator>{
    ProcessManager: () => FakeProcessManager.list(<FakeCommand>[
      kAdbVersionCommand,
      kAdbStartServerCommand,
      const FakeCommand(
        command: <String>['adb', '-s', '1234', 'shell', 'getprop'],
        stdout: '[ro.build.version.sdk]: [11]',
      ),
    ]),
    FileSystem: () => MemoryFileSystem.test(),
    AndroidSdk: () => MockAndroidSdk(),
  });

  testUsingContext('Cannot install app if APK file is missing', () async {
    final File apk = globals.fs.file('app.apk');
    final AndroidApk androidApk = AndroidApk(
      file: apk,
      id: 'app',
      versionCode: 22,
      launchActivity: 'Main',
    );
    final AndroidDevice androidDevice = AndroidDevice('1234');

    expect(await androidDevice.installApp(androidApk), false);
  }, overrides: <Type, Generator>{
    ProcessManager: () => FakeProcessManager.list(<FakeCommand>[]),
    FileSystem: () => MemoryFileSystem.test(),
    AndroidSdk: () => MockAndroidSdk(),
  });

  testUsingContext('Can install app on API level 16 or greater', () async {
    final File apk = globals.fs.file('app.apk')..createSync();
    final AndroidApk androidApk = AndroidApk(
      file: apk,
      id: 'app',
      versionCode: 22,
      launchActivity: 'Main',
    );
    final AndroidDevice androidDevice = AndroidDevice('1234');
    when(globals.androidSdk.adbPath).thenReturn('adb');
    final FakeProcessManager processManager = globals.processManager as FakeProcessManager;

    expect(await androidDevice.installApp(androidApk), true);
    expect(processManager.hasRemainingExpectations, false);
  }, overrides: <Type, Generator>{
    ProcessManager: () => FakeProcessManager.list(<FakeCommand>[
      kAdbVersionCommand,
      kAdbStartServerCommand,
      const FakeCommand(
        command: <String>['adb', '-s', '1234', 'shell', 'getprop'],
        stdout: '[ro.build.version.sdk]: [16]',
      ),
      kInstallCommand,
      kStoreShaCommand,
    ]),
    FileSystem: () => MemoryFileSystem.test(),
    AndroidSdk: () => MockAndroidSdk(),
  });

  testUsingContext('Defaults to API level 16 if adb returns a null response', () async {
    final File apk = globals.fs.file('app.apk')..createSync();
    final AndroidApk androidApk = AndroidApk(
      file: apk,
      id: 'app',
      versionCode: 22,
      launchActivity: 'Main',
    );
    final AndroidDevice androidDevice = AndroidDevice('1234');
    when(globals.androidSdk.adbPath).thenReturn('adb');
    final FakeProcessManager processManager = globals.processManager as FakeProcessManager;

    expect(await androidDevice.installApp(androidApk), true);
    expect(processManager.hasRemainingExpectations, false);
  }, overrides: <Type, Generator>{
    ProcessManager: () => FakeProcessManager.list(<FakeCommand>[
      kAdbVersionCommand,
      kAdbStartServerCommand,
      const FakeCommand(
        command: <String>['adb', '-s', '1234', 'shell', 'getprop'],
      ),
      kInstallCommand,
      kStoreShaCommand,
    ]),
    FileSystem: () => MemoryFileSystem.test(),
    AndroidSdk: () => MockAndroidSdk(),
  });
}

class MockAndroidSdk extends Mock implements AndroidSdk {}
