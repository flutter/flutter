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
          options: <String>['--org', 'io.flutter.devicelab', '--template=module', 'hello'],
        );
      });

      section('Add plugins');

      final File pubspec = File(path.join(projectDir.path, 'pubspec.yaml'));
      String content = await pubspec.readAsString();
      content = content.replaceFirst(
        '\ndependencies:\n',
        '\ndependencies:\n  device_info: 0.4.1\n  package_info: 0.4.0+9\n',
      );
      await pubspec.writeAsString(content, flush: true);
      await inDirectory(projectDir, () async {
        await flutter(
          'packages',
          options: <String>['get'],
        );
      });

      section('Build Flutter module library archive');

      await inDirectory(Directory(path.join(projectDir.path, '.android')), () async {
        await exec(
          gradlewExecutable,
          <String>['flutter:assembleDebug'],
          environment: <String, String>{ 'JAVA_HOME': javaHome },
        );
      });

      final bool aarBuilt = exists(File(path.join(
        projectDir.path,
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

      await inDirectory(projectDir, () async {
        await flutter(
          'build',
          options: <String>['apk'],
        );
      });

      final bool ephemeralHostApkBuilt = exists(File(path.join(
        projectDir.path,
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

      await inDirectory(projectDir, () async {
        await flutter('clean');
      });

      section('Make Android host app editable');

      await inDirectory(projectDir, () async {
        await flutter(
          'make-host-app-editable',
          options: <String>['android'],
        );
      });

      section('Build editable host app');

      await inDirectory(projectDir, () async {
        await flutter(
          'build',
          options: <String>['apk'],
        );
      });

      final bool editableHostApkBuilt = exists(File(path.join(
        projectDir.path,
        'build',
        'host',
        'outputs',
        'apk',
        'release',
        'app-release.apk',
      )));

      if (!editableHostApkBuilt) {
        return TaskResult.failure('Failed to build editable host .apk');
      }

      section('Add to existing Android app');

      final Directory hostApp = Directory(path.join(tempDir.path, 'hello_host_app'));
      mkdir(hostApp);
      recursiveCopy(
        Directory(
          path.join(
            flutterDirectory.path,
            'dev',
            'integration_tests',
            useAndroidEmbeddingV2 ? 'android_host_app_v2_embedding' : 'android_host_app',
          ),
        ),
        hostApp,
      );
      copy(
        File(path.join(projectDir.path, '.android', gradlew)),
        hostApp,
      );
      copy(
        File(path.join(projectDir.path, '.android', 'gradle', 'wrapper', 'gradle-wrapper.jar')),
        Directory(path.join(hostApp.path, 'gradle', 'wrapper')),
      );

      final File analyticsOutputFile = File(path.join(tempDir.path, 'analytics.log'));

      section('Build debug host APK');

      await inDirectory(hostApp, () async {
        if (!Platform.isWindows) {
          await exec('chmod', <String>['+x', 'gradlew']);
        }
        await exec(gradlewExecutable,
          <String>['app:assembleDebug'],
          environment: <String, String>{
            'JAVA_HOME': javaHome,
            'FLUTTER_ANALYTICS_LOG_FILE': analyticsOutputFile.path,
          },
        );
      });

      section('Check debug APK exists');

      final String debugHostApk = path.join(
        hostApp.path,
        'app',
        'build',
        'outputs',
        'apk',
        'debug',
        'app-debug.apk',
      );
      if (!exists(File(debugHostApk))) {
        return TaskResult.failure('Failed to build debug host APK');
      }

      section('Check files in debug APK');

      checkItContains<String>(<String>[
        ...flutterAssets,
        ...debugAssets,
        ...baseApkFiles,
      ], await getFilesInApk(debugHostApk));

      section('Check debug AndroidManifest.xml');

      final String androidManifestDebug = await getAndroidManifest(debugHostApk);
      if (!androidManifestDebug.contains('''
        <meta-data
            android:name="flutterProjectType"
            android:value="module" />''')
      ) {
        return TaskResult.failure('Debug host APK doesn\'t contain metadata: flutterProjectType = module ');
      }

      final String analyticsOutput = analyticsOutputFile.readAsStringSync();
      if (!analyticsOutput.contains('cd24: android-arm64')
          || !analyticsOutput.contains('cd25: true')
          || !analyticsOutput.contains('viewName: build/bundle')) {
        return TaskResult.failure(
          'Building outer app produced the following analytics: "$analyticsOutput"'
          'but not the expected strings: "cd24: android-arm64", "cd25: true" and '
          '"viewName: build/bundle"'
        );
      }

      section('Build release host APK');

      await inDirectory(hostApp, () async {
        await exec(gradlewExecutable,
          <String>['app:assembleRelease'],
          environment: <String, String>{
            'JAVA_HOME': javaHome,
            'FLUTTER_ANALYTICS_LOG_FILE': analyticsOutputFile.path,
          },
        );
      });

      final String releaseHostApk = path.join(
        hostApp.path,
        'app',
        'build',
        'outputs',
        'apk',
        'release',
        'app-release-unsigned.apk',
      );
      if (!exists(File(releaseHostApk))) {
        return TaskResult.failure('Failed to build release host APK');
      }

      section('Check files in release APK');

      checkItContains<String>(<String>[
        ...flutterAssets,
        ...baseApkFiles,
        'lib/arm64-v8a/libapp.so',
        'lib/arm64-v8a/libflutter.so',
        'lib/armeabi-v7a/libapp.so',
        'lib/armeabi-v7a/libflutter.so',
      ], await getFilesInApk(releaseHostApk));

      section('Check release AndroidManifest.xml');

      final String androidManifestRelease = await getAndroidManifest(debugHostApk);
      if (!androidManifestRelease.contains('''
        <meta-data
            android:name="flutterProjectType"
            android:value="module" />''')
      ) {
        return TaskResult.failure('Release host APK doesn\'t contain metadata: flutterProjectType = module ');
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
