// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:file/file.dart';
import 'package:flutter_tools/src/android/gradle_utils.dart' show getGradlewFileName;
import 'package:flutter_tools/src/base/io.dart';

import '../src/common.dart';
import 'test_utils.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = createResolvedTempDirectorySync('run_test.');
  });

  tearDown(() async {
    tryToDelete(tempDir);
  });

  testWithoutContext(
    'gradle task exists named printNdkVersion that prints the effective ndk version',
    () async {
      ProcessResult result = await processManager.run(<String>[
        flutterBin,
        'create',
        tempDir.path,
        '--project-name=testapp',
      ], workingDirectory: tempDir.path);
      expect(result.exitCode, 0, reason: 'stdout: ${result.stdout}\nstderr: ${result.stderr}');

      result = await processManager.run(<String>[
        flutterBin,
        'build',
        'apk',
        '--config-only',
      ], workingDirectory: tempDir.path);
      expect(result.exitCode, 0, reason: 'stdout: ${result.stdout}\nstderr: ${result.stderr}');

      final Directory androidApp = tempDir.childDirectory('android');
      result = await processManager.run(<String>[
        '.${platform.pathSeparator}${getGradlewFileName(platform)}',
        ...getLocalEngineArguments(),
        '-q',
        'printNdkVersion',
      ], workingDirectory: androidApp.path);
      expect(result.exitCode, 0);

      final List<String> actualLines = LineSplitter.split(result.stdout.toString()).toList();
      final Iterable<String> ndkVersionLines = actualLines.where(
        (String line) => line.startsWith('NdkVersion: '),
      );
      expect(ndkVersionLines.length, 1, reason: 'actual: $actualLines');
      expect(
        ndkVersionLines.single.length,
        greaterThan('NdkVersion: '.length),
        reason: 'actual: $actualLines',
      );
    },
  );
}
