// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:collection/collection.dart';
import 'package:flutter_devicelab/framework/devices.dart';
import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/task_result.dart';
import 'package:flutter_devicelab/framework/utils.dart';
import 'package:flutter_devicelab/tasks/integration_tests.dart';
import 'package:path/path.dart' as path;

Future<void> main() async {
  deviceOperatingSystem = DeviceOperatingSystem.android;
  await task(() async {
    await createFlavorsTest().call();
    await createIntegrationTestFlavorsTest().call();

    final TaskResult installTestsResult = await inDirectory(
      '${flutterDirectory.path}/dev/integration_tests/flavors',
      () async {
        final List<TaskResult> testResults = <TaskResult>[
          await _testInstallDebugPaidFlavor(),
          await _testInstallBogusFlavor(),
        ];

        final TaskResult? firstInstallFailure = testResults
          .firstWhereOrNull((TaskResult element) => element.failed);

        if (firstInstallFailure != null) {
          return firstInstallFailure;
        }

        return TaskResult.success(null);
      },
    );

    return installTestsResult;
  });
}

// Ensures installation works. Also tests asset bundling while we are at it.
Future<TaskResult> _testInstallDebugPaidFlavor() async {
  final String installPaidFlavorStdout = await evalFlutter(
    'install',
    options: <String>['--debug', '--flavor', 'paid'],
  );

  if (!installPaidFlavorStdout.contains('Skipping assets entry "assets/free/" '
    'since its configured flavor, "free" did not match provided flavor')) {
    return TaskResult.failure('Assets declared with a flavor not equal to the '
      'argued --flavor value should not be bundled.');
  }

  await flutter(
    'install',
    options: <String>['--debug', '--flavor', 'paid', '--uninstall-only'],
  );

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
  final String expectedApkPath = path.join('build', 'app', 'outputs', 'flutter-apk', 'app-bogus-release.apk');
  if (!stderrString.contains('"$expectedApkPath" does not exist.')) {
    print(stderrString);
    return TaskResult.failure('Should not succeed with bogus flavor');
  }

  return TaskResult.success(null);
}
