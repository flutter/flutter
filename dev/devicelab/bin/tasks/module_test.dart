// Copyright (c) 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/utils.dart';
import 'package:path/path.dart' as path;

/// Tests that the Flutter module project template works and supports
/// adding Flutter to an existing Android app.
Future<Null> main() async {
  await task(() async {

    section('Find Java');

    final String javaHome = await findJavaHome();
    if (javaHome == null)
      return TaskResult.failure('Could not find Java');
    print('\nUsing JAVA_HOME=$javaHome');

    section('Create Flutter module project');

    final Directory tempDir = Directory.systemTemp.createTempSync('flutter_module_test.');
    try {
      await inDirectory(tempDir, () async {
        await flutter(
          'create',
          options: <String>['--org', 'io.flutter.devicelab', '-t', 'module', 'hello'],
        );
      });

      section('Add plugins');

      final File pubspec = File(path.join(tempDir.path, 'hello', 'pubspec.yaml'));
      String content = await pubspec.readAsString();
      content = content.replaceFirst(
        '\ndependencies:\n',
        '\ndependencies:\n  battery:\n  package_info:\n',
      );
      await pubspec.writeAsString(content, flush: true);
      await inDirectory(Directory(path.join(tempDir.path, 'hello')), () async {
        await flutter(
          'packages',
          options: <String>['get'],
        );
      });

      section('Build Flutter module library archive');

      await inDirectory(Directory(path.join(tempDir.path, 'hello', '.android')), () async {
        await exec(
          './gradlew',
          <String>['flutter:assembleDebug'],
          environment: <String, String>{ 'JAVA_HOME': javaHome },
        );
      });

      final bool aarBuilt = exists(File(path.join(
        tempDir.path,
        'hello',
        '.android',
        'Flutter',
        'build',
        'outputs',
        'aar',
        'flutter-debug.aar',
      )));

      if (!aarBuilt) {
        return TaskResult.failure('Failed to build .aar');
      }

      section('Build ephemeral host app');

      await inDirectory(Directory(path.join(tempDir.path, 'hello')), () async {
        await flutter(
          'build',
          options: <String>['apk'],
        );
      });

      final bool ephemeralHostApkBuilt = exists(File(path.join(
        tempDir.path,
        'hello',
        'build',
        'host',
        'outputs',
        'apk',
        'release',
        'app-release.apk',
      )));

      if (!ephemeralHostApkBuilt) {
        return TaskResult.failure('Failed to build ephemeral host .apk');
      }

      section('Clean build');

      await inDirectory(Directory(path.join(tempDir.path, 'hello')), () async {
        await flutter('clean');
      });

      section('Materialize host app');

      await inDirectory(Directory(path.join(tempDir.path, 'hello')), () async {
        await flutter(
          'materialize',
          options: <String>['android'],
        );
      });

      section('Build materialized host app');

      await inDirectory(Directory(path.join(tempDir.path, 'hello')), () async {
        await flutter(
          'build',
          options: <String>['apk'],
        );
      });

      final bool materializedHostApkBuilt = exists(File(path.join(
        tempDir.path,
        'hello',
        'build',
        'host',
        'outputs',
        'apk',
        'release',
        'app-release.apk',
      )));

      if (!materializedHostApkBuilt) {
        return TaskResult.failure('Failed to build materialized host .apk');
      }

      section('Add to Android app');

      final Directory hostApp = Directory(path.join(tempDir.path, 'hello_host_app'));
      mkdir(hostApp);
      recursiveCopy(
        Directory(path.join(flutterDirectory.path, 'dev', 'integration_tests', 'android_host_app')),
        hostApp,
      );
      copy(
        File(path.join(tempDir.path, 'hello', '.android', 'gradlew')),
        hostApp,
      );
      copy(
        File(path.join(tempDir.path, 'hello', '.android', 'gradle', 'wrapper', 'gradle-wrapper.jar')),
        Directory(path.join(hostApp.path, 'gradle', 'wrapper')),
      );

      await inDirectory(hostApp, () async {
        await exec('chmod', <String>['+x', 'gradlew']);
        await exec('./gradlew',
          <String>['app:assembleDebug'],
          environment: <String, String>{ 'JAVA_HOME': javaHome },
        );
      });

      final bool existingAppBuilt = exists(File(path.join(
        hostApp.path,
        'app',
        'build',
        'outputs',
        'apk',
        'debug',
        'app-debug.apk',
      )));

      if (!existingAppBuilt) {
        return TaskResult.failure('Failed to build existing app .apk');
      }
      return TaskResult.success(null);
    } catch (e) {
      return TaskResult.failure(e.toString());
    } finally {
      rmTree(tempDir);
    }
  });
}
