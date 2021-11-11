// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/cache.dart';

import '../src/common.dart';
import 'test_utils.dart';

void main() {

  late Directory tempDir;

  setUp(()  {
    Cache.flutterRoot = getFlutterRoot();
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

    // Create dummy plugin
    processManager.runSync(<String>[
      flutterBin,
      ...getLocalEngineArguments(),
      'create',
      '--template=plugin',
      '--platforms=android',
      'test_plugin',
    ], workingDirectory: tempDir.path);

    final Directory pluginAppDir = tempDir.childDirectory('test_plugin');
    final File pluginGradleFile = pluginAppDir.childDirectory('android').childFile('build.gradle');
    expect(pluginGradleFile, exists);

    final String pluginBuildGradle = pluginGradleFile.readAsStringSync();

    // Bump up plugin compileSdkVersion to 31
    final RegExp androidCompileSdkVersionRegExp = RegExp(r'compileSdkVersion ([0-9]+|flutter.compileSdkVersion)');
    final String newPluginGradleFile = pluginBuildGradle.replaceAll(
      androidCompileSdkVersionRegExp, 'compileSdkVersion 31');
    pluginGradleFile.writeAsStringSync(newPluginGradleFile);

    final Directory pluginExampleAppDir = pluginAppDir.childDirectory('example');

    final File projectGradleFile = pluginExampleAppDir.childDirectory('android').childDirectory('app').childFile('build.gradle');
    expect(projectGradleFile, exists);

    final String projectBuildGradle = projectGradleFile.readAsStringSync();

    // Bump down plugin example app compileSdkVersion to 30
    final String newProjectGradleFile = projectBuildGradle.replaceAll(
      androidCompileSdkVersionRegExp, 'compileSdkVersion 30');
    projectGradleFile.writeAsStringSync(newProjectGradleFile);

    // Run flutter build apk to build plugin example project
    final ProcessResult result = processManager.runSync(<String>[
      flutterBin,
      ...getLocalEngineArguments(),
      'build',
      'apk',
      '--target-platform=android-arm',
    ], workingDirectory: pluginExampleAppDir.path);

    // Check error message is thrown
    expect(result.stdout,
      contains('Warning: The plugin test_plugin requires Android SDK version 31.')
      );
    expect(result.stderr,
      contains('''
One or more plugins require a higher Android SDK version.
Fix this issue by adding the following to ${projectGradleFile.path}:
android {
  compileSdkVersion 31
  ...
}

'''
      ));
   });
}
