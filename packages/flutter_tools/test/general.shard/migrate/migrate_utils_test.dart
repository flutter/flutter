// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file/file.dart';
import 'package:file/local.dart';
// import 'package:flutter_tools/src/base/file_system.dart';
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
        ..writeAsStringSync('void main() {}', flush: true);

      final File file2 = projectRoot.childFile('some_file.dart')
        ..createSync()
        ..writeAsStringSync('void main() {}blak', flush: true);

      DiffResult result = await MigrateUtils.diffFiles(file1, file2, logger);
      expect(result.diff, '');
      expect(result.exitCode, 0);

      // print(file2.readAsStringSync());

      // file2.writeAsStringSync('void main() {}\na second line\na third line', flush: true);
      
      // result = await MigrateUtils.diffFiles(file1, file2, logger);
      // expect(result.diff, '');
      // expect(result.exitCode, 1);
    });
  });
}

