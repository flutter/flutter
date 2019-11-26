// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/utils.dart';
import 'package:path/path.dart' as path;

/// Tests that a plugin A can depend on platform code from a plugin B
/// as long as plugin B is defined as a pub dependency of plugin A.
///
/// This test fails when `flutter build apk` fails and the stderr from this command
/// contains "Unresolved reference: plugin_b".
Future<void> main() async {
  await task(() async {

    section('Find Java');

    final String javaHome = await findJavaHome();
    if (javaHome == null) {
      return TaskResult.failure('Could not find Java');
    }

    print('\nUsing JAVA_HOME=$javaHome');

    final Directory tempDir = Directory.systemTemp.createTempSync('flutter_plugin_dependencies.');
    try {

      section('Create plugin A');

      final Directory pluginADirectory = Directory(path.join(tempDir.path, 'plugin_a'));
      await inDirectory(tempDir, () async {
        await flutter(
          'create',
          options: <String>[
            '--org',
            'io.flutter.devicelab.plugin_a',
            '--template=plugin',
            pluginADirectory.path,
          ],
        );
      });

      section('Create plugin B');

      final Directory pluginBDirectory = Directory(path.join(tempDir.path, 'plugin_b'));
      await inDirectory(tempDir, () async {
        await flutter(
          'create',
          options: <String>[
            '--org',
            'io.flutter.devicelab.plugin_b',
            '--template=plugin',
            pluginBDirectory.path,
          ],
        );
      });

      section('Write dummy Kotlin code in plugin B');

      final File pluginBKotlinClass = File(path.join(
        pluginBDirectory.path,
        'android',
        'src',
        'main',
        'kotlin',
        'DummyPluginBClass.kt',
      ));

      await pluginBKotlinClass.writeAsString('''
package io.flutter.devicelab.plugin_b

public class DummyPluginBClass {
  companion object {
    fun dummyStaticMethod() {
    }
  }
}
''', flush: true);

      section('Make plugin A depend on plugin B');

      final File pubspec = File(path.join(pluginADirectory.path, 'pubspec.yaml'));
      String content = await pubspec.readAsString();
      content = content.replaceFirst(
        '\ndependencies:\n',
        '\ndependencies:\n'
        '  plugin_b:\n'
        '    path: ${pluginBDirectory.path}\n',
      );
      await pubspec.writeAsString(content, flush: true);

      section('Write Kotlin code in plugin A that references Kotlin code from plugin B');

      final File pluginAKotlinClass = File(path.join(
        pluginADirectory.path,
        'android',
        'src',
        'main',
        'kotlin',
        'DummyPluginAClass.kt',
      ));

      await pluginAKotlinClass.writeAsString('''
package io.flutter.devicelab.plugin_a

import io.flutter.devicelab.plugin_b.DummyPluginBClass

public class DummyPluginAClass {
  constructor() {
    // Call a method from plugin b.
    DummyPluginBClass.dummyStaticMethod();
  }
}
''', flush: true);

      section('Verify .flutter-plugins-dependencies');

      final Directory exampleApp = Directory(path.join(pluginADirectory.path, 'example'));

      await inDirectory(exampleApp, () async {
        await flutter(
          'packages',
          options: <String>['get'],
        );
      });

      final File flutterPluginsDependenciesFile =
          File(path.join(exampleApp.path, '.flutter-plugins-dependencies'));

      if (!flutterPluginsDependenciesFile.existsSync()) {
        return TaskResult.failure('${flutterPluginsDependenciesFile.path} doesn\'t exist');
      }

      final String flutterPluginsDependenciesFileContent = flutterPluginsDependenciesFile.readAsStringSync();
      const String kExpectedPluginsDependenciesContent =
        '{'
          '\"_info\":\"// This is a generated file; do not edit or check into version control.\",'
          '\"dependencyGraph\":['
            '{'
              '\"name\":\"plugin_a\",'
              '\"dependencies\":[\"plugin_b\"]'
            '},'
            '{'
              '\"name\":\"plugin_b\",'
              '\"dependencies\":[]'
            '}'
          ']'
        '}';

      if (flutterPluginsDependenciesFileContent != kExpectedPluginsDependenciesContent) {
        return TaskResult.failure(
          'Unexpected file content in ${flutterPluginsDependenciesFile.path}: '
          'Found "$flutterPluginsDependenciesFileContent" instead of '
          '"$kExpectedPluginsDependenciesContent"'
        );
      }

      section('Build plugin A example app');

      final StringBuffer stderr = StringBuffer();
      await inDirectory(exampleApp, () async {
        await evalFlutter(
          'build',
          options: <String>['apk', '--target-platform', 'android-arm'],
          canFail: true,
          stderr: stderr,
        );
      });

      if (stderr.toString().contains('Unresolved reference: plugin_b')) {
        return TaskResult.failure('plugin_a cannot reference plugin_b');
      }

      final bool pluginAExampleApk = exists(File(path.join(
        pluginADirectory.path,
        'example',
        'build',
        'app',
        'outputs',
        'apk',
        'release',
        'app-release.apk',
      )));

      if (!pluginAExampleApk) {
        return TaskResult.failure('Failed to build plugin A example APK');
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
