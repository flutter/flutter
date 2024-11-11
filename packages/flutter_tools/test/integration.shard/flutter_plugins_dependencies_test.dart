// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'package:file/file.dart';

import '../src/common.dart';
import 'test_utils.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir =
        createResolvedTempDirectorySync('flutter_plugins_dependencies_test.');
  });

  tearDown(() async {
    tryToDelete(tempDir);
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
      tempDir.path,
      '--project-name=testapp',
    ], workingDirectory: tempDir.path);

    final File pubspecFile = tempDir.childFile('pubspec.yaml');
    expect(pubspecFile.existsSync(), true);
    String pubspecFileAsString = pubspecFile.readAsStringSync();

    // Add dependency on two plugin: one dependency, one dev dependency.
    final RegExp pubspecDependenciesRegExp = RegExp('\ndependencies:\n');
    final RegExp pubspecDevDependenciesRegExp = RegExp('dev_dependencies:\n');
    expect(pubspecDependenciesRegExp.hasMatch(pubspecFileAsString), isTrue);
    expect(pubspecDevDependenciesRegExp.hasMatch(pubspecFileAsString), isTrue);

    const String pubspecDependenciesWithCameraAdded = '''
\ndependencies:
  camera: 0.11.0
''';
    const String pubspecDevDependenciesWithVideoPlayerAdded = '''
dev_dependencies:
  video_player: 2.9.2
''';

    pubspecFileAsString = pubspecFileAsString.replaceFirst(
        pubspecDependenciesRegExp, pubspecDependenciesWithCameraAdded);
    pubspecFileAsString = pubspecFileAsString.replaceFirst(
        pubspecDevDependenciesRegExp,
        pubspecDevDependenciesWithVideoPlayerAdded);
    pubspecFile.writeAsStringSync(pubspecFileAsString);

    // Run `flutter pub get` to generate .flutter-plugins-dependencies.
    await processManager.run(<String>[
      flutterBin,
      'pub',
      'get',
    ], workingDirectory: tempDir.path);

    final File flutterPluginsDependenciesFile =
        tempDir.childFile('.flutter-plugins-dependencies');
    expect(flutterPluginsDependenciesFile.existsSync(), true);

    // Check that .flutter-plugin-dependencies denotes dependencies and
    // dev dependencies as expected.
    final String pluginsString =
        flutterPluginsDependenciesFile.readAsStringSync();
    final Map<String, dynamic> jsonContent =
        json.decode(pluginsString) as Map<String, dynamic>;
    final Map<String, dynamic> plugins =
        jsonContent['plugins'] as Map<String, dynamic>;

    // No project plugins run on Windows, Linux.
    expect(plugins['windows'], <dynamic>[]);
    expect(plugins['linux'], <dynamic>[]);

    // camera, video_player, and transitive dependencies run on Android, iOS,
    // macOS, and web, so we verify on these platforms only.
    final List<String> platformsToVerify = <String>[
      'android',
      'ios',
      'macos',
      'web'
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
        if (pluginName.startsWith('camera_')) {
          expect(pluginIsDevDependency, isFalse);
        }

        // Check video_player dependencies are marked as dev dependencies.
        if (pluginName.startsWith('video_player_')) {
          expect(pluginIsDevDependency, isTrue);
        }

        // video_player brings in transitive dependncy
        // flutter_plugin_android_lifecycle, so ensure it is marked as a
        // dev dependency.
        if (pluginName == 'flutter_plugin_android_lifecycle') {
          expect(pluginIsDevDependency, isTrue);
        }
      }
    }
  });
}
