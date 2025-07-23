// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:flutter_tools/src/android/gradle_utils.dart' show getGradlewFileName;
import 'package:flutter_tools/src/base/io.dart';

import '../src/common.dart';
import 'test_utils.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = createResolvedTempDirectorySync('bundletool_test.');
  });

  tearDown(() {
    tryToDelete(tempDir);
  });

  testWithoutContext('bundletool gradle task executes and contains help text', () async {
    // Create a new flutter project.
    ProcessResult result = await processManager.run(<String>[
      flutterBin,
      'create',
      tempDir.path,
      '--project-name=testapp',
    ], workingDirectory: tempDir.path);
    expect(result.exitCode, 0);
    // Ensure that gradle files exists from templates.
    result = await processManager.run(<String>[
      flutterBin,
      'build',
      'apk',
      '--config-only',
    ], workingDirectory: tempDir.path);
    expect(result.exitCode, 0);

    final Directory androidApp = tempDir.childDirectory('android');
    result = await processManager.run(<String>[
      '.${platform.pathSeparator}${getGradlewFileName(platform)}',
      ...getLocalEngineArguments(),
      '-q',
      ':gradle:bundleTool',
      '--args=help',
    ], workingDirectory: androidApp.path);
    expect(result.exitCode, 0);
    // Ensure bundletool is installed and can be invoked.
    expect(result.stdout.toString(), contains("Use 'bundletool help"));
  });
}
