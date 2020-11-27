// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/task_result.dart';
import 'package:flutter_devicelab/framework/utils.dart';
import 'package:path/path.dart' as path;

final String gradlew = Platform.isWindows ? 'gradlew.bat' : 'gradlew';
final String gradlewExecutable = Platform.isWindows ? '.\\$gradlew' : './$gradlew';

/// Tests that a plugin example app can be built using the current Flutter Gradle plugin.
Future<void> main() async {
  await task(() async {

    section('Find Java');

    final String javaHome = await findJavaHome();
    if (javaHome == null) {
      return TaskResult.failure('Could not find Java');
    }

    print('\nUsing JAVA_HOME=$javaHome');

    section('Create Flutter plugin project');

    await flutter(
      'precache',
      options: <String>['--android', '--no-ios'],
    );

    final Directory tempDir = Directory.systemTemp.createTempSync('flutter_plugin_test.');
    final Directory projectDir = Directory(path.join(tempDir.path, 'plugin_test'));
    try {
      await inDirectory(tempDir, () async {
        await flutter(
          'create',
          options: <String>['--template=plugin', '--platforms=android', 'plugin_test'],
        );
      });

      final Directory exampleAppDir = Directory(path.join(projectDir.path, 'example'));
      if (!exists(exampleAppDir)) {
        return TaskResult.failure('Example app directory doesn\'t exist');
      }

      section('Run flutter build apk');

      await inDirectory(exampleAppDir, () async {
        await flutter(
          'build',
          options: <String>[
            'apk',
            '--target-platform=android-arm',
          ],
        );
      });

      final String exampleApk = path.join(
        exampleAppDir.path,
        'build',
        'app',
        'outputs',
        'flutter-apk',
        'app-release.apk',
      );

      if (!exists(File(exampleApk))) {
        return TaskResult.failure('Failed to build app-release.apk');
      }

      return TaskResult.success(null);
    } on TaskResult catch (taskResult) {
      return taskResult;
    } catch (e) {
      return TaskResult.failure(e.toString());
    } finally {
      rmTree(tempDir);
    }
  });
}
