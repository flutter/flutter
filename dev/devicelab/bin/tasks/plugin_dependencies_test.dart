// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
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

      section('Create plugin C without android/ directory');

      final Directory pluginCDirectory = Directory(path.join(tempDir.path, 'plugin_c'));
      await inDirectory(tempDir, () async {
        await flutter(
          'create',
          options: <String>[
            '--org',
            'io.flutter.devicelab.plugin_c',
            '--template=plugin',
            pluginCDirectory.path,
          ],
        );
      });

      final File pluginCpubspec = File(path.join(pluginCDirectory.path, 'pubspec.yaml'));
      await pluginCpubspec.writeAsString('''
name: plugin_c
version: 0.0.1

flutter:
  plugin:
    platforms:
      ios:
        pluginClass: Plugin_cPlugin

dependencies:
  flutter:
    sdk: flutter

environment:
  sdk: ">=2.0.0-dev.28.0 <3.0.0"
  flutter: ">=1.5.0 <2.0.0"
''', flush: true);

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

      section('Make plugin A depend on plugin B and plugin C');

      final File pluginApubspec = File(path.join(pluginADirectory.path, 'pubspec.yaml'));
      String pluginApubspecContent = await pluginApubspec.readAsString();
      pluginApubspecContent = pluginApubspecContent.replaceFirst(
        '\ndependencies:\n',
        '\ndependencies:\n'
        '  plugin_b:\n'
        '    path: ${pluginBDirectory.path}\n'
        '  plugin_c:\n'
        '    path: ${pluginCDirectory.path}\n',
      );
      await pluginApubspec.writeAsString(pluginApubspecContent, flush: true);

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

      final Map<String, dynamic> jsonContent = json.decode(flutterPluginsDependenciesFileContent) as Map<String, dynamic>;

      // Verify the dependencyGraph object is valid. The rest of the contents of this file are not relevant to the
      // dependency graph and are tested by unit tests.
      final List<dynamic> dependencyGraph = jsonContent['dependencyGraph'] as List<dynamic>;
      const String kExpectedPluginsDependenciesContent =
        '['
          '{'
            '"name":"plugin_a",'
            '"dependencies":["plugin_b","plugin_c"]'
          '},'
          '{'
            '"name":"plugin_b",'
            '"dependencies":[]'
          '},'
          '{'
            '"name":"plugin_c",'
            '"dependencies":[]'
          '}'
        ']';
      final String graphString = json.encode(dependencyGraph);
      if (graphString != kExpectedPluginsDependenciesContent) {
        return TaskResult.failure(
          'Unexpected file content in ${flutterPluginsDependenciesFile.path}: '
          'Found "$graphString" instead of "$kExpectedPluginsDependenciesContent"'
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
