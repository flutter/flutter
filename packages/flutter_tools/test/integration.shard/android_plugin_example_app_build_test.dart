// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';

import '../src/common.dart';
import 'test_utils.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = createResolvedTempDirectorySync(
      'android_plugin_example_app_build_test.',
    );
  });

  tearDown(() async {
    tryToDelete(tempDir);
  });

  Future<void> testPlugin({
    required String template,
    required Directory tempDir,
  }) async {
    final String flutterBin = fileSystem.path.join(
      getFlutterRoot(),
      'bin',
      'flutter',
    );

    final String testName = '${template}_test';
    ProcessResult result = processManager.runSync(<String>[
      flutterBin,
      ...getLocalEngineArguments(),
      'create',
      '--template=$template',
      '--platforms=android',
      testName,
    ], workingDirectory: tempDir.path);
    expect(result, const ProcessResultMatcher());

    final Directory exampleAppDir =
        tempDir.childDirectory(testName).childDirectory('example');
    result = processManager.runSync(<String>[
      flutterBin,
      ...getLocalEngineArguments(),
      'build',
      'apk',
      '--target-platform=android-arm',
    ], workingDirectory: exampleAppDir.path);
    expect(result, const ProcessResultMatcher());
  }

  test('plugin example builds using the Flutter Gradle plugin', () async {
    await testPlugin(
      template: 'plugin',
      tempDir: tempDir,
    );
  });

  test('FFI plugin example builds using the Flutter Gradle plugin', () async {
    await testPlugin(
      template: 'plugin_ffi',
      tempDir: tempDir,
    );
  });
}
