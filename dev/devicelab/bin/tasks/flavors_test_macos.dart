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

    await inDirectory('${flutterDirectory.path}/dev/integration_tests/flavors', () async {
      final StringBuffer stderr = StringBuffer();

      await evalFlutter(
        'install',
        canFail: true,
        stderr: stderr,
        options: <String>[
          '--d', 'macos',
          '--flavor', 'free'
        ],
      );

      final String stderrString = stderr.toString();
      if (!stderrString.contains('Host and target are the same. Nothing to install.')) {
        print(stderrString);
        return TaskResult.failure('Installing a macOS app on macOS should no-op');
      }
    });

    return TaskResult.success(null);
  });
}
