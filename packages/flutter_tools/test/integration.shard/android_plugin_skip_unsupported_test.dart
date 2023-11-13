// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/cache.dart';

import '../src/common.dart';
import 'test_data/plugin_each_settings_gradle_project.dart';
import 'test_data/plugin_project.dart';
import 'test_data/project.dart';
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

  // Regression test for https://github.com/flutter/flutter/issues/97729 (#137115).
  Future<ProcessResult> testPlugin({
    required Project project,
  }) async {
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
    String pubspecYamlSrc =
        pubspecFile.readAsStringSync().replaceAll('\r\n', '\n');
    pubspecYamlSrc = pubspecYamlSrc
        .replaceFirst(
      RegExp(r'name:.*\n'),
      'name: test_plugin\n',
    )
        .replaceFirst('''
      android:
        package: com.example.test_plugin
        pluginClass: TestPlugin
''', '''
#      android:
#        package: com.example.test_plugin
#        pluginClass: TestPlugin
''');

    pubspecFile.writeAsStringSync(pubspecYamlSrc);

    // Check the android directory and the build.gradle file within.
    final File pluginGradleFile =
        pluginAppDir.childDirectory('android').childFile('build.gradle');
    expect(pluginGradleFile, exists);

    // Create a project which includes the plugin to test against
    final Directory pluginExampleAppDir =
        pluginAppDir.childDirectory('example');

    await project.setUpIn(pluginExampleAppDir);

    // Run flutter build apk to build plugin example project.
    return processManager.runSync(<String>[
      flutterBin,
      ...getLocalEngineArguments(),
      'build',
      'apk',
      '--debug',
    ], workingDirectory: pluginExampleAppDir.path);
  }

  test('skip plugin if it does not support the Android platform', () async {
    final Project project = PluginWithPathAndroidProject();
    final ProcessResult buildApkResult = await testPlugin(project: project);
    expect(buildApkResult.stderr.toString(), isEmpty);
    expect(buildApkResult.exitCode, equals(0),
        reason:
            'flutter build apk exited with non 0 code: ${buildApkResult.stderr}');
  });

  // TODO(54566): Remove test when issue is resolved.
  /// Test with [PluginEachSettingsGradleProject] with a legacy settings.gradle
  /// which uses the `.flutter-plugins` file to load EACH plugin.
  test(
      'skip plugin if it does not support the Android platform with a _plugin.each_ settings.gradle',
      () async {
    final Project project = PluginEachWithPathAndroidProject();
    final ProcessResult buildApkResult = await testPlugin(project: project);
    expect(buildApkResult.stderr.toString(), isEmpty);
    expect(buildApkResult.exitCode, equals(0),
        reason:
            'flutter build apk exited with non 0 code: ${buildApkResult.stderr}');
  });
}

/// Project that load's a plugin from the specified path.
class PluginWithPathAndroidProject extends PluginProject {
  @override
  String get pubspec => r'''
name: test
environment:
  sdk: '>=3.2.0-0 <4.0.0'
dependencies:
  flutter:
    sdk: flutter

  test_plugin:
    path: ../
  ''';
}

// TODO(54566): Remove class when issue is resolved.
/// [PluginEachSettingsGradleProject] that load's a plugin from the specified
/// path.
class PluginEachWithPathAndroidProject extends PluginEachSettingsGradleProject {
  @override
  String get pubspec => r'''
name: test
environment:
  sdk: '>=3.2.0-0 <4.0.0'
dependencies:
  flutter:
    sdk: flutter

  test_plugin:
    path: ../
  ''';
}
