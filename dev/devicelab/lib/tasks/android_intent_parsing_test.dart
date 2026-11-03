// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:path/path.dart' as path;

import '../framework/devices.dart';
import '../framework/framework.dart';
import '../framework/task_result.dart';
import '../framework/utils.dart';

TaskFunction createAndroidIntentParsingTest() {
  return () async {
    final device = await devices.workingDevice as AndroidDevice;
    await device.unlock();
    final String testDirectory = path.join(flutterDirectory.path, 'dev', 'integration_tests', 'ui');

    const testPackageName = 'com.yourcompany.integration_ui';
    const mainActivityName = '$testPackageName/.MainActivity';

    Future<void> testMode({required String mode, required bool expectVerbose}) async {
      section('--- Testing $mode mode ---');
      await inDirectory<void>(testDirectory, () async {
        await flutter('build', options: <String>['apk', '--$mode']);
        final String apkPath = path.join('build', 'app', 'outputs', 'flutter-apk', 'app-$mode.apk');

        // Ensure clean state
        await device.adb(<String>['uninstall', testPackageName], canFail: true);
        await device.adb(<String>['install', '-r', apkPath]);
        await device.adb(<String>['logcat', '-c']);

        await device.shellExec('am', <String>[
          'start',
          '-W',
          '-n',
          mainActivityName,
          '-a',
          'android.intent.action.RUN',
          '--ez',
          'verbose-logging',
          'true',
        ]);

        // The app is fully launched. Give logcat a tiny buffer to flush.
        await Future<void>.delayed(const Duration(seconds: 1));

        section('--- Check logcat for verbose logs in $mode ---');
        final String logcat = await device.adb(<String>['logcat', '-d']);
        final bool foundInfoLog = logcat.contains('[INFO:flutter');

        if (expectVerbose && !foundInfoLog) {
          throw TaskResult.failure(
            'Expected [INFO:] logs to be present in $mode mode when passing verbose-logging intent, but they were not found in logcat.',
          );
        } else if (!expectVerbose && foundInfoLog) {
          throw TaskResult.failure(
            'Expected [INFO:] logs to be stripped in $mode mode, but they were found in logcat!',
          );
        }

        if (!expectVerbose) {
          const expectedWarning =
              'Setting engine flags via Intent is not supported in release mode and will be ignored.';
          if (!logcat.contains(expectedWarning)) {
            throw TaskResult.failure(
              'Expected warning "$expectedWarning" to be present in $mode mode logcat, but it was not found.',
            );
          }
        }

        print(
          'Success: $mode mode behaves as expected (expectVerbose: $expectVerbose, foundInfoLog: $foundInfoLog)',
        );
      });
    }

    await testMode(mode: 'debug', expectVerbose: true);
    await testMode(mode: 'profile', expectVerbose: true);
    await testMode(mode: 'release', expectVerbose: false);

    return TaskResult.success(null);
  };
}
