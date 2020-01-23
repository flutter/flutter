// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/utils.dart';
import 'package:path/path.dart' as path;

/// Tests that flutter build apk uses R8 by default by adding an
/// invalid ProGuard rule and evaluating the error message.
Future<void> main() async {
  await task(() async {

    section('Find Java');

    final String javaHome = await findJavaHome();
    if (javaHome == null)
      return TaskResult.failure('Could not find Java');
    print('\nUsing JAVA_HOME=$javaHome');

    section('Create Flutter app project');

    final Directory tempDir = Directory.systemTemp.createTempSync('flutter_module_test.');
    final Directory projectDir = Directory(path.join(tempDir.path, 'hello'));
    try {
      await inDirectory(tempDir, () async {
        await flutter(
          'create',
          options: <String>[
            '--org', 'io.flutter.devicelab',
            'hello',
          ],
        );
      });

      section('Add incorrect proguard rules');

      final File proguardRules = File(path.join(
        projectDir.path,
        'android',
        'app',
        'proguard-rules.pro',
      ));
      proguardRules.writeAsStringSync('invalidRule', flush: true);

      section('Build release APK');

      final StringBuffer stderr = StringBuffer();

      await inDirectory(projectDir, () async {
        await evalFlutter(
          'build',
          options: <String>[
            'apk',
            '--target-platform', 'android-arm',
            '--verbose',
          ],
          canFail: true,
          stderr: stderr,
        );
      });

      if (!stderr.toString().contains('com.android.tools.r8.CompilationFailedException')) {
        return TaskResult.failure('Expected com.android.tools.r8.CompilationFailedException in stderr.');
      }

      return TaskResult.success(null);
    } catch (e) {
      return TaskResult.failure(e.toString());
    } finally {
      rmTree(tempDir);
    }
  });
}
