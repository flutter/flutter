// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/cache.dart';

import '../commands.shard/permeable/utils/project_testing_utils.dart';
import '../src/common.dart';
import 'test_utils.dart';

void main() {
  late Directory tempDir;
  late Directory projectRoot;

  setUpAll(() async {
    Cache.disableLocking();
    await ensureFlutterToolsSnapshot();
    tempDir = createResolvedTempDirectorySync('create_linux_gtk4_build_test.');
    await _runFlutterSnapshot(<String>[
      'create',
      '--platforms=linux',
      '--linux-gtk=gtk4',
      'hello',
    ], tempDir);
    projectRoot = tempDir.childDirectory('hello');
  });

  tearDownAll(() async {
    tryToDelete(tempDir);
    await restoreFlutterToolsSnapshot();
  });

  test(
    'flutter create generates a GTK4 Linux project',
    () async {
      final File cmakeFile = projectRoot.childDirectory('linux').childFile('CMakeLists.txt');
      expect(cmakeFile, exists);
      expect(
        cmakeFile.readAsStringSync(),
        contains('pkg_check_modules(GTK REQUIRED IMPORTED_TARGET gtk4)'),
      );

      final File pubspec = projectRoot.childFile('pubspec.yaml');
      expect(
        pubspec.readAsStringSync(),
        contains('linux-gtk-default: gtk4'),
      );
    },
    skip: !platform.isLinux, // [intended] Linux builds only work on Linux.
  );
}

Future<void> _runFlutterSnapshot(List<String> flutterCommandArgs, Directory workingDir) async {
  final String flutterRoot = fileSystem.path.normalize(
    fileSystem.path.join(fileSystem.currentDirectory.path, '..', '..'),
  );
  final String dartBinary = fileSystem.path.join(
    flutterRoot,
    'bin',
    'cache',
    'dart-sdk',
    'bin',
    platform.isWindows ? 'dart.exe' : 'dart',
  );
  final String flutterToolsSnapshotPath = fileSystem.path.join(
    flutterRoot,
    'bin',
    'cache',
    'flutter_tools.snapshot',
  );

  final List<String> args = <String>[
    dartBinary,
    flutterToolsSnapshotPath,
    ...getLocalEngineArguments(),
    ...flutterCommandArgs,
  ];

  final ProcessResult exec = await processManager.run(args, workingDirectory: workingDir.path);
  expect(exec, const ProcessResultMatcher());
}
