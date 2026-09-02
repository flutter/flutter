// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/ios.dart';
import 'package:flutter_devicelab/framework/task_result.dart';
import 'package:flutter_devicelab/framework/utils.dart';
import 'package:path/path.dart' as path;

Future<void> main() async {
  await task(() async {
    TaskResult? result;

    await testWithNewIOSSimulator('UniversalLinkTestSim', (String deviceId) async {
      try {
        Future<bool> buildAndTestApp(String projectName) async {
          print('--- Building and testing $projectName ---');
          final String projectDir = path.join(
            flutterDirectory.path,
            'dev',
            'integration_tests',
            projectName,
          );

          await inDirectory(projectDir, () async {
            await flutter('build', options: <String>['ios', '--simulator']);
          });

          // Run XCUITest
          print('Running XCUITest for $projectName...');
          final String iosDir = path.join(projectDir, 'ios');
          final String buildDir = path.join(projectDir, 'build', 'ios');

          final int exitCode = await exec(
            'xcodebuild',
            <String>[
              'test',
              '-workspace',
              'Runner.xcworkspace',
              '-scheme',
              'RunnerUITests',
              '-destination',
              'id=$deviceId',
              'SYMROOT=$buildDir',
            ],
            workingDirectory: iosDir,
            canFail: true,
          );

          if (exitCode != 0) {
            print('XCUITest failed for $projectName with exit code $exitCode');
            return false;
          }

          return true;
        }

        final bool success = await buildAndTestApp('ios_universal_link');
        if (success) {
          result = TaskResult.success(null, benchmarkScoreKeys: <String>[]);
        } else {
          result = TaskResult.failure('ios_universal_link test failed');
        }
      } finally {
        await removeIOSSimulator(deviceId);
      }
    });

    return result ?? TaskResult.failure('Test failed to set a result');
  });
}
