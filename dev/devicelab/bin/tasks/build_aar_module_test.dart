// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter_devicelab/framework/apk_utils.dart';
import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/task_result.dart';
import 'package:flutter_devicelab/framework/utils.dart';
import 'package:path/path.dart' as path;

final String platformLineSep = Platform.isWindows ? '\r\n': '\n';


final String gradlew = Platform.isWindows ? 'gradlew.bat' : 'gradlew';
final String gradlewExecutable = Platform.isWindows ? '.\\$gradlew' : './$gradlew';

/// Tests that AARs can be built on module projects.
Future<void> main() async {
  await task(() async {

    section('Find Java');

    final String? javaHome = await findJavaHome();
    if (javaHome == null)
      return TaskResult.failure('Could not find Java');
    print('\nUsing JAVA_HOME=$javaHome');

    final Directory tempDir = Directory.systemTemp.createTempSync('flutter_module_test.');
    final Directory projectDir = Directory(path.join(tempDir.path, 'hello'));
    try {
      section('Create module project');

      await inDirectory(tempDir, () async {
        await flutter(
          'create',
          options: <String>['--org', 'io.flutter.devicelab', '--template', 'module', 'hello'],
        );
      });

      section('Create plugin that supports android platform');

      await inDirectory(tempDir, () async {
        await flutter(
          'create',
          options: <String>['--org', 'io.flutter.devicelab', '--template', 'plugin', '--platforms=android', 'plugin_with_android'],
        );
      });

      section("Create plugin that doesn't support android project");

      await inDirectory(tempDir, () async {
        await flutter(
          'create',
          options: <String>['--org', 'io.flutter.devicelab', '--template', 'plugin', '--platforms=ios', 'plugin_without_android'],
        );
      });

      section('Add plugins to pubspec.yaml');

      final File modulePubspec = File(path.join(projectDir.path, 'pubspec.yaml'));
      String content = modulePubspec.readAsStringSync();
      content = content.replaceFirst(
        '${platformLineSep}dependencies:$platformLineSep',
        '${platformLineSep}dependencies:$platformLineSep'
          '  plugin_with_android:$platformLineSep'
          '    path: ../plugin_with_android$platformLineSep'
          '  plugin_without_android:$platformLineSep'
          '    path: ../plugin_without_android$platformLineSep'
          '  webcrypto: 0.5.2$platformLineSep', // Plugin that uses NDK.
      );
      modulePubspec.writeAsStringSync(content, flush: true);

      section('Run packages get in module project');

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

      section('Check release Maven artifacts (old format)');

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

      final String releasePomOld = path.join(
        repoPath,
        'io',
        'flutter',
        'devicelab',
        'hello',
        'flutter_release',
        '1.0',
        'flutter_release-1.0.pom',
      );

      checkFileExists(releasePomOld);

      checkFileExists(path.join(
        repoPath,
        'io',
        'flutter',
        'devicelab',
        'plugin_with_android',
        'plugin_with_android_release',
        '1.0',
        'plugin_with_android_release-1.0.aar',
      ));

      checkFileExists(path.join(
        repoPath,
        'io',
        'flutter',
        'devicelab',
        'plugin_with_android',
        'plugin_with_android_release',
        '1.0',
        'plugin_with_android_release-1.0.pom',
      ));

      section('Check release Maven artifacts (new format)');

      checkFileExists(path.join(
        repoPath,
        'io',
        'flutter',
        'devicelab',
        'hello',
        'flutter',
        '1.0',
        'flutter-1.0-release.aar',
      ));

      final String releasePomNew = path.join(
        repoPath,
        'io',
        'flutter',
        'devicelab',
        'hello',
        'flutter',
        '1.0',
        'flutter-1.0.pom',
      );

      checkFileExists(releasePomNew);

      checkFileExists(path.join(
        repoPath,
        'io',
        'flutter',
        'devicelab',
        'plugin_with_android',
        'plugin_with_android',
        '1.0',
        'plugin_with_android-1.0-release.aar',
      ));

      checkFileExists(path.join(
        repoPath,
        'io',
        'flutter',
        'devicelab',
        'plugin_with_android',
        'plugin_with_android',
        '1.0',
        'plugin_with_android-1.0.pom',
      ));

      section('Check AOT blobs in release POM');

      checkFileContains(<String>[
        'flutter_embedding_release',
        'armeabi_v7a_release',
        'arm64_v8a_release',
        'x86_64_release',
        'plugin_with_android',
        '<relocation>', //make sure the old pom contains the <relocation> tag
      ], releasePomOld);

      checkFileContains(<String>[
        'flutter_embedding_release',
        'armeabi_v7a_release',
        'arm64_v8a_release',
        'x86_64_release',
        'plugin_with_android',
      ], releasePomNew);

      section('Check assets in release AAR');

      checkCollectionContains<String>(
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

      checkCollectionContains<String>(
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
                'flutter',
                '1.0',
                'flutter-1.0-release.aar',
              )
          )
      );

      section('Check debug Maven artifacts (old format)');

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

      final String debugPomOld = path.join(
        repoPath,
        'io',
        'flutter',
        'devicelab',
        'hello',
        'flutter_debug',
        '1.0',
        'flutter_debug-1.0.pom',
      );

      checkFileExists(debugPomOld);

      checkFileExists(path.join(
        repoPath,
        'io',
        'flutter',
        'devicelab',
        'plugin_with_android',
        'plugin_with_android_debug',
        '1.0',
        'plugin_with_android_debug-1.0.aar',
      ));

      checkFileExists(path.join(
        repoPath,
        'io',
        'flutter',
        'devicelab',
        'plugin_with_android',
        'plugin_with_android_debug',
        '1.0',
        'plugin_with_android_debug-1.0.pom',
      ));

      section('Check debug Maven artifacts (new format)');

      checkFileExists(path.join(
        repoPath,
        'io',
        'flutter',
        'devicelab',
        'hello',
        'flutter',
        '1.0',
        'flutter-1.0-debug.aar',
      ));

      final String debugPomNew = path.join(
        repoPath,
        'io',
        'flutter',
        'devicelab',
        'hello',
        'flutter',
        '1.0',
        'flutter-1.0.pom',
      );

      checkFileExists(debugPomNew);

      checkFileExists(path.join(
        repoPath,
        'io',
        'flutter',
        'devicelab',
        'plugin_with_android',
        'plugin_with_android',
        '1.0',
        'plugin_with_android-1.0-debug.aar',
      ));

      checkFileExists(path.join(
        repoPath,
        'io',
        'flutter',
        'devicelab',
        'plugin_with_android',
        'plugin_with_android',
        '1.0',
        'plugin_with_android-1.0.pom',
      ));

      section('Check AOT blobs in debug POM');

      checkFileContains(<String>[
        'flutter_embedding_debug',
        'x86_debug',
        'x86_64_debug',
        'armeabi_v7a_debug',
        'arm64_v8a_debug',
        'plugin_with_android',
        '<relocation>', //make sure the old pom contains the <relocation> tag
      ], debugPomOld);

      checkFileContains(<String>[
        'flutter_embedding_debug',
        'x86_debug',
        'x86_64_debug',
        'armeabi_v7a_debug',
        'arm64_v8a_debug',
        'plugin_with_android',
      ], debugPomNew);

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

      final Iterable<String> debugAarNew = await getFilesInAar(path.join(
        repoPath,
        'io',
        'flutter',
        'devicelab',
        'hello',
        'flutter',
        '1.0',
        'flutter-1.0-debug.aar',
      ));

      checkCollectionContains<String>(<String>[
        ...flutterAssets,
        ...debugAssets,
      ], debugAar);

      checkCollectionContains<String>(<String>[
        ...flutterAssets,
        ...debugAssets,
      ], debugAarNew);

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
