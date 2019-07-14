// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/utils.dart';
import 'package:path/path.dart' as path;

final String gradlew = Platform.isWindows ? 'gradlew.bat' : 'gradlew';
final String gradlewExecutable = Platform.isWindows ? gradlew : './$gradlew';

/// Tests that [settings.gradle] is patched when possible.
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

      final String relativeSettingsGradle = path.join('android', 'settings.gradle');
      final File settingsGradle = File(path.join(projectDir.path, 'android', 'settings.gradle'));
      final File oldSettingsGradle = File(path.join(projectDir.path, 'android', '.settings.gradle'));

      const String deprecatedFileContentV1 = '''
include ':app'

def flutterProjectRoot = rootProject.projectDir.parentFile.toPath()

def plugins = new Properties()
def pluginsFile = new File(flutterProjectRoot.toFile(), '.flutter-plugins')
if (pluginsFile.exists()) {
    pluginsFile.withReader('UTF-8') { reader -> plugins.load(reader) }
}

plugins.each { name, path ->
    def pluginDirectory = flutterProjectRoot.resolve(path).resolve('android').toFile()
    include ":\$name"
    project(":\$name").projectDir = pluginDirectory
}
''';
      settingsGradle.writeAsStringSync(deprecatedFileContentV1, flush: true);

      if(oldSettingsGradle.existsSync()) {
        return TaskResult.failure('Unexpected file: `.settings.gradle`.');
      }

      section('Build APK');

      String stdout;
      await inDirectory(projectDir, () async {
        stdout = await evalFlutter(
          'build',
          options: <String>['apk', '--flavor', 'does-not-exist'],
          canFail: true, // The flavor doesn't exist.
        );
      });

      const String newFileContent = 'include \':app\'';

      if (settingsGradle.readAsStringSync().trim() != newFileContent) {
        return TaskResult.failure('Expected to patch `settings.gradle` V1.');
      }

      if (!oldSettingsGradle.existsSync()) {
        return TaskResult.failure('Expected file: `.settings.gradle`.');
      }

      if (oldSettingsGradle.readAsStringSync() != deprecatedFileContentV1) {
        return TaskResult.failure('Expected content from previous V1 file in: `.settings.gradle`.');
      }

      if (!stdout.contains('Updating `$relativeSettingsGradle`') ||
          !stdout.contains('`$relativeSettingsGradle` updated successfully')) {
        return TaskResult.failure('Expected update message in stdout.');
      }

      section('Override settings.gradle V2');

      const String deprecatedFileContentV2 = '''
include ':app'

def flutterProjectRoot = rootProject.projectDir.parentFile.toPath()

def plugins = new Properties()
def pluginsFile = new File(flutterProjectRoot.toFile(), '.flutter-plugins')
if (pluginsFile.exists()) {
    pluginsFile.withInputStream { stream -> plugins.load(stream) }
}

plugins.each { name, path ->
    def pluginDirectory = flutterProjectRoot.resolve(path).resolve('android').toFile()
    include ":\$name"
    project(":\$name").projectDir = pluginDirectory
}
''';
      settingsGradle.writeAsStringSync(deprecatedFileContentV2, flush: true);
      oldSettingsGradle.deleteSync();

      section('Build APK');

      await inDirectory(projectDir, () async {
        stdout = await evalFlutter(
          'build',
          options: <String>['apk', '--flavor', 'does-not-exist'],
          canFail: true, // The flavor doesn't exist.
        );
      });

      if (settingsGradle.readAsStringSync().trim() != newFileContent) {
        return TaskResult.failure('Expected to patch `settings.gradle` V2.');
      }

      if (!oldSettingsGradle.existsSync()) {
        return TaskResult.failure('Expected file: `.settings.gradle`.');
      }

      if (oldSettingsGradle.readAsStringSync() != deprecatedFileContentV2) {
        return TaskResult.failure('Expected content from previous V2 file in: `.settings.gradle`.');
      }

      if (!stdout.contains('Updating `$relativeSettingsGradle`') ||
          !stdout.contains('`$relativeSettingsGradle` updated successfully')) {
        return TaskResult.failure('Expected update message in stdout.');
      }

      section('Override settings.gradle with custom logic');

      const String customDeprecatedFileContent = '''
include ':app'

def flutterProjectRoot = rootProject.projectDir.parentFile.toPath()

def plugins = new Properties()
def pluginsFile = new File(flutterProjectRoot.toFile(), '.flutter-plugins')
if (pluginsFile.exists()) {
    pluginsFile.withInputStream { stream -> plugins.load(stream) }
}

plugins.each { name, path ->
    def pluginDirectory = flutterProjectRoot.resolve(path).resolve('android').toFile()
    include ":\$name"
    project(":\$name").projectDir = pluginDirectory
}
// some custom logic
''';
      settingsGradle.writeAsStringSync(customDeprecatedFileContent, flush: true);
      oldSettingsGradle.deleteSync();

      section('Build APK');

      final StringBuffer stderr = StringBuffer();
      await inDirectory(projectDir, () async {
        stdout = await evalFlutter(
          'build',
          options: <String>['apk', '--flavor', 'does-not-exist'],
          canFail: true, // The flavor doesn't exist.
          stderr: stderr
        );
      });

      if (settingsGradle.readAsStringSync().trim() == newFileContent) {
        return TaskResult.failure('Expected `settings.gradle` to remain unchangeds.');
      }

      if (oldSettingsGradle.existsSync()) {
        return TaskResult.failure('Unexpected file: `.settings.gradle`.');
      }

      if (!stdout.contains('Updating `$relativeSettingsGradle`')) {
        return TaskResult.failure('Expected update message in stdout.');
      }

      if (stdout.contains('`$relativeSettingsGradle` updated successfully')) {
        return TaskResult.failure('Unexpected message in stdout.');
      }

      if (!stderr.toString().contains('Flutter tried to update the file '
          '`$relativeSettingsGradle`, but failed due to local edits')) {
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

void checkFileExists(String file) {
  if (!exists(File(file))) {
    throw FileSystemException('Expected file to exit.', file);
  }
}
