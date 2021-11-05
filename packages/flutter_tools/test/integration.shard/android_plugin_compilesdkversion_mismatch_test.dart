// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/dart/pub.dart';
import 'package:flutter_tools/src/reporting/reporting.dart';

import '../src/common.dart';
import '../src/fakes.dart';
import 'test_utils.dart';

void main() {

  Directory tempDir;

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

    final RegExp androidCompileSdkVersionRegExp = RegExp(r'compileSdkVersion ([0-9]+|flutter.compileSdkVersion)');

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
    final String newPluginGradleFile = pluginBuildGradle.replaceAll(
      androidCompileSdkVersionRegExp, 'compileSdkVersion 31');
    pluginGradleFile.writeAsStringSync(newPluginGradleFile);

    // Create dummy project
    processManager.runSync(<String>[
      flutterBin,
      ...getLocalEngineArguments(),
      'create',
      '--platforms=android',
      'test_project',
    ], workingDirectory: tempDir.path);

    final Directory projectAppDir = tempDir.childDirectory('test_project');
    final File pubspecFile = projectAppDir.childFile('pubspec.yaml');
    expect(pubspecFile, exists);

    final File projectGradleFile = projectAppDir.childDirectory('android').childDirectory('app').childFile('build.gradle');
    expect(projectGradleFile, exists);

    final String projectBuildGradle = projectGradleFile.readAsStringSync();
    final String pubspecFileString = pubspecFile.readAsStringSync();

    // Bump down project compileSdkVersion to 30
    final String newProjectGradleFile = projectBuildGradle.replaceAll(
      androidCompileSdkVersionRegExp, 'compileSdkVersion 30');
    projectGradleFile.writeAsStringSync(newProjectGradleFile);

    // Add dummy plugin as dependency to dummy project
    final String newPubspecFile= pubspecFileString.replaceFirst(
      'dependencies:', 'dependencies:\n  test_plugin:\n    path: ../test_plugin');
    pubspecFile.writeAsStringSync(newPubspecFile);

    // Run flutter pub get to update the dependencies
    final BufferLogger logger = BufferLogger.test();
    final Pub pub = Pub(
        fileSystem: fileSystem,
        logger: logger,
        processManager: processManager,
        platform: FakePlatform(),
        botDetector: const FakeBotDetector(false),
        usage: TestUsage(),
      );

    await pub.get(
      context: PubContext.flutterTests,
      directory: projectAppDir.path);

    // Run flutter build apk to build dummy project
    final ProcessResult result = processManager.runSync(<String>[
      flutterBin,
      ...getLocalEngineArguments(),
      'build',
      'apk',
      '--target-platform=android-arm',
    ], workingDirectory: projectAppDir.path);

    // Check error message is thrown
    final RegExp charactersToIgnore = RegExp(r'\|/|[\n]');

    expect((result.stdout as String).replaceAll(charactersToIgnore, ''),
      contains('Warning: The plugin test_plugin requires Android SDK version 31.')
      );
    expect((result.stderr as String).replaceAll(charactersToIgnore, ''),
      contains('One or more plugins require a higher Android SDK version.Fix this issue by adding the following to ${projectGradleFile.path}:android {  compileSdkVersion 31    ...}')
      );
   });
}
