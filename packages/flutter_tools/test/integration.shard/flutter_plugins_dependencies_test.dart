// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'package:file/file.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/flutter_plugins.dart';

import '../src/common.dart';
import 'test_utils.dart';

void main() {
  test(
    '.flutter-plugins-dependencies correctly denotes project dev dependencies on all default platforms',
    () async {
      final Directory tempDir = createResolvedTempDirectorySync(
        'flutter_plugins_dependencies_test.',
      );
      final Directory tempProjectDir = tempDir.childDirectory('project')..createSync();
      final Directory tempPluginADir = tempDir.childDirectory('plugin_a')..createSync();
      final Directory tempPluginBDir = tempDir.childDirectory('plugin_b')..createSync();

      addTearDown(() {
        tryToDelete(tempDir);
      });

      // Create Flutter project.
      await processManager.run(<String>[
        flutterBin,
        'create',
        tempProjectDir.path,
        '--project-name=testapp',
      ], workingDirectory: tempProjectDir.path);

      final File pubspecFile = tempProjectDir.childFile('pubspec.yaml');
      expect(pubspecFile.existsSync(), true);

      // Create Flutter plugins to add as dependencies to Flutter project.
      final pluginAPath = '${tempPluginADir.path}/plugin_a_real_dependency';
      final pluginBPath = '${tempPluginBDir.path}/plugin_b_dev_dependency';

      await processManager.run(<String>[
        flutterBin,
        'create',
        pluginAPath,
        '--template=plugin',
        '--project-name=plugin_a_real_dependency',
        '--platforms=ios',
      ], workingDirectory: tempPluginADir.path);

      await processManager.run(<String>[
        flutterBin,
        'create',
        pluginBPath,
        '--template=plugin',
        '--project-name=plugin_b_dev_dependency',
        '--platforms=ios',
      ], workingDirectory: tempPluginBDir.path);

      // Add dependency on two plugins: one dependency, one dev dependency.
      await processManager.run(<String>[
        flutterBin,
        'pub',
        'add',
        'plugin_a_real_dependency',
        '--path',
        pluginAPath,
      ], workingDirectory: tempProjectDir.path);

      await processManager.run(<String>[
        flutterBin,
        'pub',
        'add',
        'dev:plugin_b_dev_dependency',
        '--path',
        pluginBPath,
      ], workingDirectory: tempProjectDir.path);

      // Run `flutter pub get` to generate .flutter-plugins-dependencies.
      await processManager.run(<String>[
        flutterBin,
        '--no-implicit-pubspec-resolution',
        'pub',
        'get',
      ], workingDirectory: tempProjectDir.path);

      final File flutterPluginsDependenciesFile = tempProjectDir.childFile(
        '.flutter-plugins-dependencies',
      );
      expect(flutterPluginsDependenciesFile, exists);
      expect(flutterPluginsListHasDevDependencies(flutterPluginsDependenciesFile), isTrue);

      // Check that .flutter-plugin-dependencies denotes the dependency and
      // dev dependency as expected.
      final String pluginsString = flutterPluginsDependenciesFile.readAsStringSync();
      final jsonContent = json.decode(pluginsString) as Map<String, dynamic>;
      final plugins = jsonContent['plugins'] as Map<String, dynamic>;

      // Loop through all platforms supported by default to verify that the
      // dependency and dev dependency are handled appropriately.
      final platformsToVerify = <String>['ios', 'android', 'windows', 'linux', 'macos', 'web'];

      for (final platform in platformsToVerify) {
        final pluginsForPlatform = plugins[platform] as List<dynamic>;

        for (final dynamic plugin in pluginsForPlatform) {
          final pluginProperties = plugin as Map<String, dynamic>;
          final pluginName = pluginProperties['name'] as String;
          final pluginIsDevDependency = pluginProperties['dev_dependency'] as bool;

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
    },
  );

  test('flutterPluginsListHasDevDependencies returns false if no dev dependencies', () async {
    final Directory tempDir = createResolvedTempDirectorySync(
      'flutter_plugins_list_has_dev_dependencies_test.',
    );
    final Directory tempProjectDir = tempDir.childDirectory('project')..createSync();
    final Directory tempPluginADir = tempDir.childDirectory('plugin_a')..createSync();

    addTearDown(() {
      tryToDelete(tempDir);
    });

    // Create Flutter project.
    await processManager.run(<String>[
      flutterBin,
      'create',
      tempProjectDir.path,
      '--project-name=testapp',
    ], workingDirectory: tempProjectDir.path);

    final File pubspecFile = tempProjectDir.childFile('pubspec.yaml');
    expect(pubspecFile.existsSync(), true);

    // Create a Flutter plugin to add as a dependency to the Flutter project.
    final pluginAPath = '${tempPluginADir.path}/plugin_a_real_dependency';

    await processManager.run(<String>[
      flutterBin,
      'create',
      pluginAPath,
      '--template=plugin',
      '--project-name=plugin_a_real_dependency',
      '--platforms=ios',
    ], workingDirectory: tempPluginADir.path);

    // Add dependency on the plugin.
    await processManager.run(<String>[
      flutterBin,
      'pub',
      'add',
      'plugin_a_real_dependency',
      '--path',
      pluginAPath,
    ], workingDirectory: tempProjectDir.path);

    // Run `flutter pub get` to generate .flutter-plugins-dependencies.
    await processManager.run(<String>[
      flutterBin,
      '--no-implicit-pubspec-resolution',
      'pub',
      'get',
    ], workingDirectory: tempProjectDir.path);

    final File flutterPluginsDependenciesFile = tempProjectDir.childFile(
      '.flutter-plugins-dependencies',
    );
    expect(flutterPluginsDependenciesFile, exists);
    expect(flutterPluginsListHasDevDependencies(flutterPluginsDependenciesFile), isFalse);
  });

  test('flutterPluginsListHasDevDependencies ignores Dart package dev dependency', () async {
    final Directory tempDir = createResolvedTempDirectorySync(
      'flutter_plugins_list_ignores_dart_dev_dependency_test.',
    );
    final Directory tempProjectDir = tempDir.childDirectory('project')..createSync();
    final Directory tempPackageADir = tempDir.childDirectory('package_a')..createSync();

    addTearDown(() {
      tryToDelete(tempDir);
    });

    // Create Flutter project.
    await processManager.run(<String>[
      flutterBin,
      'create',
      tempProjectDir.path,
      '--project-name=testapp',
    ], workingDirectory: tempProjectDir.path);

    final File pubspecFile = tempProjectDir.childFile('pubspec.yaml');
    expect(pubspecFile.existsSync(), true);

    // Create a pure Dart Flutter plugin to add as a dependency to the Flutter project.
    final packageAPath = '${tempPackageADir.path}/package_a';

    await processManager.run(<String>[
      flutterBin,
      'create',
      packageAPath,
      '--template=plugin',
      '--project-name=package_a',
    ], workingDirectory: tempPackageADir.path);

    // Add a dev dependency on the plugin.
    await processManager.run(<String>[
      flutterBin,
      'pub',
      'add',
      'dev:package_a',
      '--path',
      packageAPath,
    ], workingDirectory: tempProjectDir.path);

    // Run `flutter pub get` to generate .flutter-plugins-dependencies.
    await processManager.run(<String>[
      flutterBin,
      '--no-implicit-pubspec-resolution',
      'pub',
      'get',
    ], workingDirectory: tempProjectDir.path);

    final File flutterPluginsDependenciesFile = tempProjectDir.childFile(
      '.flutter-plugins-dependencies',
    );
    expect(flutterPluginsDependenciesFile, exists);
    expect(flutterPluginsListHasDevDependencies(flutterPluginsDependenciesFile), isFalse);
  });
}
