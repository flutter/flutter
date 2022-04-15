// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/migrate/migrate_utils.dart';
import 'package:flutter_tools/src/globals.dart' as globals;

import '../../src/common.dart';

void main() {
  late BufferLogger logger;
  late FileSystem fileSystem;
  late Directory projectRoot;
  late String projectRootPath;

  setUpAll(() async {
    fileSystem = LocalFileSystem();
    logger = BufferLogger.test();
  });

  group('git', () {
    setUp(() async {
      projectRoot = fileSystem.systemTempDirectory.createTempSync('flutter_migrate_utils_test');;
      projectRoot.createSync(recursive: true);
      projectRootPath = projectRoot.path;
    });

    testWithoutContext('init', () async {
      expect(projectRoot.existsSync(), true);
      expect(projectRoot.childDirectory('.git').existsSync(), false);
      await MigrateUtils.gitInit(projectRootPath, logger);
      expect(projectRoot.childDirectory('.git').existsSync(), true);
    });

    testWithoutContext('isGitIgnored', () async {
      expect(projectRoot.existsSync(), true);
      expect(projectRoot.childDirectory('.git').existsSync(), false);
      await MigrateUtils.gitInit(projectRootPath, logger);
      expect(projectRoot.childDirectory('.git').existsSync(), true);

      projectRoot.childFile('.gitignore')
        ..createSync()
        ..writeAsStringSync('ignored_file.dart', flush: true);

      expect(await MigrateUtils.isGitIgnored('ignored_file.dart', projectRootPath, logger), true);
      expect(await MigrateUtils.isGitIgnored('other_file.dart', projectRootPath, logger), false);
    });

    testWithoutContext('isGitRepo', () async {
      expect(projectRoot.existsSync(), true);
      expect(projectRoot.childDirectory('.git').existsSync(), false);
      expect(await MigrateUtils.isGitRepo(projectRootPath, logger), false);
      await MigrateUtils.gitInit(projectRootPath, logger);
      expect(projectRoot.childDirectory('.git').existsSync(), true);
      expect(await MigrateUtils.isGitRepo(projectRootPath, logger), true);
    });

    testWithoutContext('hasUncommitedChanges', () async {
      expect(projectRoot.existsSync(), true);
      expect(projectRoot.childDirectory('.git').existsSync(), false);
      await MigrateUtils.gitInit(projectRootPath, logger);
      expect(projectRoot.childDirectory('.git').existsSync(), true);

      projectRoot.childFile('some_file.dart')
        ..createSync()
        ..writeAsStringSync('void main() {}', flush: true);

      expect(await MigrateUtils.hasUncommitedChanges(projectRootPath, logger), true);
    });

    testWithoutContext('diffFiles', () async {
      expect(projectRoot.existsSync(), true);
      expect(projectRoot.childDirectory('.git').existsSync(), false);
      await MigrateUtils.gitInit(projectRootPath, logger);
      expect(projectRoot.childDirectory('.git').existsSync(), true);

      final File file1 = projectRoot.childFile('some_file.dart')
        ..createSync()
        ..writeAsStringSync('void main() {}\n', flush: true);

      final File file2 = projectRoot.childFile('some_other_file.dart');

      DiffResult result = await MigrateUtils.diffFiles(file1, file2, logger);
      expect(result.diff, '');
      expect(result.isAddition, false);
      expect(result.isIgnored, false);
      expect(result.isDeletion, true);
      expect(result.exitCode, 0);

      result = await MigrateUtils.diffFiles(file2, file1, logger);
      expect(result.diff, '');
      expect(result.isAddition, true);
      expect(result.isIgnored, false);
      expect(result.isDeletion, false);
      expect(result.exitCode, 0);

      file2.createSync();
      file2.writeAsStringSync('void main() {}\n', flush: true);

      result = await MigrateUtils.diffFiles(file1, file2, logger);
      expect(result.diff, '');
      expect(result.isAddition, false);
      expect(result.isIgnored, false);
      expect(result.isDeletion, false);
      expect(result.exitCode, 0);

      file2.writeAsStringSync('void main() {}\na second line\na third line\n', flush: true);

      result = await MigrateUtils.diffFiles(file1, file2, logger);
      expect(result.diff, contains('@@ -1 +1,3 @@\n void main() {}\n+a second line\n+a third line'));
      expect(result.isAddition, false);
      expect(result.isIgnored, false);
      expect(result.isDeletion, false);
      expect(result.exitCode, 1);
    });

    testWithoutContext('merge', () async {
      expect(projectRoot.existsSync(), true);
      expect(projectRoot.childDirectory('.git').existsSync(), false);
      await MigrateUtils.gitInit(projectRootPath, logger);
      expect(projectRoot.childDirectory('.git').existsSync(), true);

      final File file1 = projectRoot.childFile('some_file.dart');
      file1.createSync();
      file1.writeAsStringSync('void main() {}\n\nline1\nline2\nline3\nline4\nline5\n', flush: true);
      final File file2 = projectRoot.childFile('some_other_file.dart');
      file2.createSync();
      file2.writeAsStringSync('void main() {}\n\nline1\nline2\nline3.0\nline3.5\nline4\nline5\n', flush: true);
      final File file3 = projectRoot.childFile('some_other_third_file.dart');
      file3.createSync();
      file3.writeAsStringSync('void main() {}\n\nline2\nline3\nline4\nline5\n', flush: true);

      MergeResult result = await MigrateUtils.gitMergeFile(
        base: file1.path,
        current: file2.path,
        target: file3.path,
        localPath: 'some_file.dart',
        logger: logger,
      );
      expect(result.mergedString, 'void main() {}\n\nline2\nline3.0\nline3.5\nline4\nline5\n');
      expect(result.hasConflict, false);
      expect(result.exitCode, 0);

      file3.writeAsStringSync('void main() {}\n\nline1\nline2\nline3.1\nline3.5\nline4\nline5\n', flush: true);

      result = await MigrateUtils.gitMergeFile(
        base: file1.path,
        current: file2.path,
        target: file3.path,
        localPath: 'some_file.dart',
        logger: logger,
      );
      expect(result.mergedString, contains('line3.0\n=======\nline3.1\n>>>>>>>'));
      expect(result.hasConflict, true);
      expect(result.exitCode, 1);
    });
  });

  group('DiffResult', () {
    testWithoutContext('init works', () async {
      DiffResult result = DiffResult.addition();
      expect(result.diff, '');
      expect(result.isAddition, true);
      expect(result.isIgnored, false);
      expect(result.isDeletion, false);
      expect(result.exitCode, 0);

      result = DiffResult.deletion();
      expect(result.diff, '');
      expect(result.isAddition, false);
      expect(result.isIgnored, false);
      expect(result.isDeletion, true);
      expect(result.exitCode, 0);

      result = DiffResult.ignored();
      expect(result.diff, '');
      expect(result.isAddition, false);
      expect(result.isIgnored, true);
      expect(result.isDeletion, false);
      expect(result.exitCode, 0);
    });
  });
}
