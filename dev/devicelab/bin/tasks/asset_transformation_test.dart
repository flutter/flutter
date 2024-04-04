// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' show File;

import 'package:flutter_devicelab/framework/devices.dart';
import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/task_result.dart';
import 'package:flutter_devicelab/framework/utils.dart';
import 'package:path/path.dart' as path;

Future<void> main() async {
  deviceOperatingSystem = DeviceOperatingSystem.android;
  await task(() async {
    final String projectPath =
        '${flutterDirectory.path}/dev/integration_tests/asset_transformation';
    return inDirectory(projectPath, () async {
      await evalFlutter('build');

      final String assetData = File(
        path.join(projectPath, 'build', 'app', 'intermediates', 'assets',
            'debug', 'flutter_assets', 'assets', 'test_asset.txt'),
      ).readAsStringSync();

      return assetData == 'ABC'
          ? TaskResult.success(null)
          : TaskResult.failure('Expected test_asset.txt contents to be "ABC".');
    });
  });
}
