// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/process.dart';
import 'package:flutter_tools/src/commands/migrate.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/migrate/migrate_utils.dart';

import '../src/common.dart';

void main() {
  late BufferLogger logger;
  late FileSystem fileSystem;
  late Directory projectRoot;
  late String projectRootPath;
  late ProcessUtils processUtils;
  late MigrateUtils utils;

  setUpAll(() async {
    fileSystem = globals.localFileSystem;
    logger = BufferLogger.test();
    utils = MigrateUtils(
      logger: logger,
      fileSystem: fileSystem,
      platform: globals.platform,
      processManager: globals.processManager,
    );
    processUtils = ProcessUtils(processManager: globals.processManager, logger: logger);
  });

  group('git', () {
    setUp(() async {
      projectRoot = fileSystem.systemTempDirectory.createTempSync('flutter_migrate_command_test');
      projectRoot.createSync(recursive: true);
      projectRootPath = projectRoot.path;
    });

    tearDown(() async {
      tryToDelete(projectRoot);
    });

    testWithoutContext('isGitRepo', () async {
      expect(projectRoot.existsSync(), true);
      expect(projectRoot.childDirectory('.git').existsSync(), false);

      expect(await gitRepoExists(projectRootPath, logger, utils), false);
      expect(logger.statusText, contains('Project is not a git repo. Please initialize a git repo and try again.'));

      await utils.gitInit(projectRootPath);
      expect(projectRoot.childDirectory('.git').existsSync(), true);

      expect(await gitRepoExists(projectRootPath, logger, utils), true);
    });

    testWithoutContext('printCommandText produces formatted output', () async {
      printCommandText('some command --help', logger);

      expect(logger.statusText, contains(r'  $ some command --help'));
    });

    testWithoutContext('hasUncommittedChanges false on clean repo', () async {
      expect(projectRoot.existsSync(), true);
      expect(projectRoot.childDirectory('.git').existsSync(), false);
      await utils.gitInit(projectRootPath);
      expect(projectRoot.childDirectory('.git').existsSync(), true);

      projectRoot.childFile('.gitignore')
        ..createSync()
        ..writeAsStringSync('ignored_file.dart', flush: true);

      await processUtils.run(<String>['git', 'add', '.'], workingDirectory: projectRootPath);
      await processUtils.run(<String>['git', 'commit', '-m', 'Initial commit'], workingDirectory: projectRootPath);

      expect(await hasUncommittedChanges(projectRootPath, logger, utils), false);
    });

    testWithoutContext('hasUncommittedChanges true on dirty repo', () async {
      expect(projectRoot.existsSync(), true);
      expect(projectRoot.childDirectory('.git').existsSync(), false);
      await utils.gitInit(projectRootPath);
      expect(projectRoot.childDirectory('.git').existsSync(), true);

      projectRoot.childFile('some_file.dart')
        ..createSync()
        ..writeAsStringSync('void main() {}', flush: true);

      expect(await hasUncommittedChanges(projectRootPath, logger, utils), true);
    });
  });
}
