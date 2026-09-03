// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/android_device.dart';
import 'package:flutter_tools/src/android/android_sdk.dart';
import 'package:flutter_tools/src/android/application_package.dart';
import 'package:flutter_tools/src/android/gradle_utils.dart' as gradle_utils;
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';
import '../../src/fake_process_manager.dart';

const kAdbVersionCommand = FakeCommand(
  command: <String>['adb', 'version'],
  stdout: 'Android Debug Bridge version 1.0.39',
);

const kAdbStartServerCommand = FakeCommand(command: <String>['adb', 'start-server']);

void main() {
  late FileSystem fileSystem;
  late BufferLogger logger;

  setUp(() {
    fileSystem = MemoryFileSystem.test();
    logger = BufferLogger.test();
  });

  AndroidDevice setUpAndroidDevice({AndroidSdk? androidSdk, ProcessManager? processManager}) {
    androidSdk ??= FakeAndroidSdk();
    return AndroidDevice(
      '1234',
      modelID: 'TestModel',
      logger: logger,
      platform: FakePlatform(),
      androidSdk: androidSdk,
      fileSystem: fileSystem,
      processManager: processManager ?? FakeProcessManager.any(),
    );
  }

  testWithoutContext('isLatestBuildInstalled checks SHA hash in app-specific storage', () async {
    final processManager = FakeProcessManager.list(<FakeCommand>[
      const FakeCommand(
        command: <String>['adb', '-s', '1234', 'shell', 'cat', '/sdcard/Android/data/app/sky.sha1'],
        stdout: 'example_sha',
      ),
    ]);

    final File apk = fileSystem.file('app-debug.apk')..createSync();
    // Create source sha1 file
    fileSystem.file('app-debug.apk.sha1').writeAsStringSync('example_sha');

    final androidApk = AndroidApk(
      applicationPackage: apk,
      id: 'app',
      versionCode: 22,
      launchActivity: 'Main',
    );
    final AndroidDevice androidDevice = setUpAndroidDevice(processManager: processManager);

    expect(await androidDevice.isLatestBuildInstalled(androidApk), isTrue);
    expect(processManager, hasNoRemainingExpectations);
  });

  testWithoutContext(
    'isLatestBuildInstalled checks SHA hash in correct user-specific storage when userIdentifier is provided',
    () async {
      final processManager = FakeProcessManager.list(<FakeCommand>[
        const FakeCommand(
          command: <String>[
            'adb',
            '-s',
            '1234',
            'shell',
            'cat',
            '/storage/emulated/10/Android/data/app/sky.sha1',
          ],
          stdout: 'example_sha',
        ),
      ]);

      final File apk = fileSystem.file('app-debug.apk')..createSync();
      // Create source sha1 file
      fileSystem.file('app-debug.apk.sha1').writeAsStringSync('example_sha');

      final androidApk = AndroidApk(
        applicationPackage: apk,
        id: 'app',
        versionCode: 22,
        launchActivity: 'Main',
      );
      final AndroidDevice androidDevice = setUpAndroidDevice(processManager: processManager);

      expect(await androidDevice.isLatestBuildInstalled(androidApk, userIdentifier: '10'), isTrue);
      expect(processManager, hasNoRemainingExpectations);
    },
  );

  testWithoutContext(
    'installApp writes SHA hash to app-specific storage after creating directory',
    () async {
      final processManager = FakeProcessManager.list(<FakeCommand>[
        kAdbVersionCommand,
        kAdbStartServerCommand,
        const FakeCommand(
          command: <String>['adb', '-s', '1234', 'shell', 'getprop'],
          stdout: '[ro.build.version.sdk]: [${gradle_utils.targetSdkVersion}]',
        ),
        // adb install command
        const FakeCommand(
          command: <String>['adb', '-s', '1234', 'install', '-t', '-r', 'app-debug.apk'],
        ),
        // mkdir command for app-specific storage
        const FakeCommand(
          command: <String>[
            'adb',
            '-s',
            '1234',
            'shell',
            'mkdir',
            '-p',
            '/sdcard/Android/data/app',
          ],
        ),
        // echo/store SHA command
        const FakeCommand(
          command: <String>[
            'adb',
            '-s',
            '1234',
            'shell',
            'echo',
            '-n',
            'example_sha',
            '>',
            '/sdcard/Android/data/app/sky.sha1',
          ],
        ),
      ]);

      final File apk = fileSystem.file('app-debug.apk')..createSync();
      // Create source sha1 file
      fileSystem.file('app-debug.apk.sha1').writeAsStringSync('example_sha');

      final androidApk = AndroidApk(
        applicationPackage: apk,
        id: 'app',
        versionCode: 22,
        launchActivity: 'Main',
      );
      final AndroidDevice androidDevice = setUpAndroidDevice(processManager: processManager);

      expect(await androidDevice.installApp(androidApk), isTrue);
      expect(processManager, hasNoRemainingExpectations);
    },
  );

  testWithoutContext(
    'installApp writes SHA hash to correct user-specific storage when userIdentifier is provided',
    () async {
      final processManager = FakeProcessManager.list(<FakeCommand>[
        kAdbVersionCommand,
        kAdbStartServerCommand,
        const FakeCommand(
          command: <String>['adb', '-s', '1234', 'shell', 'getprop'],
          stdout: '[ro.build.version.sdk]: [${gradle_utils.targetSdkVersion}]',
        ),
        // adb install command with user
        const FakeCommand(
          command: <String>[
            'adb',
            '-s',
            '1234',
            'install',
            '-t',
            '-r',
            '--user',
            '10',
            'app-debug.apk',
          ],
        ),
        // mkdir command for user 10 app-specific storage
        const FakeCommand(
          command: <String>[
            'adb',
            '-s',
            '1234',
            'shell',
            'mkdir',
            '-p',
            '/storage/emulated/10/Android/data/app',
          ],
        ),
        // echo/store SHA command
        const FakeCommand(
          command: <String>[
            'adb',
            '-s',
            '1234',
            'shell',
            'echo',
            '-n',
            'example_sha',
            '>',
            '/storage/emulated/10/Android/data/app/sky.sha1',
          ],
        ),
      ]);

      final File apk = fileSystem.file('app-debug.apk')..createSync();
      fileSystem.file('app-debug.apk.sha1').writeAsStringSync('example_sha');

      final androidApk = AndroidApk(
        applicationPackage: apk,
        id: 'app',
        versionCode: 22,
        launchActivity: 'Main',
      );
      final AndroidDevice androidDevice = setUpAndroidDevice(processManager: processManager);

      expect(await androidDevice.installApp(androidApk, userIdentifier: '10'), isTrue);
      expect(processManager, hasNoRemainingExpectations);
    },
  );

  testWithoutContext(
    'installApp still succeeds and logs warning if writing SHA hash fails',
    () async {
      final processManager = FakeProcessManager.list(<FakeCommand>[
        kAdbVersionCommand,
        kAdbStartServerCommand,
        const FakeCommand(
          command: <String>['adb', '-s', '1234', 'shell', 'getprop'],
          stdout: '[ro.build.version.sdk]: [${gradle_utils.targetSdkVersion}]',
        ),
        const FakeCommand(
          command: <String>['adb', '-s', '1234', 'install', '-t', '-r', 'app-debug.apk'],
        ),
        const FakeCommand(
          command: <String>[
            'adb',
            '-s',
            '1234',
            'shell',
            'mkdir',
            '-p',
            '/sdcard/Android/data/app',
          ],
        ),
        const FakeCommand(
          command: <String>[
            'adb',
            '-s',
            '1234',
            'shell',
            'echo',
            '-n',
            'example_sha',
            '>',
            '/sdcard/Android/data/app/sky.sha1',
          ],
          exitCode: 1,
        ),
      ]);

      final File apk = fileSystem.file('app-debug.apk')..createSync();
      fileSystem.file('app-debug.apk.sha1').writeAsStringSync('example_sha');

      final androidApk = AndroidApk(
        applicationPackage: apk,
        id: 'app',
        versionCode: 22,
        launchActivity: 'Main',
      );
      final AndroidDevice androidDevice = setUpAndroidDevice(processManager: processManager);

      expect(await androidDevice.installApp(androidApk), isTrue);
      expect(logger.errorText, contains('adb shell failed to write the SHA hash'));
      expect(processManager, hasNoRemainingExpectations);
    },
  );
}

class FakeAndroidSdk extends Fake implements AndroidSdk {
  @override
  String get adbPath => 'adb';
}
