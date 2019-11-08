// Copyright (c) 2019 The Chromium Authors. All rights reserved.
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

final bool useAndroidEmbeddingV2 = Platform.environment['ENABLE_ANDROID_EMBEDDING_V2'] == 'true';

/// Tests that the Flutter module project template works and supports
/// adding Flutter to an existing Android app.
Future<void> main() async {
  await task(() async {

    section('Find Java');

    final String javaHome = await findJavaHome();
    if (javaHome == null)
      return TaskResult.failure('Could not find Java');
    print('\nUsing JAVA_HOME=$javaHome');

    section('Create Flutter module project');

    final Directory tempDir = Directory.systemTemp.createTempSync('flutter_module_test.');
    final Directory projectDir = Directory(path.join(tempDir.path, 'hello'));
    try {
      await inDirectory(tempDir, () async {
        await flutter(
          'create',
          options: <String>['--org', 'io.flutter.devicelab', 'hello'],
        );
      });

      section('Add assets');

      final File pubspec = File(path.join(projectDir.path, 'pubspec.yaml'));
      String content = await pubspec.readAsString();
      content = content.replaceFirst(
        '\nflutter:\n',
        '\nflutter:\n  assets:\n    - assets/\n',
      );
      await pubspec.writeAsString(content, flush: true);
      File(path.join(projectDir.path, 'assets', 'a.txt'))
        ..createSync(recursive: true);
      File(path.join(projectDir.path, 'assets', 'b.txt'))
        ..createSync();
      await inDirectory(projectDir, () async {
        await flutter(
          'packages',
          options: <String>['get'],
        );
      });

      section('Build Flutter APK');

      await inDirectory(projectDir, () async {
        await flutter(
          'build',
          options: <String>['apk', '--debug'],
        );
      });

     final String apkPath = path.join(
        projectDir.path,
        'build',
        'app',
        'outputs',
        'apk',
        'debug',
        'app-debug.apk',
      );

      checkItContains<String>(<String>[
        ...flutterAssets,
        ...baseApkFiles,
        'assets/flutter_assets/assets/a.txt',
        'assets/flutter_assets/assets/b.txt',
      ], await getFilesInApk(apkPath));

      section('Invalidate asset bundle');

      File(path.join(projectDir.path, 'assets', 'b.txt'))
        ..deleteSync();

      await inDirectory(projectDir, () async {
        await flutter(
          'build',
          options: <String>['apk', '--debug'],
        );
      });

      checkItDoesNotContain(<String>[
        'assets/flutter_assets/assets/b.txt',
      ], await getFilesInApk(apkPath));
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
