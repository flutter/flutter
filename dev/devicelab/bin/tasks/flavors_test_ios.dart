// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:flutter_devicelab/framework/devices.dart';
import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/ios.dart';
import 'package:flutter_devicelab/framework/task_result.dart';
import 'package:flutter_devicelab/framework/utils.dart';
import 'package:flutter_devicelab/tasks/integration_tests.dart';
import 'package:path/path.dart' as path;
import 'package:standard_message_codec/standard_message_codec.dart';

Future<void> main() async {
  deviceOperatingSystem = DeviceOperatingSystem.ios;
  await task(() async {
    String? simulatorDeviceId;
    var res = TaskResult.success(null);
    try {
      await testWithNewIOSSimulator('flavors_test_ios', (String deviceId) async {
        simulatorDeviceId = deviceId;
        await createFlavorsTest(deviceIdOverride: deviceId).call();
        await createIntegrationTestFlavorsTest(deviceIdOverride: deviceId).call();
        // test install and uninstall of flavors app
        final projectDir = '${flutterDirectory.path}/dev/integration_tests/flavors';
        final TaskResult installTestsResult = await inDirectory(projectDir, () async {
          final testResults = <TaskResult>[
            await _testInstallDebugPaidFlavor(projectDir, deviceId),
            await _testInstallBogusFlavor(deviceId),
          ];

          final TaskResult? firstInstallFailure = testResults.firstWhereOrNull(
            (TaskResult element) => element.failed,
          );

          return firstInstallFailure ?? TaskResult.success(null);
        });

        if (installTestsResult.failed) {
          res = installTestsResult;
          return;
        }

        res = await _testFlavorWhenBuiltFromXcode(projectDir, deviceId);
      });
    } finally {
      await removeIOSSimulator(simulatorDeviceId);
    }
    return res;
  });
}

Future<TaskResult> _testInstallDebugPaidFlavor(String projectDir, String deviceId) async {
  await evalFlutter('install', options: <String>['-d', deviceId, '--flavor', 'paid']);
  final Uint8List assetManifestFileData = File(
    path.join(
      projectDir,
      'build',
      'ios',
      'iphonesimulator',
      'Paid App.app',
      'Frameworks',
      'App.framework',
      'flutter_assets',
      'AssetManifest.bin',
    ),
  ).readAsBytesSync();

  final assetManifest =
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

  await flutter(
    'install',
    options: <String>['-d', deviceId, '--flavor', 'paid', '--uninstall-only'],
  );

  return TaskResult.success(null);
}

Future<TaskResult> _testInstallBogusFlavor(String deviceId) async {
  final stderr = StringBuffer();
  await evalFlutter(
    'install',
    canFail: true,
    stderr: stderr,
    options: <String>['-d', deviceId, '--flavor', 'bogus'],
  );

  final stderrString = stderr.toString();
  if (!stderrString.contains(
    'You must specify a --flavor option to select one of the available schemes.',
  )) {
    print(stderrString);
    return TaskResult.failure('Should not succeed with bogus flavor');
  }

  return TaskResult.success(null);
}

Future<TaskResult> _testFlavorWhenBuiltFromXcode(String projectDir, String deviceId) async {
  await inDirectory(projectDir, () async {
    // This will put FLAVOR=free in the Flutter/Generated.xcconfig file
    await flutter(
      'build',
      options: <String>['ios', '--simulator', '--config-only', '--debug', '--flavor', 'free'],
    );
  });

  final generatedXcconfig = File(path.join(projectDir, 'ios/Flutter/Generated.xcconfig'));
  if (!generatedXcconfig.existsSync()) {
    throw TaskResult.failure('Unable to find Generated.xcconfig');
  }
  if (!generatedXcconfig.readAsStringSync().contains('FLAVOR=free')) {
    throw TaskResult.failure('Generated.xcconfig does not contain FLAVOR=free');
  }

  const configuration = 'Debug Paid';
  const productName = 'Paid App';
  const buildDir = 'build/ios';

  // Delete app bundle before build to ensure checks below do not use previously
  // built bundle.
  final appPath = '$projectDir/$buildDir/$configuration-iphonesimulator/$productName.app';
  final appBundle = Directory(appPath);
  if (appBundle.existsSync()) {
    appBundle.deleteSync(recursive: true);
  }

  if (!await runXcodeBuild(
    platformDirectory: path.join(projectDir, 'ios'),
    destination: 'id=$deviceId',
    testName: 'flavors_test_ios',
    configuration: configuration,
    scheme: 'paid',
    actions: <String>['clean', 'build'],
    extraOptions: <String>['BUILD_DIR=${path.join(projectDir, buildDir)}'],
  )) {
    throw TaskResult.failure('Build failed');
  }

  if (!appBundle.existsSync()) {
    throw TaskResult.failure('App not found at $appPath');
  }

  if (!generatedXcconfig.readAsStringSync().contains('FLAVOR=free')) {
    throw TaskResult.failure('Generated.xcconfig does not contain FLAVOR=free');
  }

  // Despite FLAVOR=free being in the Generated.xcconfig, the flavor found in
  // the test should be "paid" because it was built with the "Debug Paid" configuration.
  return createFlavorsTest(
    deviceIdOverride: deviceId,
    extraOptions: <String>['--flavor', 'paid', '--use-application-binary=$appPath'],
  ).call();
}
