// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/android_device.dart';
import 'package:flutter_tools/src/android/android_sdk.dart';
import 'package:flutter_tools/src/application_package.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
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
  testWithoutContext('Cannot install app on API level below 16', () async {
    final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
      kAdbVersionCommand,
      kAdbStartServerCommand,
      const FakeCommand(
        command: <String>['adb', '-s', '1234', 'shell', 'getprop'],
        stdout: '[ro.build.version.sdk]: [11]',
      ),
    ]);
    final FileSystem fileSystem = MemoryFileSystem.test();
    final File apk = fileSystem.file('app.apk')..createSync();
    final AndroidApk androidApk = AndroidApk(
      file: apk,
      id: 'app',
      versionCode: 22,
      launchActivity: 'Main',
    );
    final AndroidDevice androidDevice = setUpAndroidDevice(
      fileSystem: fileSystem,
      processManager: processManager,
    );

    expect(await androidDevice.installApp(androidApk), false);
    expect(processManager.hasRemainingExpectations, false);
  });

  testWithoutContext('Cannot install app if APK file is missing', () async {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final File apk = fileSystem.file('app.apk');
    final AndroidApk androidApk = AndroidApk(
      file: apk,
      id: 'app',
      versionCode: 22,
      launchActivity: 'Main',
    );
    final AndroidDevice androidDevice = setUpAndroidDevice(
      fileSystem: fileSystem,
    );

    expect(await androidDevice.installApp(androidApk), false);
  });

  testWithoutContext('Can install app on API level 16 or greater', () async {
    final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
      kAdbVersionCommand,
      kAdbStartServerCommand,
      const FakeCommand(
        command: <String>['adb', '-s', '1234', 'shell', 'getprop'],
        stdout: '[ro.build.version.sdk]: [16]',
      ),
      kInstallCommand,
      kStoreShaCommand,
    ]);
    final FileSystem fileSystem = MemoryFileSystem.test();
    final File apk = fileSystem.file('app.apk')..createSync();
    final AndroidApk androidApk = AndroidApk(
      file: apk,
      id: 'app',
      versionCode: 22,
      launchActivity: 'Main',
    );
    final AndroidDevice androidDevice = setUpAndroidDevice(
      fileSystem: fileSystem,
      processManager: processManager,
    );

    expect(await androidDevice.installApp(androidApk), true);
    expect(processManager.hasRemainingExpectations, false);
  });

  testWithoutContext('Defaults to API level 16 if adb returns a null response', () async {
    final FakeProcessManager processManager =  FakeProcessManager.list(<FakeCommand>[
      kAdbVersionCommand,
      kAdbStartServerCommand,
      const FakeCommand(
        command: <String>['adb', '-s', '1234', 'shell', 'getprop'],
      ),
      kInstallCommand,
      kStoreShaCommand,
    ]);
    final FileSystem fileSystem = MemoryFileSystem.test();
    final File apk = fileSystem.file('app.apk')..createSync();
    final AndroidApk androidApk = AndroidApk(
      file: apk,
      id: 'app',
      versionCode: 22,
      launchActivity: 'Main',
    );
    final AndroidDevice androidDevice = setUpAndroidDevice(
      fileSystem: fileSystem,
      processManager: processManager,
    );

    expect(await androidDevice.installApp(androidApk), true);
    expect(processManager.hasRemainingExpectations, false);
  });
}

AndroidDevice setUpAndroidDevice({
  AndroidSdk androidSdk,
  FileSystem fileSystem,
  ProcessManager processManager,
}) {
  androidSdk ??= MockAndroidSdk();
  when(androidSdk.adbPath).thenReturn('adb');
  return AndroidDevice('1234',
    logger: BufferLogger.test(),
    platform: FakePlatform(operatingSystem: 'linux'),
    androidSdk: androidSdk,
    fileSystem: fileSystem ?? MemoryFileSystem.test(),
    processManager: processManager ?? FakeProcessManager.any(),
  );
}

class MockAndroidSdk extends Mock implements AndroidSdk {}
