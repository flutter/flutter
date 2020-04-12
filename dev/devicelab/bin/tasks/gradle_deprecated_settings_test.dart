// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/utils.dart';
import 'package:path/path.dart' as path;

/// Tests that apps can be built using the deprecated `android/settings.gradle` file.
/// This test should be removed once apps have been migrated to this new file.
// TODO(egarciad): Migrate existing files, https://github.com/flutter/flutter/issues/54566
Future<void> main() async {
  await task(() async {

    section('Find Java');

    final String javaHome = await findJavaHome();
    if (javaHome == null)
      return TaskResult.failure('Could not find Java');
    print('\nUsing JAVA_HOME=$javaHome');

    final Directory projectDirectory =
        dir('${flutterDirectory.path}/dev/integration_tests/gradle_deprecated_settings');
    try {
      section('Build debug APK using deprecated settings.gradle');
      await inDirectory(projectDirectory, () async {
        await flutter(
          'build',
          options: <String>[
            'apk',
            '--debug',
            '--target-platform', 'android-arm',
            '--no-shrink',
            '--verbose',
          ],
        );
      });
      final File debugApk = File(path.join(
        projectDirectory.path,
        'build',
        'app',
        'outputs',
        'flutter-apk',
        'app-debug.apk',
      ));
      if (!exists(debugApk)) {
        return TaskResult.failure('Failed to build debug APK.');
      }
      return TaskResult.success(null);
    } catch (e) {
      return TaskResult.failure(e.toString());
    }
  });
}
