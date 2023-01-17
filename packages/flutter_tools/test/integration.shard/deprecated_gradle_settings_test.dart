// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/base/io.dart';

import '../src/common.dart';
import 'test_utils.dart';

/// Tests that apps can be built using the deprecated `android/settings.gradle` file.
/// This test should be removed once apps have been migrated to this new file.
// TODO(egarciad): Migrate existing files, https://github.com/flutter/flutter/issues/54566
void main() {
  test('android project using deprecated settings.gradle will still build', () async {
    final String woringDirectory = fileSystem.path.join(getFlutterRoot(), 'dev', 'integration_tests', 'gradle_deprecated_settings');
    final String flutterBin = fileSystem.path.join(getFlutterRoot(), 'bin', 'flutter');

    final ProcessResult result = await processManager.run(<String>[
      flutterBin,
      'build',
      'apk',
      '--debug',
      '--target-platform', 'android-arm',
      '--verbose',
    ], workingDirectory: woringDirectory);

    printOnFailure('Output of flutter build apk:');
    printOnFailure(result.stdout.toString());
    printOnFailure(result.stderr.toString());

    expect(result.exitCode, 0);

    final String apkPath = fileSystem.path.join(
      woringDirectory, 'build', 'app', 'outputs', 'flutter-apk', 'app-debug.apk');
    expect(fileSystem.file(apkPath), exists);
  });
}
