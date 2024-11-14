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
  /// Creates a project which uses a plugin, which is not supported on Android.
  /// This means it has no entry in pubspec.yaml for:
  /// flutter -> plugin -> platforms -> android
  ///
  /// [createAndroidPluginFolder] indicates that the plugin can additionally
  /// have a functioning `android` folder.
  Future<ProcessResult> testUnsupportedPlugin({
    required Project project,
    required bool createAndroidPluginFolder,
  }) async {
    final String flutterBin = fileSystem.path.join(
      getFlutterRoot(),
      'bin',
      'flutter',
    );

    // Create dummy plugin that supports iOS and optionally Android.
    processManager.runSync(<String>[
      flutterBin,
      ...getLocalEngineArguments(),
      'create',
      '--template=plugin',
      '--platforms=ios${createAndroidPluginFolder ? ',android' : ''}',
      'test_plugin',
    ], workingDirectory: tempDir.path);

    final Directory pluginAppDir = tempDir.childDirectory('test_plugin');

    final File pubspecFile = pluginAppDir.childFile('pubspec.yaml');
    String pubspecYamlSrc =
        pubspecFile.readAsStringSync().replaceAll('\r\n', '\n');
    if (createAndroidPluginFolder) {
      // Override pubspec to drop support for the Android implementation.
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
    } else {
      expect(pubspecYamlSrc, isNot(contains('android:')));
    }

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
      // TODO(bkonyi): remove once https://github.com/flutter/flutter/pull/158933 is resolved
      '--verbose',
    ], workingDirectory: pluginExampleAppDir.path);
  }

  test('skip plugin if it does not support the Android platform', () async {
    final Project project = PluginWithPathAndroidProject();
    final ProcessResult buildApkResult = await testUnsupportedPlugin(
        project: project, createAndroidPluginFolder: false);
    expect(buildApkResult.stderr.toString(),
        isNot(contains('Please fix your settings.gradle')));
    expect(buildApkResult, const ProcessResultMatcher());
  });

  test(
      'skip plugin with android folder if it does not support the Android platform',
      () async {
    final Project project = PluginWithPathAndroidProject();
    final ProcessResult buildApkResult = await testUnsupportedPlugin(
        project: project, createAndroidPluginFolder: true);
    expect(buildApkResult.stderr.toString(),
        isNot(contains('Please fix your settings.gradle')));
    expect(buildApkResult, const ProcessResultMatcher());
  });

  // TODO(54566): Remove test when issue is resolved.
  /// Test project with a `settings.gradle` (PluginEach) that apps were created
  /// with until Flutter v1.22.0.
  /// It uses the `.flutter-plugins` file to load EACH plugin.
  test(
      'skip plugin if it does not support the Android platform with a _plugin.each_ settings.gradle',
      () async {
    final Project project = PluginEachWithPathAndroidProject();
    final ProcessResult buildApkResult = await testUnsupportedPlugin(
        project: project, createAndroidPluginFolder: false);
    expect(buildApkResult.stderr.toString(),
        isNot(contains('Please fix your settings.gradle')));
    expect(buildApkResult, const ProcessResultMatcher());
  });

  // TODO(54566): Remove test when issue is resolved.
  /// Test project with a `settings.gradle` (PluginEach) that apps were created
  /// with until Flutter v1.22.0.
  /// It uses the `.flutter-plugins` file to load EACH plugin.
  /// The plugin includes a functional 'android' folder.
  test(
      'skip plugin with android folder if it does not support the Android platform with a _plugin.each_ settings.gradle',
      () async {
    final Project project = PluginEachWithPathAndroidProject();
    final ProcessResult buildApkResult = await testUnsupportedPlugin(
        project: project, createAndroidPluginFolder: true);
    expect(buildApkResult.stderr.toString(),
        isNot(contains('Please fix your settings.gradle')));
    expect(buildApkResult, const ProcessResultMatcher());
  });

  // TODO(54566): Remove test when issue is resolved.
  /// Test project with a `settings.gradle` (PluginEach) that apps were created
  /// with until Flutter v1.22.0.
  /// It is compromised by removing the 'include' statement of the plugins.
  /// As the "'.flutter-plugins'" keyword is still present, the framework
  /// assumes that all plugins are included, which is not the case.
  /// Therefore it should throw an error.
  test(
      'skip plugin if it does not support the Android platform with a compromised _plugin.each_ settings.gradle',
      () async {
    final Project project = PluginCompromisedEachWithPathAndroidProject();
    final ProcessResult buildApkResult = await testUnsupportedPlugin(
        project: project, createAndroidPluginFolder: true);
    expect(
      buildApkResult,
      const ProcessResultMatcher(
          stderrPattern: 'Please fix your settings.gradle'),
    );
  });
}

const String pubspecWithPluginPath = r'''
name: test
environment:
  sdk: '>=3.2.0-0 <4.0.0'
dependencies:
  flutter:
    sdk: flutter

  test_plugin:
    path: ../
''';

/// Project that load's a plugin from the specified path.
class PluginWithPathAndroidProject extends PluginProject {
  @override
  String get pubspec => pubspecWithPluginPath;
}

// TODO(54566): Remove class when issue is resolved.
/// [PluginEachSettingsGradleProject] that load's a plugin from the specified
/// path.
class PluginEachWithPathAndroidProject extends PluginEachSettingsGradleProject {
  @override
  String get pubspec => pubspecWithPluginPath;
}

// TODO(54566): Remove class when issue is resolved.
/// [PluginCompromisedEachSettingsGradleProject] that load's a plugin from the
/// specified path.
class PluginCompromisedEachWithPathAndroidProject
    extends PluginCompromisedEachSettingsGradleProject {
  @override
  String get pubspec => pubspecWithPluginPath;
}
