// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';

import '../src/common.dart';
import 'test_utils.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = createResolvedTempDirectorySync('flutter_plugin_test.');
  });

  tearDown(() async {
    tryToDelete(tempDir);
  });

  // Regression test for https://github.com/flutter/flutter/issues/169215 and
  // https://github.com/flutter/flutter/issues/196412.
  test('app build type with applicationIdSuffix builds with a library plugin', () async {
    final ProcessResult createResult = processManager.runSync(<String>[
      flutterBin,
      ...getLocalEngineArguments(),
      'create',
      '--template=plugin',
      '--platforms=android',
      'test_plugin',
    ], workingDirectory: tempDir.path);
    expect(createResult, const ProcessResultMatcher());

    final Directory exampleAppDir = tempDir.childDirectory('test_plugin').childDirectory('example');
    final File appGradleFile = exampleAppDir
        .childDirectory('android')
        .childDirectory('app')
        .childFile('build.gradle.kts');
    expect(appGradleFile, exists);

    // The plugin does not define a profile build type, so the Flutter Gradle
    // Plugin copies the app's profile build type onto the plugin.
    appGradleFile.writeAsStringSync('''
${appGradleFile.readAsStringSync()}

android {
    buildTypes {
        getByName("profile") {
            applicationIdSuffix = ".profile"
            versionNameSuffix = "-PROFILE"
        }
    }
}
''');

    final ProcessResult buildResult = processManager.runSync(<String>[
      flutterBin,
      ...getLocalEngineArguments(),
      'build',
      'apk',
      '--debug',
      '--target-platform=android-arm64',
    ], workingDirectory: exampleAppDir.path);

    expect(buildResult.stderr, isNot(contains('Library projects cannot set applicationIdSuffix')));
    expect(buildResult, const ProcessResultMatcher());
  });
}
