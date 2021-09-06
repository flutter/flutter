// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter_devicelab/framework/devices.dart';
import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/host_agent.dart';
import 'package:flutter_devicelab/framework/task_result.dart';
import 'package:flutter_devicelab/framework/utils.dart';
import 'package:path/path.dart' as path;

Future<void> main() async {
  deviceOperatingSystem = DeviceOperatingSystem.ios;

  await task(() async {
    final String projectDirectory = '${flutterDirectory.path}/dev/integration_tests/flutter_gallery';

    await inDirectory(projectDirectory, () async {
      section('Build clean');

      await flutter('clean');

      section('Build gallery app');

      await flutter(
        'build',
        options: <String>[
          'ios',
          '-v',
          '--release',
          '--config-only',
        ],
      );
    });

    section('Run platform unit tests');

    final Device device = await devices.workingDevice;
    final Map<String, String> environment = Platform.environment;
    // If not running on CI, inject the Flutter team code signing properties.
    final String developmentTeam = environment['FLUTTER_XCODE_DEVELOPMENT_TEAM'] ?? 'S8QB4VV633';
    final String? codeSignStyle = environment['FLUTTER_XCODE_CODE_SIGN_STYLE'];
    final String? provisioningProfile = environment['FLUTTER_XCODE_PROVISIONING_PROFILE_SPECIFIER'];

    final String resultBundleTemp = Directory.systemTemp.createTempSync('flutter_native_ui_tests_ios32_xcresult.').path;
    final String resultBundlePath = path.join(resultBundleTemp, 'result');
    final int testResultExit = await exec(
      'xcodebuild',
      <String>[
        '-workspace',
        'Runner.xcworkspace',
        '-scheme',
        'Runner',
        '-configuration',
        'Release',
        '-destination',
        'id=${device.deviceId}',
        '-resultBundlePath',
        resultBundlePath,
        'test',
        'COMPILER_INDEX_STORE_ENABLE=NO',
        'DEVELOPMENT_TEAM=$developmentTeam',
        if (codeSignStyle != null)
          'CODE_SIGN_STYLE=$codeSignStyle',
        if (provisioningProfile != null)
          'PROVISIONING_PROFILE_SPECIFIER=$provisioningProfile',
      ],
      workingDirectory: path.join(projectDirectory, 'ios'),
      canFail: true,
    );

    if (testResultExit != 0) {
      final Directory? dumpDirectory = hostAgent.dumpDirectory;
      if (dumpDirectory != null) {
        // Zip the test results to the artifacts directory for upload.
        final String zipPath = path.join(dumpDirectory.path,
            'native_ui_tests_ios32-${DateTime.now().toLocal().toIso8601String()}.zip');
        await exec(
          'zip',
          <String>[
            '-r',
            '-9',
            zipPath,
            'result.xcresult',
          ],
          workingDirectory: resultBundleTemp,
          canFail: true, // Best effort to get the logs.
        );
      }

      return TaskResult.failure('Platform unit tests failed');
    }

    return TaskResult.success(null);
  });
}
