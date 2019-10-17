// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/utils.dart';
import 'package:path/path.dart' as path;

/// Tests that the Flutter plugin template works. Use `pod lib lint`
/// to confirm the plugin module can be imported into an app.
Future<void> main() async {
  await task(() async {
    section('Create Objective-C iOS plugin');

    final Directory tempDir = Directory.systemTemp.createTempSync('flutter_plugin_test.');
    try {
      const String objcPluginName = 'test_plugin_objc';
      await inDirectory(tempDir, () async {
        await flutter(
          'create',
          options: <String>[
            '--org',
            'io.flutter.devicelab',
            '--template=plugin',
            '--ios-language=objc',
            objcPluginName,
          ],
        );
      });

      final String objcPodspecPath = path.join(tempDir.path, objcPluginName, 'ios', '$objcPluginName.podspec');
      section('Lint Objective-C iOS plugin as framework');
      await inDirectory(tempDir, () async {
        await exec(
          'pod',
          <String>[
            'lib',
            'lint',
            objcPodspecPath,
            '--allow-warnings',
          ],
        );
      });

      section('Lint Objective-C iOS plugin as library');
      await inDirectory(tempDir, () async {
        await exec(
          'pod',
          <String>[
            'lib',
            'lint',
            objcPodspecPath,
            '--allow-warnings',
            '--use-libraries',
          ],
        );
      });

      return TaskResult.success(null);
    } catch (e) {
      return TaskResult.failure(e.toString());
    } finally {
      rmTree(tempDir);
    }
  });
}
