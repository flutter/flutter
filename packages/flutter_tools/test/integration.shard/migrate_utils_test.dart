// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:async';
import 'dart:convert';

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/process.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/migrate/migrate_utils.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:platform/platform.dart';

import '../src/common.dart';
import '../src/context.dart';

void main() {
  BufferLogger logger;
  FileSystem fileSystem;
  Directory projectRoot;
  String projectRootPath;
  MigrateUtils utils;

  setUpAll(() async {
    fileSystem = LocalFileSystem();
    logger = BufferLogger.test();
    utils = MigrateUtils(
      logger: logger,
      fileSystem: fileSystem,
      platform: FakePlatform(),
      processManager: globals.processManager,
    );
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
      await utils.gitInit(projectRootPath);
      expect(projectRoot.childDirectory('.git').existsSync(), true);
    });

    testWithoutContext('isGitIgnored', () async {
      expect(projectRoot.existsSync(), true);
      expect(projectRoot.childDirectory('.git').existsSync(), false);
      await utils.gitInit(projectRootPath);
      expect(projectRoot.childDirectory('.git').existsSync(), true);

      projectRoot.childFile('.gitignore')
        ..createSync()
        ..writeAsStringSync('ignored_file.dart', flush: true);

      expect(await utils.isGitIgnored('ignored_file.dart', projectRootPath), true);
      expect(await utils.isGitIgnored('other_file.dart', projectRootPath), false);
    });

    testWithoutContext('isGitRepo', () async {
      expect(projectRoot.existsSync(), true);
      expect(projectRoot.childDirectory('.git').existsSync(), false);
      expect(await utils.isGitRepo(projectRootPath), false);
      await utils.gitInit(projectRootPath);
      expect(projectRoot.childDirectory('.git').existsSync(), true);
      expect(await utils.isGitRepo(projectRootPath), true);
    });

    testWithoutContext('hasUncommitedChanges', () async {
      expect(projectRoot.existsSync(), true);
      expect(projectRoot.childDirectory('.git').existsSync(), false);
      await utils.gitInit(projectRootPath);
      expect(projectRoot.childDirectory('.git').existsSync(), true);

      projectRoot.childFile('some_file.dart')
        ..createSync()
        ..writeAsStringSync('void main() {}', flush: true);

      expect(await utils.hasUncommitedChanges(projectRootPath), true);
    });

    testWithoutContext('diffFiles', () async {
      expect(projectRoot.existsSync(), true);
      expect(projectRoot.childDirectory('.git').existsSync(), false);
      await utils.gitInit(projectRootPath);
      expect(projectRoot.childDirectory('.git').existsSync(), true);

      final File file1 = projectRoot.childFile('some_file.dart')
        ..createSync()
        ..writeAsStringSync('void main() {}\n', flush: true);

      final File file2 = projectRoot.childFile('some_other_file.dart');

      DiffResult result = await utils.diffFiles(file1, file2);
      expect(result.diff, null);
      expect(result.diffType, DiffType.deletion);
      expect(result.exitCode, null);

      result = await utils.diffFiles(file2, file1);
      expect(result.diff, null);
      expect(result.diffType, DiffType.addition);
      expect(result.exitCode, null);

      file2.createSync();
      file2.writeAsStringSync('void main() {}\n', flush: true);

      result = await utils.diffFiles(file1, file2);
      expect(result.diff, '');
      expect(result.diffType, DiffType.modification);
      expect(result.exitCode, 0);

      file2.writeAsStringSync('void main() {}\na second line\na third line\n', flush: true);

      result = await utils.diffFiles(file1, file2);
      expect(result.diff, contains('@@ -1 +1,3 @@\n void main() {}\n+a second line\n+a third line'));
      expect(result.diffType, DiffType.modification);
      expect(result.exitCode, 1);
    });

    testWithoutContext('merge', () async {
      expect(projectRoot.existsSync(), true);
      expect(projectRoot.childDirectory('.git').existsSync(), false);
      await utils.gitInit(projectRootPath);
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

      StringMergeResult result = await utils.gitMergeFile(
        base: file1.path,
        current: file2.path,
        target: file3.path,
        localPath: 'some_file.dart',
      ) as StringMergeResult;

      expect(result.mergedString, 'void main() {}\n\nline2\nline3.0\nline3.5\nline4\nline5\n');
      expect(result.hasConflict, false);
      expect(result.exitCode, 0);

      file3.writeAsStringSync('void main() {}\n\nline1\nline2\nline3.1\nline3.5\nline4\nline5\n', flush: true);

      result = await utils.gitMergeFile(
        base: file1.path,
        current: file2.path,
        target: file3.path,
        localPath: 'some_file.dart',
      ) as StringMergeResult;

      expect(result.mergedString, contains('line3.0\n=======\nline3.1\n>>>>>>>'));
      expect(result.hasConflict, true);
      expect(result.exitCode, 1);
    });
  });

  group('legacy app creation', () {
    testWithoutContext('clone and create', () async {
      projectRoot = fileSystem.systemTempDirectory.createTempSync('flutter_sdk_test');
      final String revision = '5391447fae6209bb21a89e6a5a6583cac1af9b4b';

      expect(await utils.cloneFlutter(revision, projectRoot.path), true);
      expect(projectRoot.childFile('README.md').existsSync(), true);

      final Directory appDir = fileSystem.systemTempDirectory.createTempSync('flutter_app');
      await utils.createFromTemplates(
        projectRoot.childDirectory('bin').path,
        name: 'testapp',
        androidLanguage: 'java',
        iosLanguage: 'objc',
        outputDirectory: appDir.path,
      );
      expect(appDir.childFile('pubspec.yaml').existsSync(), true);
      expect(appDir.childFile('.metadata').existsSync(), true);
      expect(appDir.childFile('.metadata').readAsStringSync(), contains(revision));
      expect(appDir.childDirectory('android').existsSync(), true);
      expect(appDir.childDirectory('ios').existsSync(), true);
      expect(appDir.childDirectory('web').existsSync(), false);

      projectRoot.deleteSync(recursive: true);
    });
  });
}
