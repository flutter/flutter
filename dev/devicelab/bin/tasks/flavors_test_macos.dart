// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_devicelab/framework/devices.dart';
import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/task_result.dart';
import 'package:flutter_devicelab/framework/utils.dart';
import 'package:flutter_devicelab/tasks/integration_tests.dart';

Future<void> main() async {
  deviceOperatingSystem = DeviceOperatingSystem.macos;
  await task(() async {
    await createFlavorsTest().call();
    await createIntegrationTestFlavorsTest().call();

    final TaskResult installTestsResult = await inDirectory(
      '${flutterDirectory.path}/dev/integration_tests/flavors',
      () async {
        await flutter(
          'install',
          options: <String>['--flavor', 'paid', '-d', 'macos'],
        );
        await flutter(
          'install',
          options: <String>['--flavor', 'paid', '--uninstall-only', '-d', 'macos'],
        );
        final StringBuffer stderr = StringBuffer();
        await evalFlutter(
          'build',
          canFail: true,
          stderr: stderr,
          options: <String>['macos', '--flavor', 'bogus'],
        );

        final String stderrString = stderr.toString();
        print(stderrString);
        if (!stderrString.contains('The Xcode project defines schemes:')) {
          print(stderrString);
          return TaskResult.failure('Should not succeed with bogus flavor');
        }

        return TaskResult.success(null);
      },
    );

    return installTestsResult;
  });
}
