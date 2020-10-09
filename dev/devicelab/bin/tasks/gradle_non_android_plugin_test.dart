// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/task_result.dart';
import 'package:flutter_devicelab/framework/utils.dart';
import 'package:path/path.dart' as path;

/// Tests that a flutter app that depends on a non-Android plugin
/// (an iOS only plugin in this case) can still build for Android.
Future<void> main() async {
  await task(() async {

    section('Find Java');

    final String javaHome = await findJavaHome();
    if (javaHome == null)
      return TaskResult.failure('Could not find Java');
    print('\nUsing JAVA_HOME=$javaHome');

    section('Create Flutter plugin project');

    final Directory tempDir = Directory.systemTemp.createTempSync('flutter_plugin_test.');
    final Directory projectDir = Directory(path.join(tempDir.path, 'ios_only'));
    try {
      await inDirectory(tempDir, () async {
        await flutter(
          'create',
          options: <String>[
            '--org', 'io.flutter.devicelab',
            '-t', 'plugin',
            '--platforms=ios,android',
            'ios_only',
          ],
        );
      });

      section("Delete plugin's Android folder");

      final File androidFolder = File(path.join(
        projectDir.path,
        'android',
      ));
      androidFolder.deleteSync(recursive: true);

      section('Update pubspec.yaml to iOS only plugin');
      final File pubspecFile = File(path.join(projectDir.path, 'pubspec.yaml'));
      final String pubspecString = pubspecFile.readAsStringSync();

      final StringBuffer iosOnlyPubspec = StringBuffer();
      bool inAndroidSection = false;
      const String pluginPlatformIndentation = '      ';
      for (final String line in pubspecString.split('\n')) {
        // Skip everything in the Android section of the plugin platforms list.
        if (line.startsWith('${pluginPlatformIndentation}android:')) {
          inAndroidSection = true;
          continue;
        }
        if (inAndroidSection) {
          if (line.startsWith('$pluginPlatformIndentation  ')) {
            continue;
          } else {
            inAndroidSection = false;
          }
        }
        iosOnlyPubspec.write('$line\n');
      }

      pubspecFile.writeAsStringSync(iosOnlyPubspec.toString());

      section('Build example APK');

      final StringBuffer stderr = StringBuffer();

      final Directory exampleDir = Directory(path.join(projectDir.path, 'example'));
      await inDirectory(exampleDir, () async {
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

      section('Check that the example APK was built');

      final String exampleAppApk = path.join(
        exampleDir.path,
        'build',
        'app',
        'outputs',
        'apk',
        'release',
        'app-release.apk',
      );
      if (!exists(File(exampleAppApk))) {
        return TaskResult.failure('Failed to build example app');
      }
      return TaskResult.success(null);
    } catch (e) {
      return TaskResult.failure(e.toString());
    } finally {
      rmTree(tempDir);
    }
  });
}
