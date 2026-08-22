// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/android_device.dart';
import 'package:flutter_tools/src/android/android_sdk.dart';
import 'package:flutter_tools/src/android/application_package.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';
import '../../src/fake_process_manager.dart';

const kAdbVersionCommand = FakeCommand(
  command: <String>['adb', 'version'],
  stdout: 'Android Debug Bridge version 1.0.39',
);

const kStartServer = FakeCommand(command: <String>['adb', 'start-server']);

void main() {
  late FileSystem fileSystem;
  late FakeProcessManager processManager;
  late AndroidSdk androidSdk;

  setUp(() {
    processManager = FakeProcessManager.empty();
    fileSystem = MemoryFileSystem.test();
    androidSdk = FakeAndroidSdk();
  });

  testWithoutContext(
    'AndroidDevice.startApp launches by Intent using package name only (no specific activity)',
    () async {
      final device = AndroidDevice(
        '1234',
        modelID: 'TestModel',
        fileSystem: fileSystem,
        processManager: processManager,
        logger: BufferLogger.test(),
        platform: FakePlatform(),
        androidSdk: androidSdk,
      );
      final File apkFile = fileSystem.file('app-release.apk')..createSync();
      final apk = AndroidApk(
        id: 'io.flutter.examples.hello_world',
        applicationPackage: apkFile,
        launchActivity:
            'io.flutter.examples.hello_world/io.flutter.examples.hello_world.MainActivity',
        versionCode: 1,
      );

      processManager.addCommand(kAdbVersionCommand);
      processManager.addCommand(kStartServer);

      // This configures the target platform of the device.
      processManager.addCommand(
        const FakeCommand(
          command: <String>['adb', '-s', '1234', 'shell', 'getprop'],
          stdout: '[ro.product.cpu.abi]: [arm64-v8a]',
        ),
      );
      processManager.addCommand(
        const FakeCommand(
          command: <String>[
            'adb',
            '-s',
            '1234',
            'shell',
            'am',
            'force-stop',
            'io.flutter.examples.hello_world',
          ],
        ),
      );
      processManager.addCommand(
        const FakeCommand(
          command: <String>['adb', '-s', '1234', 'install', '-t', '-r', 'app-release.apk'],
        ),
      );
      processManager.addCommand(
        const FakeCommand(
          command: <String>[
            'adb',
            '-s',
            '1234',
            'shell',
            'echo',
            '-n',
            '',
            '>',
            '/data/local/tmp/sky.io.flutter.examples.hello_world.sha1',
          ],
        ),
      );

      // The expectation: Launching by intent using the package name (with `-p`) rather than specific activity.
      processManager.addCommand(
        const FakeCommand(
          command: <String>[
            'adb',
            '-s',
            '1234',
            'shell',
            'am',
            'start',
            '-a',
            'android.intent.action.MAIN',
            '-c',
            'android.intent.category.LAUNCHER',
            '-f',
            '0x20000000',
            '-p',
            'io.flutter.examples.hello_world',
          ],
        ),
      );

      final LaunchResult launchResult = await device.startApp(
        apk,
        prebuiltApplication: true,
        debuggingOptions: DebuggingOptions.disabled(BuildInfo.release, enableDartProfiling: false),
        platformArgs: <String, dynamic>{},
      );

      expect(launchResult.started, true);
      expect(processManager, hasNoRemainingExpectations);
    },
  );
}

class FakeAndroidSdk extends Fake implements AndroidSdk {
  @override
  String get adbPath => 'adb';

  @override
  bool get licensesAvailable => false;

  @override
  AndroidSdkVersion? get latestVersion => null;
}
