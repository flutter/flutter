// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';

import '../src/common.dart';
import 'test_utils.dart';

void main() {
  /// Verifies that `dart migrate` will run successfully on the default `flutter create`
  /// template.
  testWithoutContext('dart migrate succeeds on flutter create template', () async {
    Directory tempDir;
    try {
      tempDir = await _createProject(tempDir);
      await _migrate(tempDir);
      await _analyze(tempDir);
    } finally {
      tempDir?.deleteSync(recursive: true);
    }
  });

  /// Verifies that `dart migrate` will run successfully on the module template
  /// used by `flutter create --template=module`.
  testWithoutContext('dart migrate succeeds on module template', () async {
    Directory tempDir;
    try {
      tempDir = await _createProject(tempDir, <String>['--template=module']);
      await _migrate(tempDir);
      await _analyze(tempDir);
    } finally {
      tempDir?.deleteSync(recursive: true);
    }
  }, timeout: const Timeout(Duration(minutes: 1)));

  /// Verifies that `dart migrate` will run successfully on the module template
  /// used by `flutter create --template=plugin`.
  testWithoutContext('dart migrate succeeds on plugin template', () async {
    Directory tempDir;
    try {
      tempDir = await _createProject(tempDir, <String>['--template=plugin']);
      await _migrate(tempDir);
      await _analyze(tempDir);
    } finally {
      tempDir?.deleteSync(recursive: true);
    }
  });

  /// Verifies that `dart migrate` will run successfully on the module template
  /// used by `flutter create --template=package`.
  testWithoutContext('dart migrate succeeds on package template', () async {
    Directory tempDir;
    try {
      tempDir = await _createProject(tempDir, <String>['--template=package']);
      await _migrate(tempDir);
      await _analyze(tempDir);
    } finally {
      tempDir?.deleteSync(recursive: true);
    }
  });
}

Future<Directory> _createProject(Directory tempDir, [List<String> extraAgs]) async {
  tempDir = createResolvedTempDirectorySync('dart_migrate_test.');
  final ProcessResult createResult = await processManager.run(<String>[
    _flutterBin,
    'create',
    if (extraAgs != null)
      ...extraAgs,
    'foo',
  ], workingDirectory: tempDir.path);
  if (createResult.exitCode != 0) {
    fail('flutter create did not work: ${createResult.stdout}${createResult.stderr}');
  }
  return tempDir;
}

Future<void> _migrate(Directory tempDir) async {
  final ProcessResult migrateResult = await processManager.run(<String>[
    _dartBin,
    'migrate',
    '--apply-changes',
  ], workingDirectory: fileSystem.path.join(tempDir.path, 'foo'));
  if (migrateResult.exitCode != 0) {
    fail('dart migrate did not work: ${migrateResult.stdout}${migrateResult.stderr}');
  }
}

Future<void> _analyze(Directory tempDir) async {
  final ProcessResult analyzeResult = await processManager.run(<String>[
    _flutterBin,
    'analyze',
  ], workingDirectory: fileSystem.path.join(tempDir.path, 'foo'));
  if (analyzeResult.exitCode != 0) {
    fail('flutter analyze had errors: ${analyzeResult.stdout}${analyzeResult.stderr}');
  }
}

String get _flutterBin => fileSystem.path.join(getFlutterRoot(), 'bin', platform.isWindows ? 'flutter.bat' : 'flutter');
String get _dartBin => fileSystem.path.join(getFlutterRoot(), 'bin', platform.isWindows ? 'dart.bat' : 'dart');
