// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/task_result.dart';
import 'package:flutter_devicelab/framework/utils.dart';
import 'package:path/path.dart' as path;

final String gradlew = Platform.isWindows ? 'gradlew.bat' : 'gradlew';
final String gradlewExecutable = Platform.isWindows ? '.\\$gradlew' : './$gradlew';

/// Tests that [settings_aar.gradle] is created when possible.
Future<void> main() async {
  await task(() async {

    section('Find Java');

    final String javaHome = await findJavaHome();
    if (javaHome == null)
      return TaskResult.failure('Could not find Java');
    print('\nUsing JAVA_HOME=$javaHome');

    section('Create app project');

    final Directory tempDir = Directory.systemTemp.createTempSync('flutter_module_test.');
    final Directory projectDir = Directory(path.join(tempDir.path, 'hello'));
    try {
      await inDirectory(tempDir, () async {
        await flutter(
          'create',
          options: <String>['hello'],
        );
      });

      section('Override settings.gradle V1');

      final String relativeNewSettingsGradle = path.join('android', 'settings_aar.gradle');

      section('Build APK');

      String stdout;
      await inDirectory(projectDir, () async {
        stdout = await evalFlutter(
          'build',
          options: <String>[
            'apk',
            '--flavor', 'does-not-exist',
          ],
          canFail: true, // The flavor doesn't exist.
        );
      });

      const String newFileContent = "include ':app'";

      final File settingsGradle = File(path.join(projectDir.path, 'android', 'settings.gradle'));
      final File newSettingsGradle = File(path.join(projectDir.path, 'android', 'settings_aar.gradle'));

      if (!newSettingsGradle.existsSync()) {
        return TaskResult.failure('Expected file: `${newSettingsGradle.path}`.');
      }

      if (newSettingsGradle.readAsStringSync().trim() != newFileContent) {
        return TaskResult.failure('Expected to create `${newSettingsGradle.path}` V1.');
      }

      if (!stdout.contains('Creating `$relativeNewSettingsGradle`') ||
          !stdout.contains('`$relativeNewSettingsGradle` created successfully')) {
        return TaskResult.failure('Expected update message in stdout.');
      }

      section('Override settings.gradle V2');

      const String deprecatedFileContentV2 = r'''
include ':app'

def flutterProjectRoot = rootProject.projectDir.parentFile.toPath()

def plugins = new Properties()
def pluginsFile = new File(flutterProjectRoot.toFile(), '.flutter-plugins')
if (pluginsFile.exists()) {
    pluginsFile.withInputStream { stream -> plugins.load(stream) }
}

plugins.each { name, path ->
    def pluginDirectory = flutterProjectRoot.resolve(path).resolve('android').toFile()
    include ":$name"
    project(":$name").projectDir = pluginDirectory
}
''';
      settingsGradle.writeAsStringSync(deprecatedFileContentV2, flush: true);
      newSettingsGradle.deleteSync();

      section('Build APK');

      await inDirectory(projectDir, () async {
        stdout = await evalFlutter(
          'build',
          options: <String>[
            'apk',
            '--flavor', 'does-not-exist',
          ],
          canFail: true, // The flavor doesn't exist.
        );
      });

      if (newSettingsGradle.readAsStringSync().trim() != newFileContent) {
        return TaskResult.failure('Expected to create `${newSettingsGradle.path}` V2.');
      }

      if (!stdout.contains('Creating `$relativeNewSettingsGradle`') ||
          !stdout.contains('`$relativeNewSettingsGradle` created successfully')) {
        return TaskResult.failure('Expected update message in stdout.');
      }

      section('Override settings.gradle with custom logic');

      const String customDeprecatedFileContent = r'''
include ':app'

def flutterProjectRoot = rootProject.projectDir.parentFile.toPath()

def plugins = new Properties()
def pluginsFile = new File(flutterProjectRoot.toFile(), '.flutter-plugins')
if (pluginsFile.exists()) {
    pluginsFile.withInputStream { stream -> plugins.load(stream) }
}

plugins.each { name, path ->
    def pluginDirectory = flutterProjectRoot.resolve(path).resolve('android').toFile()
    include ":$name"
    project(":$name").projectDir = pluginDirectory
}
// some custom logic
''';
      settingsGradle.writeAsStringSync(customDeprecatedFileContent, flush: true);
      newSettingsGradle.deleteSync();

      section('Build APK');

      final StringBuffer stderr = StringBuffer();
      await inDirectory(projectDir, () async {
        stdout = await evalFlutter(
          'build',
          options: <String>[
            'apk',
            '--flavor', 'does-not-exist',
          ],
          canFail: true, // The flavor doesn't exist.
          stderr: stderr,
        );
      });

      if (newSettingsGradle.existsSync()) {
        return TaskResult.failure('Unexpected file: `${newSettingsGradle.path}`.');
      }

      if (!stdout.contains('Creating `$relativeNewSettingsGradle`')) {
        return TaskResult.failure('Expected update message in stdout.');
      }

      if (stdout.contains('`$relativeNewSettingsGradle` created successfully')) {
        return TaskResult.failure('Unexpected message in stdout.');
      }

      if (!stderr.toString().contains('Flutter tried to create the file '
          '`$relativeNewSettingsGradle`, but failed.')) {
        return TaskResult.failure('Expected failure message in stdout.');
      }

      return TaskResult.success(null);
    } catch (e) {
      return TaskResult.failure(e.toString());
    } finally {
      rmTree(tempDir);
    }
  });
}
