// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';


import '../src/common.dart';
import '../src/context.dart';
import 'test_utils.dart';

void main() {
  Directory tempDir;

  setUp(() async {
    tempDir = createResolvedTempDirectorySync('flutter_plugin_test.');
  });

  tearDown(() async {
    tryToDelete(tempDir);
  });

  test('error logged when plugin Android compileSdkVersion higher than project', () async {
    final String flutterBin = fileSystem.path.join(
      getFlutterRoot(),
      'bin',
      'flutter',
    );

    final RegExp androidCompileSdkVersionRegExp = RegExp(r'compileSdkVersion [0-9]+');

    // Create dummy plugin
    processManager.runSync(<String>[
      flutterBin,
      ...getLocalEngineArguments(),
      'create',
      '--template=plugin',
      '--platforms=android',
      'test_plugin',
    ], workingDirectory: tempDir.path);

    final Directory pluginAppDir = tempDir.childDirectory('test_plugin').childDirectory('example');
    final File pluginGradleFile = pluginAppDir.childDirectory('android').childDirectory('app').childFile('build.gradle');
    expect(pluginGradleFile, exists);
    final String pluginBuildGradle = pluginGradleFile.readAsStringSync();


    // Bump up plugin compileSdkVersion to 31
    String pluginNewGradleFile = pluginBuildGradle.replaceAll(
      androidCompileSdkVersionRegExp, 'compileSdkVersion 31');
    pluginGradleFile.writeAsStringSync(pluginNewGradleFile);

    // Create dummy project
    processManager.runSync(<String>[
      flutterBin,
      ...getLocalEngineArguments(),
      'create',
      '--platforms=android',
      'test_project',
    ], workingDirectory: tempDir.path);

    final Directory projectAppDir = tempDir.childDirectory('test_project'); //todo check
    final File pubspecFile = projectAppDir.childFile('pubspec.yaml'); //check exists
    final File projectGradleFile = pluginAppDir.childDirectory('android').childDirectory('app').childFile('build.gradle'); //check exists
    final String projectBuildGradle = projectGradleFile.readAsStringSync();
    final String pubspecFileString = pubspecFile.readAsStringSync();
    final RegExp pubspecDependenciesRegExp = RegExp(r'dependencies:');

    // Bump down project compileSdkVersion to 30
    String newProjectGradleFile = projectBuildGradle.replaceAll(
      androidCompileSdkVersionRegExp, 'compileSdkVersion 30');
    projectGradleFile.writeAsStringSync(newProjectGradleFile);

    // Add dummy plugin as dependency to dummy project
    String newPubspecFile= pubspecFileString.replaceAll(
      pubspecDependenciesRegExp, 'dependencies:\n ../test_plugin');
    projectGradleFile.writeAsStringSync(newPubspecFile);

    // Run flutter build apk to build dummy project
    processManager.runSync(<String>[
      flutterBin,
      ...getLocalEngineArguments(),
      'build',
      'apk',
      '--target-platform=android-arm',
    ], workingDirectory: projectAppDir.path);

    // Check error message is thrown
    expect(testLogger.statusText,
      contains("Warning: The plugin test_plugin requires Android SDK version 31.")
      );
    expect(testLogger.errorText,
      contains("One or more plugins require a higher Android SDK version.\nFix this issue by adding the following to /flutter_plugin_test/test_project/android/app/build.gradle:\nandroid {\n  compileSdkVersion 31\n    ...\n}\n")
      );
  });
}
