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

  setUp(() {
    Cache.flutterRoot = getFlutterRoot();
    tempDir = createResolvedTempDirectorySync('flutter_plugin_test.');
  });

  tearDown(() async {
    tryToDelete(tempDir);
  });

  // Regression test for https://github.com/flutter/flutter/issues/97729.
  test('skip plugin if it does not support the Android platform', () async {
    final String flutterBin = fileSystem.path.join(
      getFlutterRoot(),
      'bin',
      'flutter',
    );

    // Create dummy plugin that *only* supports iOS.
    processManager.runSync(<String>[
      flutterBin,
      ...getLocalEngineArguments(),
      'create',
      '--template=plugin',
      '--platforms=ios',
      'test_plugin',
    ], workingDirectory: tempDir.path);

    final Directory pluginAppDir = tempDir.childDirectory('test_plugin');

    // Create an android directory and a build.gradle file within.
    final File pluginGradleFile = pluginAppDir
        .childDirectory('android')
        .childFile('build.gradle')
      ..createSync(recursive: true);
    expect(pluginGradleFile, exists);

    pluginGradleFile.writeAsStringSync(r'''
buildscript {
    ext.kotlin_version = '1.5.31'
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath 'com.android.tools.build:gradle:7.0.0'
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
    }

    configurations.classpath {
        resolutionStrategy.activateDependencyLocking()
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.buildDir = '../build'

subprojects {
    project.buildDir = "${rootProject.buildDir}/${project.name}"
}

subprojects {
    project.evaluationDependsOn(':app')
}

task clean(type: Delete) {
    delete rootProject.buildDir
}
''');

    final Directory pluginExampleAppDir =
        pluginAppDir.childDirectory('example');

    // Add android support to the plugin's example app.
    final ProcessResult addAndroidResult = processManager.runSync(<String>[
      flutterBin,
      ...getLocalEngineArguments(),
      'create',
      '--template=app',
      '--platforms=android',
      '.',
    ], workingDirectory: pluginExampleAppDir.path);
    expect(addAndroidResult.exitCode, equals(0),
        reason:
            'flutter create exited with non 0 code: ${addAndroidResult.stderr}');

    // Run flutter build apk to build plugin example project.
    final ProcessResult buildApkResult = processManager.runSync(<String>[
      flutterBin,
      ...getLocalEngineArguments(),
      'build',
      'apk',
      '--debug',
    ], workingDirectory: pluginExampleAppDir.path);
    expect(buildApkResult.exitCode, equals(0),
        reason:
            'flutter build apk exited with non 0 code: ${buildApkResult.stderr}');
  });
}
