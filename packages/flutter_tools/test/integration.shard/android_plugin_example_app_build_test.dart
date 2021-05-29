// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/base/file_system.dart';

import '../src/common.dart';
import 'test_utils.dart';

void main() {
  Directory tempDir;

  setUp(() async {
    tempDir = createResolvedTempDirectorySync('flutter_plugin_test.');
  });

  tearDown(() async {
    tryToDelete(tempDir);
  });

  test('plugin example can be built using current Flutter Gradle plugin', () async {
    final String flutterBin = fileSystem.path.join(
      getFlutterRoot(),
      'bin',
      'flutter',
    );

    processManager.runSync(<String>[
      flutterBin,
      ...getLocalEngineArguments(),
      'create',
      '--template=plugin',
      '--platforms=android',
      'plugin_test',
    ], workingDirectory: tempDir.path);

    final Directory exampleAppDir = tempDir.childDirectory('plugin_test').childDirectory('example');

    final File buildGradleFile = exampleAppDir.childDirectory('android').childFile('build.gradle');
    expect(buildGradleFile, exists);

    final String buildGradle = buildGradleFile.readAsStringSync();
    final RegExp androidPluginRegExp =
        RegExp(r'com\.android\.tools\.build:gradle:(\d+\.\d+\.\d+)');

    // Use AGP 4.1.0
    String newBuildGradle = buildGradle.replaceAll(
        androidPluginRegExp, 'com.android.tools.build:gradle:4.1.0');
    buildGradleFile.writeAsStringSync(newBuildGradle);

    // Run flutter build apk using AGP 4.1.0
    processManager.runSync(<String>[
      flutterBin,
      ...getLocalEngineArguments(),
      'build',
      'apk',
      '--target-platform=android-arm',
    ], workingDirectory: exampleAppDir.path);

    final File exampleApk = fileSystem.file(fileSystem.path.join(
      exampleAppDir.path,
      'build',
      'app',
      'outputs',
      'flutter-apk',
      'app-release.apk',
    ));
    expect(exampleApk, exists);

    // Clean
    processManager.runSync(<String>[
      flutterBin,
      ...getLocalEngineArguments(),
      'clean',
    ], workingDirectory: exampleAppDir.path);

    // Remove Gradle wrapper
    fileSystem
        .directory(fileSystem.path
            .join(exampleAppDir.path, 'android', 'gradle', 'wrapper'))
        .deleteSync(recursive: true);

    // Use AGP 3.3.0
    newBuildGradle = buildGradle.replaceAll(
        androidPluginRegExp, 'com.android.tools.build:gradle:3.3.0');
    buildGradleFile.writeAsStringSync(newBuildGradle);

    // Enable R8 in gradle.properties
    final File gradleProperties =
        exampleAppDir.childDirectory('android').childFile('gradle.properties');
    expect(gradleProperties, exists);

    gradleProperties.writeAsStringSync('''
org.gradle.jvmargs=-Xmx1536M
android.useAndroidX=true
android.enableJetifier=true
android.enableR8=true''');

    // Run flutter build apk using AGP 3.3.0
    processManager.runSync(<String>[
      flutterBin,
      ...getLocalEngineArguments(),
      'build',
      'apk',
      '--target-platform=android-arm',
    ], workingDirectory: exampleAppDir.path);
    expect(exampleApk, exists);
  });
}
