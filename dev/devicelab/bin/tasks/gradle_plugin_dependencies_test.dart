// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:flutter_devicelab/framework/apk_utils.dart';
import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/utils.dart';
import 'package:path/path.dart' as path;

final String gradlew = Platform.isWindows ? 'gradlew.bat' : 'gradlew';
final String gradlewExecutable = Platform.isWindows ? '.\\$gradlew' : './$gradlew';

/// Tests that projects can include plugins that have a transitive dependency in common.
/// For more info see: https://github.com/flutter/flutter/issues/27254.
Future<void> main() async {
  await task(() async {

    section('Find Java');

    final String javaHome = await findJavaHome();
    if (javaHome == null)
      return TaskResult.failure('Could not find Java');
    print('\nUsing JAVA_HOME=$javaHome');

    section('Create Flutter AndroidX app project');

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

      section('Add plugin that have conflicting dependencies');

      final File pubspec = File(path.join(projectDir.path, 'pubspec.yaml'));
      String content = pubspec.readAsStringSync();

      // `flutter_local_notifications` uses `androidx.core:core:1.0.1`
      // `firebase_core` and `firebase_messaging` use `androidx.core:core:1.0.0`.
      content = content.replaceFirst(
        '\ndependencies:\n',
        '\ndependencies:\n  flutter_local_notifications: 0.7.1+3\n  firebase_core:\n  firebase_messaging:\n',
      );
      pubspec.writeAsStringSync(content, flush: true);
      await inDirectory(projectDir, () async {
        await flutter(
          'packages',
          options: <String>['get'],
        );
      });

      section('Build release APK');

      await inDirectory(projectDir, () async {
        await flutter(
          'build',
          options: <String>[
            'apk',
            '--target-platform', 'android-arm',
            '--verbose',
          ],
        );
      });

      final File releaseApk = File(path.join(
        projectDir.path,
        'build',
        'app',
        'outputs',
        'flutter-apk',
        'app-release.apk',
      ));

      if (!exists(releaseApk)) {
        return TaskResult.failure('Failed to build release APK.');
      }

      checkApkContainsClasses(releaseApk, <String>[
        // Used by `flutter_local_notifications`.
        'com.google.gson.Gson',
        // Used by `firebase_core` and `firebase_messaging`.
        'com.google.firebase.FirebaseApp',
        // Used by `firebase_core`.
        'com.google.firebase.FirebaseOptions',
        // Used by `firebase_messaging`.
        'com.google.firebase.messaging.FirebaseMessaging',
      ]);

      section('Build debug APK');

      await inDirectory(projectDir, () async {
        await flutter(
          'build',
          options: <String>[
            'apk',
            '--target-platform', 'android-arm',
            '--debug',
            '--verbose',
          ],
        );
      });

      final File debugApk = File(path.join(
        projectDir.path,
        'build',
        'app',
        'outputs',
        'flutter-apk',
        'app-debug.apk',
      ));

      if (!exists(debugApk)) {
        return TaskResult.failure('Failed to build debug APK.');
      }

      checkApkContainsClasses(debugApk, <String>[
        // Used by `flutter_local_notifications`.
        'com.google.gson.Gson',
        // Used by `firebase_core` and `firebase_messaging`.
        'com.google.firebase.FirebaseApp',
        // Used by `firebase_core`.
        'com.google.firebase.FirebaseOptions',
        // Used by `firebase_messaging`.
        'com.google.firebase.messaging.FirebaseMessaging',
      ]);

      return TaskResult.success(null);
    } catch (e) {
      return TaskResult.failure(e.toString());
    } finally {
      rmTree(tempDir);
    }
  });
}
