// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:flutter_devicelab/framework/devices.dart';
import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/task_result.dart';
import 'package:flutter_devicelab/framework/utils.dart';
import 'package:flutter_devicelab/tasks/integration_tests.dart';
import 'package:path/path.dart' as path;
import 'package:standard_message_codec/standard_message_codec.dart';

Future<void> main() async {
  deviceOperatingSystem = DeviceOperatingSystem.ios;
  await task(() async {
    await createFlavorsTest().call();
    await createIntegrationTestFlavorsTest().call();
    // test install and uninstall of flavors app
    final String projectDir = '${flutterDirectory.path}/dev/integration_tests/flavors';
    final TaskResult installTestsResult = await inDirectory(projectDir, () async {
      final List<TaskResult> testResults = <TaskResult>[
        await _testInstallDebugPaidFlavor(projectDir),
        await _testInstallBogusFlavor(),
        await _testFlavorsWhenBuildStartsWithXcode(projectDir),
      ];

      final TaskResult? firstInstallFailure = testResults.firstWhereOrNull(
        (TaskResult element) => element.failed,
      );

      return firstInstallFailure ?? TaskResult.success(null);
    });

    return installTestsResult;
  });
}

Future<TaskResult> _testInstallDebugPaidFlavor(String projectDir) async {
  await evalFlutter('install', options: <String>['--flavor', 'paid']);
  final Uint8List assetManifestFileData =
      File(
        path.join(
          projectDir,
          'build',
          'ios',
          'iphoneos',
          'Paid App.app',
          'Frameworks',
          'App.framework',
          'flutter_assets',
          'AssetManifest.bin',
        ),
      ).readAsBytesSync();

  final Map<Object?, Object?> assetManifest =
      const StandardMessageCodec().decodeMessage(ByteData.sublistView(assetManifestFileData))
          as Map<Object?, Object?>;

  if (assetManifest.containsKey('assets/free/free.txt')) {
    return TaskResult.failure(
      'Expected the asset "assets/free/free.txt", which '
      ' was declared with a flavor of "free" to not be included in the asset bundle '
      ' because the --flavor was set to "paid".',
    );
  }

  if (!assetManifest.containsKey('assets/paid/paid.txt')) {
    return TaskResult.failure(
      'Expected the asset "assets/paid/paid.txt", which '
      ' was declared with a flavor of "paid" to be included in the asset bundle '
      ' because the --flavor was set to "paid".',
    );
  }

  await flutter('install', options: <String>['--flavor', 'paid', '--uninstall-only']);

  return TaskResult.success(null);
}

Future<TaskResult> _testInstallBogusFlavor() async {
  final StringBuffer stderr = StringBuffer();
  await evalFlutter(
    'install',
    canFail: true,
    stderr: stderr,
    options: <String>['--flavor', 'bogus'],
  );

  final String stderrString = stderr.toString();
  if (!stderrString.contains('The Xcode project defines schemes: free, paid')) {
    print(stderrString);
    return TaskResult.failure('Should not succeed with bogus flavor');
  }

  return TaskResult.success(null);
}

Future<TaskResult> _testFlavorsWhenBuildStartsWithXcode(String projectDir) async {
  final String iosDirPath = '$projectDir/ios';

  // Prebuild with --config-only to make sure that Cocoapods dependencies are installed.
  await flutter('build', options: <String>['ios', '--config-only', '--flavor', 'paid']);

  await inDirectory(iosDirPath, () async {
    await exec('xcodebuild', <String>[
      'clean',
      'build',
      '-workspace',
      'Runner.xcworkspace',
      '-scheme paid',
      '-derivedDataPath',
      'build',
      '-destination',
      '"generic/platform=iOS Simulator"',
      'CODE_SIGNING_ALLOWED=NO',
      'CODE_SIGNING_REQUIRED=NO',
      'CODE_SIGNING_IDENTITY=""',
    ]);
  });

  final String appPath = '$iosDirPath/build/Build/Products/Debug-Paid-iphonesimulator/Paid App.app';

  // Verify app exists before proceeding
  if (!File(appPath).existsSync()) {
    return TaskResult.failure('Built app not found at expected path: $appPath');
  }

  final Device device = await devices.workingDevice;
  await device.unlock();
  await flutter(
    'drive',
    options: <String>[
      '--use-application-binary="$appPath"',
      '--driver=test_driver/main_test.dart',
      '--device-id',
      device.deviceId,
    ],
  );

  return TaskResult.success(null);
}
