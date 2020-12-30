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

    final Directory tempDir =
        Directory.systemTemp.createTempSync('flutter_plugin_test.');
    final Directory projectDir =
        Directory(path.join(tempDir.path, 'plugin_test'));
    try {
      await inDirectory(tempDir, () async {
        await flutter(
          'create',
          options: <String>[
            '--template=plugin',
            '--platforms=android',
            'plugin_test',
          ],
        );
      });

      final Directory exampleAppDir =
          Directory(path.join(projectDir.path, 'example'));
      if (!exists(exampleAppDir)) {
        return TaskResult.failure('Example app directory doesn\'t exist');
      }

      final File buildGradleFile =
          File(path.join(exampleAppDir.path, 'android', 'build.gradle'));

      if (!exists(buildGradleFile)) {
        return TaskResult.failure('$buildGradleFile doesn\'t exist');
      }

      final String buildGradle = buildGradleFile.readAsStringSync();
      final RegExp androidPluginRegExp =
          RegExp(r'com\.android\.tools\.build:gradle:(\d+\.\d+\.\d+)');

      section('Use AGP 4.1.0');

      String newBuildGradle = buildGradle.replaceAll(
          androidPluginRegExp, 'com.android.tools.build:gradle:4.1.0');
      print(newBuildGradle);
      buildGradleFile.writeAsString(newBuildGradle);

      section('Run flutter build apk using AGP 4.1.0');

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

      section('Clean');

      await inDirectory(exampleAppDir, () async {
        await flutter('clean');
      });

      section('Remove Gradle wrapper');

      Directory(path.join(exampleAppDir.path, 'android', 'gradle', 'wrapper'))
          .deleteSync(recursive: true);

      section('Use AGP 3.3.0');

      newBuildGradle = buildGradle.replaceAll(
          androidPluginRegExp, 'com.android.tools.build:gradle:3.3.0');
      print(newBuildGradle);
      buildGradleFile.writeAsString(newBuildGradle);

      section('Enable R8 in gradle.properties');

      final File gradleProperties =
          File(path.join(exampleAppDir.path, 'android', 'gradle.properties'));

      if (!exists(gradleProperties)) {
        return TaskResult.failure('$gradleProperties doesn\'t exist');
      }

      gradleProperties.writeAsString('''
org.gradle.jvmargs=-Xmx1536M
android.useAndroidX=true
android.enableJetifier=true
android.enableR8=true''');

      section('Run flutter build apk using AGP 3.3.0');

      await inDirectory(exampleAppDir, () async {
        await flutter(
          'build',
          options: <String>[
            'apk',
            '--target-platform=android-arm',
          ],
        );
      });

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
