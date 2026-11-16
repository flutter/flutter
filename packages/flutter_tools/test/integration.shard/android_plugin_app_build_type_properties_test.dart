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
  testWithoutContext(
    'app build types with app-only properties build with a library plugin',
    () async {
      final ProcessResult createResult = processManager.runSync(<String>[
        flutterBin,
        ...getLocalEngineArguments(),
        'create',
        '--template=plugin',
        '--platforms=android',
        'test_plugin',
      ], workingDirectory: tempDir.path);
      expect(createResult, const ProcessResultMatcher());

      final Directory exampleAppDir = tempDir
          .childDirectory('test_plugin')
          .childDirectory('example');
      final File appGradleFile = exampleAppDir
          .childDirectory('android')
          .childDirectory('app')
          .childFile('build.gradle.kts');
      expect(appGradleFile, exists);

      // The plugin defines neither build type, so the Flutter Gradle Plugin
      // creates both on the plugin. A library can't use any of these settings:
      // applicationIdSuffix and isShrinkResources are app-only, and the plugin
      // doesn't enable the buildConfig or resValues build features.
      appGradleFile.writeAsStringSync('''
${appGradleFile.readAsStringSync()}

android {
    buildFeatures {
        buildConfig = true
        resValues = true
    }
    buildTypes {
        getByName("profile") {
            applicationIdSuffix = ".profile"
            versionNameSuffix = "-PROFILE"
            buildConfigField("String", "BUILD_TYPE_NOTE", "\\"profile\\"")
            resValue("string", "build_type_note", "profile")
        }
        create("staging") {
            initWith(getByName("release"))
            isMinifyEnabled = true
            isShrinkResources = true
        }
    }
}
''');

      // Gradle configures every build type of every project, so a debug build
      // is enough to catch build types that AGP rejects in the plugin.
      final ProcessResult buildResult = processManager.runSync(<String>[
        flutterBin,
        ...getLocalEngineArguments(),
        'build',
        'apk',
        '--debug',
        '--target-platform=android-arm64',
      ], workingDirectory: exampleAppDir.path);

      expect(
        buildResult.stderr,
        isNot(contains('Library projects cannot set applicationIdSuffix')),
      );
      expect(buildResult.stderr, isNot(contains('Resource shrinker cannot be used for libraries')));
      expect(buildResult, const ProcessResultMatcher());
    },
  );
}
