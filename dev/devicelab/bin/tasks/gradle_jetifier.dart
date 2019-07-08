// Copyright (c) 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:flutter_devicelab/framework/apk_utils.dart';
import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/utils.dart';
import 'package:path/path.dart' as path;

final String gradlew = Platform.isWindows ? 'gradlew.bat' : 'gradlew';
final String gradlewExecutable = Platform.isWindows ? gradlew : './$gradlew';

/// Tests that Jetifier can translate plugins that use support libraries.
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
          options: <String>['--org', 'io.flutter.devicelab', '--androidx', 'hello'],
        );
      });

      section('Add plugin that uses support libraries');

      final File pubspec = File(path.join(projectDir.path, 'pubspec.yaml'));
      String content = await pubspec.readAsString();
      content = content.replaceFirst(
        '\ndependencies:\n',
        '\ndependencies:\n  firebase_auth: 0.7.0\n',
      );
      await pubspec.writeAsString(content, flush: true);
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
          options: <String>['apk', '--target-platform', 'android-arm', '--verbose'],
        );
      });

      final File releaseApk = File(path.join(
        projectDir.path,
        'build',
        'app',
        'outputs',
        'apk',
        'release',
        'app-release.apk',
      ));

      if (!exists(releaseApk)) {
        return TaskResult.failure('Failed to build release APK');
      }

      final ApkExtractor releaseApkExtractor = ApkExtractor(releaseApk);

      if (!(await releaseApkExtractor.containsClass('io.flutter.plugins.firebaseauth.FirebaseAuthPlugin'))) {
        return TaskResult.failure('Release APK doesn\'t contain class io.flutter.plugins.firebaseauth.FirebaseAuthPlugin');
      }

      if (!(await releaseApkExtractor.containsClass('com.google.firebase.FirebaseApp'))) {
        return TaskResult.failure('Release APK doesn\'t contain class com.google.firebase.FirebaseApp');
      }

      releaseApkExtractor.dispose();

      section('Build debug APK');

      await inDirectory(projectDir, () async {
        await flutter(
          'build',
          options: <String>['apk', '--target-platform', 'android-arm', '--debug', '--verbose'],
        );
      });

      final File debugApk = File(path.join(
        projectDir.path,
        'build',
        'app',
        'outputs',
        'apk',
        'debug',
        'app-debug.apk',
      ));

      if (!exists(debugApk)) {
        return TaskResult.failure('Failed to build debug APK');
      }

      final ApkExtractor debugApkExtractor = ApkExtractor(debugApk);

      if (!(await debugApkExtractor.containsClass('io.flutter.plugins.firebaseauth.FirebaseAuthPlugin'))) {
        return TaskResult.failure('Debug APK doesn\'t contain class io.flutter.plugins.firebaseauth.FirebaseAuthPlugin');
      }

      if (!(await debugApkExtractor.containsClass('com.google.firebase.FirebaseApp'))) {
        return TaskResult.failure('Debug APK doesn\'t contain class com.google.firebase.FirebaseApp');
      }

      debugApkExtractor.dispose();

      return TaskResult.success(null);
    } catch (e) {
      return TaskResult.failure(e.toString());
    } finally {
      rmTree(tempDir);
    }
  });
}
