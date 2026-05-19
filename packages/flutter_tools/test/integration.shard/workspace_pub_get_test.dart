// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;

import 'package:file/file.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:process/process.dart';
import 'package:test/test.dart';

import '../src/common.dart';
import 'isolated/native_assets_test_utils.dart';
import 'test_utils.dart';

void main() {
  if (!platform.isMacOS && !platform.isLinux && !platform.isWindows) {
    return;
  }

  const ProcessManager processManager = LocalProcessManager();

  testWithoutContext('flutter tools correctly skip pub get when resolution is up-to-date in a workspace', () async {
    await inTempDir((Directory tempDir) async {
      final Directory workspaceDir = tempDir.childDirectory('my_workspace');
      final Directory appDir = workspaceDir.childDirectory('packages').childDirectory('my_app');

      // 1. Create workspace root pubspec
      workspaceDir.createSync(recursive: true);
      workspaceDir.childFile('pubspec.yaml').writeAsStringSync('''
name: my_workspace
environment:
  sdk: ^3.10.0-0
workspace:
  - packages/my_app
''');

      // 2. Create sub-package app pubspec and main.dart
      appDir.createSync(recursive: true);
      appDir.childFile('pubspec.yaml').writeAsStringSync('''
name: my_app
environment:
  sdk: ^3.10.0-0
resolution: workspace
dependencies:
  flutter:
    sdk: flutter
''');
      appDir.childDirectory('lib').childFile('main.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('void main() {}');

      // 3. Run initial pub get to resolve the workspace
      final io.ProcessResult getResult = await processManager.run(<String>[
        flutterBin,
        '--verbose',
        'pub',
        'get',
      ], workingDirectory: appDir.path);
      expect(getResult.exitCode, 0, reason: 'Initial pub get failed:\n${getResult.stderr}\n${getResult.stdout}');

      // Validate workspace output structure
      expect(workspaceDir.childDirectory('.dart_tool').childFile('package_config.json').existsSync(), true);
      expect(workspaceDir.childFile('pubspec.lock').existsSync(), true);
      expect(appDir.childDirectory('.dart_tool').childDirectory('pub').childFile('workspace_ref.json').existsSync(), true);

      // 4. Run flutter analyze once to populate any SDK caches/unpacks
      final io.ProcessResult analyzeResultPrep = await processManager.run(<String>[
        flutterBin,
        '--verbose',
        'analyze',
      ], workingDirectory: appDir.path);
      io.stderr.writeln('PREP ANALYZE OUTPUT:\n${analyzeResultPrep.stdout}\n${analyzeResultPrep.stderr}');

      // 5. Run flutter analyze again and verify that it skips pub get
      final io.ProcessResult analyzeResult1 = await processManager.run(<String>[
        flutterBin,
        '--verbose',
        'analyze',
      ], workingDirectory: appDir.path);

      expect(analyzeResult1.exitCode, 0);
      expect(analyzeResult1.stdout.toString(), contains('Skipping pub get: resolution up-to-date.'));
      expect(analyzeResult1.stdout.toString(), isNot(contains('get --example')));

      // 6. Dirty the pubspec to invalidate resolution
      appDir.childFile('pubspec.yaml').writeAsStringSync('''
name: my_app
environment:
  sdk: ^3.10.0-0
resolution: workspace
dependencies:
  flutter:
    sdk: flutter
# Dirty comment to trigger out-of-date resolution
''');

      // 7. Run flutter analyze again and verify it does NOT skip pub get
      final io.ProcessResult analyzeResult2 = await processManager.run(<String>[
        flutterBin,
        '--verbose',
        'analyze',
      ], workingDirectory: appDir.path);

      expect(analyzeResult2.exitCode, 0);
      expect(analyzeResult2.stdout.toString(), isNot(contains('Skipping pub get: resolution up-to-date.')));
      expect(analyzeResult2.stdout.toString(), contains('get --example'));
    });
  });
}
