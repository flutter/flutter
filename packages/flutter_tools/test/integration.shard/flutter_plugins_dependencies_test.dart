// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
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

  testWithoutContext(
      '.flutter-plugins-dependencies correctly denotes project dev dependencies on iOS, Android',
      () async {
    final String flutterBin =
        fileSystem.path.join(getFlutterRoot(), 'bin', 'flutter');

    await processManager.run(<String>[
      flutterBin,
      'create',
      tempDir.path,
      '--project-name=testapp',
    ], workingDirectory: tempDir.path);

    await processManager.run(<String>[
      flutterBin,
      'packages',
      'get',
    ], workingDirectory: tempDir.path);
    await processManager.run(<String>[
      flutterBin,
      'build',
      'apk',
    ], workingDirectory: tempDir.path);

    final File flutterPluginsDependenciesFile =
        tempDir.childFile('.flutter-plugins-dependencies');
    expect(flutterPluginsDependenciesFile.existsSync(), true);

    // TODO(camsim99): Figure out the rest later:
    final String pluginsString =
        flutterPluginsDependenciesFile.readAsStringSync();
    final Map<String, dynamic> jsonContent =
        json.decode(pluginsString) as Map<String, dynamic>;
    final Map<String, dynamic> plugins =
        jsonContent['plugins'] as Map<String, dynamic>;

    final List<dynamic> expectedPlugins = <dynamic>[
      <String, dynamic>{
        'name': 'flutter',
        // 'path': '${pluginA.path}/',
        'native_build': true,
        // 'dependencies': <String>[
        //   'plugin-b',
        //   'plugin-c',
        // ],
        'dev_dependency': false,
      },
      <String, dynamic>{
        'name': 'flutter_test',
        // 'path': '${pluginB.path}/',
        'native_build': true,
        // 'dependencies': <String>[
        //   'plugin-c',
        // ],
        'dev_dependency': true,
      },
      <String, dynamic>{
        'name': 'flutter_lints',
        // 'path': '${pluginC.path}/',
        'native_build': true,
        // 'dependencies': <String>[],
        'dev_dependency': true,
      },
    ];

    print(plugins['ios']);

    expect(plugins['ios'], expectedPlugins);
    expect(plugins['android'], expectedPlugins);
    expect(plugins['macos'], <dynamic>[]);
    expect(plugins['windows'], <dynamic>[]);
    expect(plugins['linux'], <dynamic>[]);
    expect(plugins['web'], <dynamic>[]);
  });
}
