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
  command: <String>[
    'adb',
    '-s',
    '1234',
    'install',
    '-t',
    '-r',
    '--user',
    '10',
    'app.apk'
  ],
);
const FakeCommand kStoreShaCommand = FakeCommand(
  command: <String>['adb', '-s', '1234', 'shell', 'echo', '-n', '', '>', '/data/local/tmp/sky.app.sha1']
);

void main() {
  FileSystem fileSystem;
  BufferLogger logger;

  setUp(() {
    fileSystem = MemoryFileSystem.test();
    logger = BufferLogger.test();
  });

  AndroidDevice setUpAndroidDevice({
    AndroidSdk androidSdk,
    ProcessManager processManager,
  }) {
    androidSdk ??= MockAndroidSdk();
    when(androidSdk.adbPath).thenReturn('adb');
    return AndroidDevice('1234',
      logger: logger,
      platform: FakePlatform(operatingSystem: 'linux'),
      androidSdk: androidSdk,
      fileSystem: fileSystem ?? MemoryFileSystem.test(),
      processManager: processManager ?? FakeProcessManager.any(),
    );
  }

  testWithoutContext('Cannot install app on API level below 16', () async {
    final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
      kAdbVersionCommand,
      kAdbStartServerCommand,
      const FakeCommand(
        command: <String>['adb', '-s', '1234', 'shell', 'getprop'],
        stdout: '[ro.build.version.sdk]: [11]',
      ),
    ]);
    final File apk = fileSystem.file('app.apk')..createSync();
    final AndroidApk androidApk = AndroidApk(
      file: apk,
      id: 'app',
      versionCode: 22,
      launchActivity: 'Main',
    );
    final AndroidDevice androidDevice = setUpAndroidDevice(
      processManager: processManager,
    );

    expect(await androidDevice.installApp(androidApk), false);
    expect(processManager.hasRemainingExpectations, false);
  });

  testWithoutContext('Cannot install app if APK file is missing', () async {
    final File apk = fileSystem.file('app.apk');
    final AndroidApk androidApk = AndroidApk(
      file: apk,
      id: 'app',
      versionCode: 22,
      launchActivity: 'Main',
    );
    final AndroidDevice androidDevice = setUpAndroidDevice(
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
    final File apk = fileSystem.file('app.apk')..createSync();
    final AndroidApk androidApk = AndroidApk(
      file: apk,
      id: 'app',
      versionCode: 22,
      launchActivity: 'Main',
    );
    final AndroidDevice androidDevice = setUpAndroidDevice(
      processManager: processManager,
    );

    expect(await androidDevice.installApp(androidApk, userIdentifier: '10'), true);
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
    final File apk = fileSystem.file('app.apk')..createSync();
    final AndroidApk androidApk = AndroidApk(
      file: apk,
      id: 'app',
      versionCode: 22,
      launchActivity: 'Main',
    );
    final AndroidDevice androidDevice = setUpAndroidDevice(
      processManager: processManager,
    );

    expect(await androidDevice.installApp(androidApk, userIdentifier: '10'), true);
    expect(processManager.hasRemainingExpectations, false);
  });

  testWithoutContext('displays error if user not found', () async {
    final FakeProcessManager processManager =  FakeProcessManager.list(<FakeCommand>[
      kAdbVersionCommand,
      kAdbStartServerCommand,
      const FakeCommand(
        command: <String>['adb', '-s', '1234', 'shell', 'getprop'],
      ),
      const FakeCommand(
        command: <String>[
          'adb',
          '-s',
          '1234',
          'install',
          '-t',
          '-r',
          '--user',
          'jane',
          'app.apk'
        ],
        exitCode: 1,
        stderr: 'Exception occurred while executing: java.lang.IllegalArgumentException: Bad user number: jane',
      ),
    ]);
    final File apk = fileSystem.file('app.apk')..createSync();
    final AndroidApk androidApk = AndroidApk(
      file: apk,
      id: 'app',
      versionCode: 22,
      launchActivity: 'Main',
    );
    final AndroidDevice androidDevice = setUpAndroidDevice(
      processManager: processManager,
    );

    expect(await androidDevice.installApp(androidApk, userIdentifier: 'jane'), false);
    expect(logger.errorText, contains('Error: User "jane" not found. Run "adb shell pm list users" to see list of available identifiers.'));
    expect(processManager.hasRemainingExpectations, false);
  });
}

class MockAndroidSdk extends Mock implements AndroidSdk {}
