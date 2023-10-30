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

    // Create dummy plugin that supports iOS and Android.
    processManager.runSync(<String>[
      flutterBin,
      ...getLocalEngineArguments(),
      'create',
      '--template=plugin',
      '--platforms=ios,android',
      'test_plugin',
    ], workingDirectory: tempDir.path);

    final Directory pluginAppDir = tempDir.childDirectory('test_plugin');
    
    // Override pubspec to drop support for the Android implementation.
    final File pubspecFile = pluginAppDir.childFile('pubspec.yaml');
    const String pubspecYamlSrc = r'''
name: test_plugin
version: 0.0.1

environment:
  sdk: '>=3.3.0-71.0.dev <4.0.0'
  flutter: '>=3.3.0'

dependencies:
  flutter:
    sdk: flutter
  plugin_platform_interface: ^2.0.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

flutter:
  plugin:
    platforms:
      ios:
        pluginClass: TestPlugin
''';
    pubspecFile.writeAsStringSync(pubspecYamlSrc);
    
    // Check the android directory and the build.gradle file within.
    final File pluginGradleFile = pluginAppDir
        .childDirectory('android')
        .childFile('build.gradle');
    expect(pluginGradleFile, exists);

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
