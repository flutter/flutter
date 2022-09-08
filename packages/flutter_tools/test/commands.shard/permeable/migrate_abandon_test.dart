// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/migrate.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/migrate/migrate_utils.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/test_flutter_command_runner.dart';

void main() {
  late FileSystem fileSystem;
  late BufferLogger logger;
  late Platform platform;
  late Terminal terminal;
  late ProcessManager processManager;
  late Directory appDir;

  setUp(() {
    fileSystem = globals.localFileSystem;
    appDir = fileSystem.systemTempDirectory.createTempSync('apptestdir');
    logger = BufferLogger.test();
    platform = FakePlatform();
    terminal = Terminal.test();
    processManager = globals.processManager;
  });

  setUpAll(() {
    Cache.disableLocking();
  });

  tearDown(() async {
    tryToDelete(appDir);
  });

  testUsingContext('abandon deletes staging directory', () async {
    final MigrateCommand command = MigrateCommand(
      verbose: true,
      logger: logger,
      fileSystem: fileSystem,
      terminal: terminal,
      platform: platform,
      processManager: processManager,
    );
    final Directory stagingDir = appDir.childDirectory(kDefaultMigrateStagingDirectoryName);
    appDir.childFile('lib/main.dart').createSync(recursive: true);
    final File pubspecOriginal = appDir.childFile('pubspec.yaml');
    pubspecOriginal.createSync();
    pubspecOriginal.writeAsStringSync('''
name: originalname
description: A new Flutter project.
version: 1.0.0+1
environment:
  sdk: '>=2.18.0-58.0.dev <3.0.0'
dependencies:
  flutter:
    sdk: flutter
dev_dependencies:
  flutter_test:
    sdk: flutter
flutter:
  uses-material-design: true''', flush: true);

    expect(stagingDir.existsSync(), false);
    await createTestCommandRunner(command).run(
      <String>[
        'migrate',
        'abandon',
        '--staging-directory=${stagingDir.path}',
        '--project-directory=${appDir.path}',
      ]
    );
    expect(logger.errorText, contains('Provided staging directory'));
    expect(logger.errorText, contains('migrate_staging_dir` does not exist or is not valid.'));

    logger.clear();
    await createTestCommandRunner(command).run(
      <String>[
        'migrate',
        'abandon',
        '--project-directory=${appDir.path}',
      ]
    );
    expect(logger.statusText, contains('No migration in progress. Start a new migration with:'));

    final File pubspecModified = stagingDir.childFile('pubspec.yaml');
    pubspecModified.createSync(recursive: true);
    pubspecModified.writeAsStringSync('''
name: newname
description: new description of the test project
version: 1.0.0+1
environment:
  sdk: '>=2.18.0-58.0.dev <3.0.0'
dependencies:
  flutter:
    sdk: flutter
dev_dependencies:
  flutter_test:
    sdk: flutter
flutter:
  uses-material-design: false
  EXTRALINE''', flush: true);

    final File addedFile = stagingDir.childFile('added.file');
    addedFile.createSync(recursive: true);
    addedFile.writeAsStringSync('new file contents');

    final File manifestFile = stagingDir.childFile('.migrate_manifest');
    manifestFile.createSync(recursive: true);
    manifestFile.writeAsStringSync('''
merged_files:
  - pubspec.yaml
conflict_files:
added_files:
  - added.file
deleted_files:
''');

    expect(appDir.childFile('lib/main.dart').existsSync(), true);

    expect(stagingDir.existsSync(), true);
    logger.clear();
    await createTestCommandRunner(command).run(
      <String>[
        'migrate',
        'abandon',
        '--staging-directory=${stagingDir.path}',
        '--project-directory=${appDir.path}',
        '--force',
      ]
    );
    expect(logger.statusText, contains('Abandon complete. Start a new migration with:'));
    expect(stagingDir.existsSync(), false);
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
    Platform: () => platform,
  });
}
