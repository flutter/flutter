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

/// Tests that AARs can be built on module projects.
Future<void> main() async {
  await task(() async {

    section('Find Java');

    final String javaHome = await findJavaHome();
    if (javaHome == null)
      return TaskResult.failure('Could not find Java');
    print('\nUsing JAVA_HOME=$javaHome');

    section('Create module project');

    final Directory tempDir = Directory.systemTemp.createTempSync('flutter_module_test.');
    final Directory projectDir = Directory(path.join(tempDir.path, 'hello'));
    try {
      await inDirectory(tempDir, () async {
        await flutter(
          'create',
          options: <String>['--org', 'io.flutter.devicelab', '--template', 'module', 'hello'],
        );
      });

      section('Add plugins');

      final File pubspec = File(path.join(projectDir.path, 'pubspec.yaml'));
      String content = pubspec.readAsStringSync();
      content = content.replaceFirst(
        '\ndependencies:\n',
        '\ndependencies:\n  device_info: 0.4.1\n  package_info: 0.4.0+9\n',
      );
      pubspec.writeAsStringSync(content, flush: true);
      await inDirectory(projectDir, () async {
        await flutter(
          'packages',
          options: <String>['get'],
        );
      });

      section('Build release AAR');

      await inDirectory(projectDir, () async {
        await flutter(
          'build',
          options: <String>['aar', '--verbose'],
        );
      });

      final String repoPath = path.join(
        projectDir.path,
        'build',
        'host',
        'outputs',
        'repo',
      );

      section('Check release Maven artifacts');

      checkFileExists(path.join(
        repoPath,
        'io',
        'flutter',
        'devicelab',
        'hello',
        'flutter_release',
        '1.0',
        'flutter_release-1.0.aar',
      ));

      final String releasePom = path.join(
        repoPath,
        'io',
        'flutter',
        'devicelab',
        'hello',
        'flutter_release',
        '1.0',
        'flutter_release-1.0.pom',
      );

      checkFileExists(releasePom);

      checkFileExists(path.join(
        repoPath,
        'io',
        'flutter',
        'plugins',
        'deviceinfo',
        'device_info_release',
        '1.0',
        'device_info_release-1.0.aar',
      ));

      checkFileExists(path.join(
        repoPath,
        'io',
        'flutter',
        'plugins',
        'deviceinfo',
        'device_info_release',
        '1.0',
        'device_info_release-1.0.pom',
      ));

      checkFileExists(path.join(
        repoPath,
        'io',
        'flutter',
        'plugins',
        'packageinfo',
        'package_info_release',
        '1.0',
        'package_info_release-1.0.aar',
      ));

      checkFileExists(path.join(
        repoPath,
        'io',
        'flutter',
        'plugins',
        'packageinfo',
        'package_info_release',
        '1.0',
        'package_info_release-1.0.pom',
      ));

      section('Check AOT blobs in release POM');

      checkFileContains(<String>[
        'flutter_embedding_release',
        'armeabi_v7a_release',
        'arm64_v8a_release',
        'x86_64_release',
        'package_info_release',
        'device_info_release',
      ], releasePom);

      section('Check assets in release AAR');

      checkItContains<String>(
        <String>[
          ...flutterAssets,
          // AOT snapshots
          'jni/arm64-v8a/libapp.so',
          'jni/armeabi-v7a/libapp.so',
          'jni/x86_64/libapp.so',
        ],
        await getFilesInAar(
          path.join(
            repoPath,
            'io',
            'flutter',
            'devicelab',
            'hello',
            'flutter_release',
            '1.0',
            'flutter_release-1.0.aar',
          )
        )
      );

      section('Build debug AAR');

      await inDirectory(projectDir, () async {
        await flutter(
          'build',
          options: <String>['aar', '--verbose', '--debug'],
        );
      });

      section('Check debug Maven artifacts');

      checkFileExists(path.join(
        repoPath,
        'io',
        'flutter',
        'devicelab',
        'hello',
        'flutter_debug',
        '1.0',
        'flutter_debug-1.0.aar',
      ));

      final String debugPom = path.join(
        repoPath,
        'io',
        'flutter',
        'devicelab',
        'hello',
        'flutter_debug',
        '1.0',
        'flutter_debug-1.0.pom',
      );

      checkFileExists(debugPom);

      checkFileExists(path.join(
        repoPath,
        'io',
        'flutter',
        'plugins',
        'deviceinfo',
        'device_info_debug',
        '1.0',
        'device_info_debug-1.0.aar',
      ));

      checkFileExists(path.join(
        repoPath,
        'io',
        'flutter',
        'plugins',
        'deviceinfo',
        'device_info_debug',
        '1.0',
        'device_info_debug-1.0.pom',
      ));

      checkFileExists(path.join(
        repoPath,
        'io',
        'flutter',
        'plugins',
        'packageinfo',
        'package_info_debug',
        '1.0',
        'package_info_debug-1.0.aar',
      ));

      checkFileExists(path.join(
        repoPath,
        'io',
        'flutter',
        'plugins',
        'packageinfo',
        'package_info_debug',
        '1.0',
        'package_info_debug-1.0.pom',
      ));

      section('Check AOT blobs in debug POM');

      checkFileContains(<String>[
        'flutter_embedding_debug',
        'x86_debug',
        'x86_64_debug',
        'armeabi_v7a_debug',
        'arm64_v8a_debug',
        'package_info_debug',
        'device_info_debug',
      ], debugPom);

      section('Check assets in debug AAR');

      final Iterable<String> debugAar = await getFilesInAar(path.join(
        repoPath,
        'io',
        'flutter',
        'devicelab',
        'hello',
        'flutter_debug',
        '1.0',
        'flutter_debug-1.0.aar',
      ));

      checkItContains<String>(<String>[
        ...flutterAssets,
        ...debugAssets,
      ], debugAar);

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
