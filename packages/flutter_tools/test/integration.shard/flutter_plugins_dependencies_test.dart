// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'package:file/file.dart';

import '../src/common.dart';
import 'test_utils.dart';

void main() {
  late Directory tempProjectDir;
  late Directory tempPluginADir;
  late Directory tempPluginBDir;

  setUp(() {
    tempProjectDir = createResolvedTempDirectorySync(
        'flutter_plugins_dependencies_test_project.');
    tempPluginADir = createResolvedTempDirectorySync(
        'flutter_plugins_dependencies_test_plugin_a.');
    tempPluginBDir = createResolvedTempDirectorySync(
        'flutter_plugins_dependencies_test_plugin_b.');
  });

  tearDown(() {
    tryToDelete(tempProjectDir);
  });

  test(
      '.flutter-plugins-dependencies correctly denotes project dev dependencies on iOS, Android',
      () async {
    // Create Flutter project.
    final String flutterBin =
        fileSystem.path.join(getFlutterRoot(), 'bin', 'flutter');

    await processManager.run(<String>[
      flutterBin,
      'create',
      tempProjectDir.path,
      '--project-name=testapp',
    ], workingDirectory: tempProjectDir.path);

    final File pubspecFile = tempProjectDir.childFile('pubspec.yaml');
    expect(pubspecFile.existsSync(), true);
    String pubspecFileAsString = pubspecFile.readAsStringSync();

    // Create Flutter plugins to add as dependencies to Flutter project.
    await processManager.run(<String>[
      flutterBin,
      'create',
      tempPluginADir.path,
      '--template=plugin',
      '--platforms=android', //TODO(camsim99): Consider looping through platforms to verify behavior across.
      '--project-name=plugin_a_real_dependency',
    ], workingDirectory: tempPluginADir.path);

    await processManager.run(<String>[
      flutterBin,
      'create',
      tempPluginBDir.path,
      '--template=plugin',
      '--platforms=android', //TODO(camsim99): Consider looping through platforms to verify behavior across.
      '--project-name=plugin_b_dev_dependency',
    ], workingDirectory: tempPluginBDir.path);

    // Add dependency on two plugin: one dependency, one dev dependency.
    await processManager.run(<String>[
      flutterBin,
      'pub',
      'add',
      'plugin_a_real_dependency', //TODO(camsim99): Figure out how this should work.
      tempProjectDir.path,
    ], workingDirectory: tempProjectDir.path);
    await processManager.run(<String>[
      flutterBin,
      'pub',
      'add',
      'plugin_b_dev_dependency',
      '--dev-dependency', //TODO(camsim99): Figure out how this should work.
      tempProjectDir.path,
    ], workingDirectory: tempProjectDir.path);

    // Run `flutter pub get` to generate .flutter-plugins-dependencies.
    await processManager.run(<String>[
      flutterBin,
      'pub',
      'get',
    ], workingDirectory: tempProjectDir.path);

    final File flutterPluginsDependenciesFile =
        tempProjectDir.childFile('.flutter-plugins-dependencies');
    expect(flutterPluginsDependenciesFile.existsSync(), true);

    // Check that .flutter-plugin-dependencies denotes dependencies and
    // dev dependencies as expected.
    final String pluginsString =
        flutterPluginsDependenciesFile.readAsStringSync();
    final Map<String, dynamic> jsonContent =
        json.decode(pluginsString) as Map<String, dynamic>;
    final Map<String, dynamic> plugins =
        jsonContent['plugins'] as Map<String, dynamic>;

    //  TODO(camsim99): Consider looping through platforms to verify behavior across.
    final List<String> platformsToVerify = <String>[
      'android',
      // 'ios',
      // 'macos',
      // 'web'
    ];

    for (final String platform in platformsToVerify) {
      final List<dynamic> pluginsForPlatform =
          plugins[platform] as List<dynamic>;

      for (final dynamic plugin in pluginsForPlatform) {
        final Map<String, dynamic> pluginProperties =
            plugin as Map<String, dynamic>;
        final String pluginName = pluginProperties['name'] as String;
        final bool pluginIsDevDependency =
            pluginProperties['dev_dependency'] as bool;

        // Check camera dependencies are not marked as dev dependencies.
        if (pluginName.startsWith('plugin_a_real_dependency')) {
          expect(pluginIsDevDependency, isFalse);
        }

        // Check video_player dependencies are marked as dev dependencies.
        if (pluginName.startsWith('plugin_b_dev_dependency')) {
          expect(pluginIsDevDependency, isTrue);
        }
      }
    }
  });
}
