// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/cache.dart';

import '../src/common.dart';
import 'test_data/deferred_components_config.dart';
import 'test_data/plugin_project.dart';
import 'test_data/project.dart';
import 'test_utils.dart';

const String testPluginName = 'test_plugin';

void main() {
  late Directory tempDir;

  setUp(() {
    Cache.flutterRoot = getFlutterRoot();
    tempDir =
        createResolvedTempDirectorySync('flutter_gradle_source_path_test.');
  });

  tearDown(() async {
    tryToDelete(tempDir);
  });

  test('gradle task builds without setting a source path in app/build.gradle', () async {
    final Project project = PluginWithPathAndroidProject();
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
      '--platforms=android',
      testPluginName,
    ], workingDirectory: tempDir.path);

    final Directory pluginAppDir = tempDir.childDirectory(testPluginName);

    // Create a project which includes the plugin to test against
    final Directory pluginExampleAppDir =
        pluginAppDir.childDirectory('example');

    await project.setUpIn(pluginExampleAppDir);

    // Run flutter build apk to build plugin example project.
    final ProcessResult buildApkResult = processManager.runSync(<String>[
      flutterBin,
      ...getLocalEngineArguments(),
      'build',
      'apk',
      '--debug',
    ], workingDirectory: pluginExampleAppDir.path);

    expect(buildApkResult, const ProcessResultMatcher());
  });
}

/// Project that load's a plugin from the specified path.
class PluginWithPathAndroidProject extends PluginProject {
  @override
  String get pubspec => '''
name: test
environment:
  sdk: '>=3.2.0-0 <4.0.0'
dependencies:
  flutter:
    sdk: flutter

  $testPluginName:
    path: ../
''';

  @override
  DeferredComponentsConfig? get deferredComponents =>
      MissingSourcePathPluginDeferredComponentsConfig();
}

class MissingSourcePathPluginDeferredComponentsConfig
    extends PluginDeferredComponentsConfig {
  final String _flutterSourcePath = '''
  flutter {
      source '../..'
  }
''';

  @override
  String get appBuild {
    if (!super.appBuild.contains(_flutterSourcePath)) {
      throw Exception(
          'Flutter source path not found in original configuration!');
    }
    return super.appBuild.replaceAll(_flutterSourcePath, '');
  }
}
