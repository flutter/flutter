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
      return new TaskResult.failure('Could not find Java');
    print('\nUsing JAVA_HOME=$javaHome');

    section('Create Flutter module project');

    final Directory directory = await Directory.systemTemp.createTemp('module');
    try {
      await inDirectory(directory, () async {
        await flutter(
          'create',
          options: <String>['--org', 'io.flutter.devicelab', '-t', 'module', 'hello'],
        );
      });

      section('Build Android .aar');

      await inDirectory(new Directory(path.join(directory.path, 'hello', '.android')), () async {
        await exec(
          './gradlew',
          <String>['flutter:assembleDebug'],
          environment: <String, String>{ 'JAVA_HOME': javaHome },
        );
      });

      final bool aarBuilt = exists(new File(path.join(
        directory.path,
        'hello',
        '.android',
        'Flutter',
        'build',
        'outputs',
        'aar',
        'flutter-debug.aar',
      )));

      if (!aarBuilt) {
        return new TaskResult.failure('Failed to build .aar');
      }

      section('Add to Android app');

      final Directory hostApp = new Directory(path.join(directory.path, 'hello_host_app'));
      mkdir(hostApp);
      recursiveCopy(
        new Directory(path.join(flutterDirectory.path, 'dev', 'integration_tests', 'android_host_app')),
        hostApp,
      );
      copy(
        new File(path.join(directory.path, 'hello', '.android', 'gradlew')),
        hostApp,
      );
      copy(
        new File(path.join(directory.path, 'hello', '.android', 'gradle', 'wrapper', 'gradle-wrapper.jar')),
        new Directory(path.join(hostApp.path, 'gradle', 'wrapper')),
      );

      await inDirectory(hostApp, () async {
        await exec('chmod', <String>['+x', 'gradlew']);
        await exec('./gradlew',
          <String>['app:assembleDebug'],
          environment: <String, String>{ 'JAVA_HOME': javaHome },
        );
      });

      final bool appBuilt = exists(new File(path.join(
        hostApp.path,
        'app',
        'build',
        'outputs',
        'apk',
        'debug',
        'app-debug.apk',
      )));

      if (!appBuilt) {
        return new TaskResult.failure('Failed to build .apk');
      }
      return new TaskResult.success(null);
    } catch (e) {
      return new TaskResult.failure(e.toString());
    } finally {
      rmTree(directory);
    }
  });
}
