// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/android_device.dart';
import 'package:flutter_tools/src/android/android_sdk.dart';
import 'package:flutter_tools/src/application_package.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:process/process.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';
import '../../src/fake_process_manager.dart';

void main() {
  testWithoutContext('stopApp times out and does not hang forever', () {
    fakeAsync((FakeAsync async) {
      final Completer<void> completer = Completer<void>();
      final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
        FakeCommand(
          command: const <String>[
            'adb',
            '-s',
            '1234',
            'shell',
            'am',
            'force-stop',
            'com.example.test',
          ],
          completer: completer,
        ),
      ]);

      final AndroidDevice device = setUpAndroidDevice(processManager: processManager);
      final FakeApplicationPackage app = FakeApplicationPackage();

      bool? stopAppResult;
      device.stopApp(app).then((bool result) {
        stopAppResult = result;
      });

      // Flush microtasks to allow the process to start.
      async.flushMicrotasks();
      expect(stopAppResult, isNull);

      // Elapse 40 seconds (longer than a 30s timeout, or just any timeout).
      async.elapse(const Duration(seconds: 40));

      // Currently, stopApp has no timeout, so it should still be running/null.
      // Once we implement a timeout (e.g. 30s), it should complete with false.
      expect(stopAppResult, isFalse);
    });
  });

  testWithoutContext('uninstallApp times out and does not hang forever', () {
    fakeAsync((FakeAsync async) {
      final Completer<void> completer = Completer<void>();
      final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
        // During _checkForSupportedAdbVersion:
        const FakeCommand(
          command: <String>['adb', 'version'],
          stdout: 'Android Debug Bridge version 1.0.41',
        ),
        // During _checkForSupportedAndroidVersion:
        const FakeCommand(command: <String>['adb', 'start-server']),
        // During _properties initialization (triggered by gradle_utils.minSdkVersion check or sdkVersion check):
        const FakeCommand(
          command: <String>['adb', '-s', '1234', 'shell', 'getprop'],
          stdout: '[ro.build.version.sdk]: [30]',
        ),
        // During uninstallApp:
        FakeCommand(
          command: const <String>['adb', '-s', '1234', 'uninstall', 'com.example.test'],
          completer: completer,
        ),
      ]);

      final AndroidDevice device = setUpAndroidDevice(processManager: processManager);
      final FakeApplicationPackage app = FakeApplicationPackage();

      bool? uninstallResult;
      device.uninstallApp(app).then((bool result) {
        uninstallResult = result;
      });

      // Flush microtasks to allow the process to start.
      async.flushMicrotasks();
      expect(uninstallResult, isNull);

      // Elapse 40 seconds.
      async.elapse(const Duration(seconds: 40));

      // Currently, uninstallApp has no timeout, so it should still be running/null.
      // Once we implement a timeout (e.g. 30s), it should complete with false.
      expect(uninstallResult, isFalse);
    });
  });
}

AndroidDevice setUpAndroidDevice({required ProcessManager processManager}) {
  return AndroidDevice(
    '1234',
    modelID: 'TestModel',
    logger: BufferLogger.test(),
    platform: FakePlatform(),
    androidSdk: FakeAndroidSdk(),
    fileSystem: MemoryFileSystem.test(),
    processManager: processManager,
    androidConsoleSocketFactory: (String host, int port) async => throw UnimplementedError(),
  );
}

class FakeAndroidSdk extends Fake implements AndroidSdk {
  @override
  String get adbPath => 'adb';
}

class FakeApplicationPackage extends Fake implements ApplicationPackage {
  @override
  String get id => 'com.example.test';
  @override
  String get name => 'FakeApp';
}
