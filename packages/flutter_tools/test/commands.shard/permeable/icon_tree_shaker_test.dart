// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;

import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/globals.dart' as globals;

import '../../src/common.dart';
import '../../src/context.dart';
import 'utils/project_testing_utils.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = globals.fs.systemTempDirectory.createTempSync('flutter_tree_shaker_test.');
    await ensureFlutterToolsSnapshot();
  });

  tearDown(() async {
    tryToDelete(tempDir);
    await restoreFlutterToolsSnapshot();
  });

  testUsingContext('tool_backend.dart tree shakes icons successfully', () async {
    final String flutterRoot = Cache.flutterRoot!;
    final String flutterBin = globals.fs.path.join(
      flutterRoot,
      'bin',
      io.Platform.isWindows ? 'flutter.bat' : 'flutter',
    );
    final String engineDartBin = globals.artifacts!.getArtifactPath(Artifact.engineDartBinary);
    final String toolBackend = globals.fs.path.join(
      flutterRoot,
      'packages',
      'flutter_tools',
      'bin',
      'tool_backend.dart',
    );

    // 1. flutter create
    final io.ProcessResult createResult = await io.Process.run(
      flutterBin,
      <String>['create', '--no-pub', 'dummy_app'],
      workingDirectory: tempDir.path,
      environment: <String, String>{...io.Platform.environment, 'FLUTTER_ROOT': flutterRoot},
    );
    expect(createResult.exitCode, 0, reason: 'flutter create failed: ${createResult.stderr}');

    final String projectDir = globals.fs.path.join(tempDir.path, 'dummy_app');

    // 2. Add a single icon reference to main.dart
    final File mainDart = globals.fs.file(globals.fs.path.join(projectDir, 'lib', 'main.dart'));
    mainDart.writeAsStringSync('''
import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(
    home: Icon(Icons.add),
  ));
}
''');

    // 3. Run pub get
    final io.ProcessResult pubResult = await io.Process.run(
      flutterBin,
      <String>['pub', 'get'],
      workingDirectory: projectDir,
      environment: <String, String>{...io.Platform.environment, 'FLUTTER_ROOT': flutterRoot},
    );
    expect(pubResult.exitCode, 0, reason: 'flutter pub get failed: ${pubResult.stderr}');

    // 4. Determine target platform
    var targetPlatform = 'windows-x64';
    if (io.Platform.isLinux) {
      targetPlatform = 'linux-x64';
    } else if (io.Platform.isMacOS) {
      targetPlatform = 'darwin';
    }

    // 5. Run tool_backend.dart
    final io.ProcessResult toolBackendResult = await io.Process.run(
      engineDartBin,
      <String>[toolBackend, targetPlatform, 'release'],
      workingDirectory: projectDir,
      environment: <String, String>{
        ...io.Platform.environment,
        'PROJECT_DIR': projectDir,
        'FLUTTER_ROOT': flutterRoot,
        'TREE_SHAKE_ICONS': 'true',
      },
    );
    expect(
      toolBackendResult.exitCode,
      0,
      reason: 'tool_backend.dart failed: ${toolBackendResult.stderr}',
    );

    // 6. Verify font size
    final String fontPath = io.Platform.isMacOS
        ? globals.fs.path.join(
            projectDir,
            'build',
            'App.framework',
            'Versions',
            'A',
            'Resources',
            'flutter_assets',
            'fonts',
            'MaterialIcons-Regular.otf',
          )
        : globals.fs.path.join(
            projectDir,
            'build',
            'flutter_assets',
            'fonts',
            'MaterialIcons-Regular.otf',
          );

    final File shakenFont = globals.fs.file(fontPath);
    expect(shakenFont.existsSync(), isTrue);
    final int size = shakenFont.lengthSync();

    // Full font is about 1.6MB (1645184 bytes). Shaken font should be much smaller (< 10KB).
    expect(
      size,
      lessThan(10000),
      reason: 'Font file size ($size bytes) suggests tree shaking was not applied.',
    );
  });
}
