// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/migrate.dart';
import 'package:flutter_tools/src/globals.dart' as globals;


import '../src/common.dart';
import '../src/context.dart';
import '../src/test_flutter_command_runner.dart';

void main() {
  FileSystem fileSystem;
  BufferLogger logger;
  Platform platform;
  Terminal terminal;
  ProcessManager processManager;
  Directory appDir;

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

  testUsingContext('abandon deletes working directory', () async {
    final MigrateCommand command = MigrateCommand(
      verbose: true,
      logger: logger,
      fileSystem: fileSystem,
      terminal: terminal,
      platform: platform,
      processManager: processManager,
    );
    Directory workingDir = appDir.childDirectory('migrate_working_dir');
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

    expect(workingDir.existsSync(), false);
    await createTestCommandRunner(command).run(
      <String>[
        'migrate',
        'abandon',
        '--working-directory=${workingDir.path}',
        '--project-directory=${appDir.path}',
      ]
    );
    expect(logger.errorText, contains('Provided working directory'));
    expect(logger.errorText, contains('/migrate_working_dir` does not exist or is not valid.'));

    logger.clear();
    await createTestCommandRunner(command).run(
      <String>[
        'migrate',
        'abandon',
        '--project-directory=${appDir.path}',
      ]
    );
    expect(logger.statusText, contains('No migration in progress. Start a new migration with:'));

    final File pubspecModified = workingDir.childFile('pubspec.yaml');
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

    final File addedFile = workingDir.childFile('added.file');
    addedFile.createSync(recursive: true);
    addedFile.writeAsStringSync('new file contents');

    final File manifestFile = workingDir.childFile('.migrate_manifest');
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

    expect(workingDir.existsSync(), true);
    logger.clear();
    await createTestCommandRunner(command).run(
      <String>[
        'migrate',
        'abandon',
        '--working-directory=${workingDir.path}',
        '--project-directory=${appDir.path}',
        '--force',
      ]
    );
    expect(logger.statusText, contains('Abandon complete. Start a new migration with:'));
    expect(workingDir.existsSync(), false);
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
    Platform: () => platform,
  });
}
