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

/// Tests that plugins that don't define a `androidx.annotation:annotation:+` or
/// `com.android.support:support-annotations:+` dependency can be built as AAR.
/// aar_init_script.gradle adds these dependencies manually.
Future<void> main() async {
  await task(() async {

    section('Find Java');

    final String javaHome = await findJavaHome();
    if (javaHome == null) {
      return TaskResult.failure('Could not find Java');
    }
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

      section('Add firebase_auth: 0.11.1+12 since it uses AndroidX annotations');
      //  firebase_auth: 0.11.1+12 uses `androidx.annotation.NonNull` without having a
      // dependency on `androidx.annotation:annotation:+`

      final File pubspec = File(path.join(projectDir.path, 'pubspec.yaml'));
      String content = pubspec.readAsStringSync();
      content = content.replaceFirst(
        '\ndependencies:\n',
        '\ndependencies:\n  firebase_auth: 0.11.1+12\n',
      );
      pubspec.writeAsStringSync(content, flush: true);
      await inDirectory(projectDir, () async {
        await flutter(
          'packages',
          options: <String>['get'],
        );
      });

      section('Update proguard rules');

      // Don't obfuscate the input class files, since the test is checking if some classes are in the DEX.
      final File proguardRules = File(path.join(projectDir.path, 'android', 'app', 'proguard-rules.pro'));
      proguardRules.writeAsStringSync('-dontobfuscate', flush: true);

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
        // The plugin class defined by `firebase_auth`.
        'io.flutter.plugins.firebaseauth.FirebaseAuthPlugin',
        // Used by `firebase_auth`.
        'com.google.firebase.FirebaseApp',
      ]);

      section('Build debug APK');

      await inDirectory(projectDir, () async {
        await flutter(
          'build',
          options: <String>[
            'apk',
            '--target-platform', 'android-arm',
            '--debug', '--verbose',
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
        // The plugin class defined by `firebase_auth`.
        'io.flutter.plugins.firebaseauth.FirebaseAuthPlugin',
        // Used by `firebase_auth`.
        'com.google.firebase.FirebaseApp',
      ]);

      return TaskResult.success(null);
    } catch (e) {
      return TaskResult.failure(e.toString());
    } finally {
      rmTree(tempDir);
    }
  });
}
