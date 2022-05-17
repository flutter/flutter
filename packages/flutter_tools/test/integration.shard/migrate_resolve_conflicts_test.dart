// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/migrate.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/migrate/migrate_manifest.dart';
import 'package:flutter_tools/src/migrate/migrate_result.dart';
import 'package:flutter_tools/src/migrate/migrate_utils.dart';
import 'package:test/fake.dart';


import '../src/common.dart';
import '../src/context.dart';
import '../src/fakes.dart';
import '../src/test_flutter_command_runner.dart';

void main() {
  FileSystem fileSystem;
  BufferLogger logger;
  Platform platform;
  FakeTerminal terminal;
  ProcessManager processManager;
  Directory appDir;
  Directory workingDir;
  MigrateCommand command;

  setUp(() {
    fileSystem = globals.localFileSystem;
    appDir = fileSystem.systemTempDirectory.createTempSync('apptestdir');
    appDir.createSync(recursive: true);
    appDir.childFile('lib/main.dart').createSync(recursive: true);
    workingDir = appDir.childDirectory('migrate_working_dir');
    workingDir.createSync(recursive: true);
    logger = BufferLogger.test();
    platform = FakePlatform();
    terminal = FakeTerminal(platform: platform);
    processManager = globals.processManager;

    final File pubspecOriginal = appDir.childFile('pubspec.yaml');
    pubspecOriginal.createSync(recursive: true);
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
    command = MigrateCommand(
      logger: logger,
      fileSystem: fileSystem,
      terminal: terminal,
    );
  });

  setUpAll(() {
    Cache.disableLocking();
  });

  tearDown(() async {
    tryToDelete(appDir);
  });

  testUsingContext('commits new simple conflict', () async {
    final File conflictFile = workingDir.childFile('conflict_file');
    conflictFile.createSync(recursive: true);
    conflictFile.writeAsStringSync('hello\nwow a bunch of lines\n<<<<<<<\noriginal\n=======\nnew\n>>>>>>>\nhi\n', flush: true);

    final MigrateManifest manifest = MigrateManifest(migrateRootDir: workingDir, migrateResult: MigrateResult(
      mergeResults: <MergeResult>[
        StringMergeResult.explicit(
          localPath: 'merged_file',
          mergedString: 'str',
          hasConflict: false,
          exitCode: 0,
        ),
        StringMergeResult.explicit(
          localPath: 'conflict_file',
          mergedString: 'hello\nwow a bunch of lines\n<<<<<<<\noriginal\n=======\nnew\n>>>>>>>\nhi\n',
          hasConflict: true,
          exitCode: 1,
        ),
      ],
      addedFiles: <FilePendingMigration>[FilePendingMigration('added_file', fileSystem.file('added_file'))],
      deletedFiles: <FilePendingMigration>[FilePendingMigration('deleted_file', fileSystem.file('deleted_file'))],
      // The following are ignored by the manifest.
      mergeTypeMap: <String, MergeType>{'test': MergeType.threeWay},
      diffMap: <String, DiffResult>{},
      tempDirectories: <Directory>[],
      sdkDirs: <String, Directory>{},
    ));
    manifest.writeFile();

    expect(workingDir.existsSync(), true);
    final Future<void> commandFuture = createTestCommandRunner(command).run(
      <String>[
        'migrate',
        'resolve-conflicts',
        '--working-directory=${workingDir.path}',
        '--project-directory=${appDir.path}',
      ]
    );

    terminal.simulateStdin('n');
    terminal.simulateStdin('y');

    await commandFuture;
    expect(logger.statusText, contains('''
Cyan = Original lines.  Green = New lines.

  2    <<<<<<<
  3    original
  4    =======
  5    new
  6    >>>>>>>
  7    hi'''));
    expect(logger.statusText, contains('''
Conflict in conflict_file.
Accept the (o)riginal lines, (n)ew lines, or (s)kip and resolve the conflict manually? [o|n|s]: n


Conflicts in conflict_file complete.

You chose to:
  Skip 0 conflicts
  Acccept the original lines for 0 conflicts
  Accept the new lines for 1 conflicts

Commit the changes to the working directory? (y)es, (n)o, (r)etry this file [y|n|r]:'''));
    expect(conflictFile.readAsStringSync(), equals('hello\nwow a bunch of lines\nnew\nhi\n'));
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
    Platform: () => platform,
  });

  testUsingContext('skip commit simple conflict leaves intact', () async {
    final File conflictFile = workingDir.childFile('conflict_file');
    conflictFile.createSync(recursive: true);
    conflictFile.writeAsStringSync('hello\nwow a bunch of lines\n<<<<<<<\noriginal\n=======\nnew\n>>>>>>>\nhi\n', flush: true);

    final MigrateManifest manifest = MigrateManifest(migrateRootDir: workingDir, migrateResult: MigrateResult(
      mergeResults: <MergeResult>[
        StringMergeResult.explicit(
          localPath: 'merged_file',
          mergedString: 'str',
          hasConflict: false,
          exitCode: 0,
        ),
        StringMergeResult.explicit(
          localPath: 'conflict_file',
          mergedString: 'hello\nwow a bunch of lines\n<<<<<<<\noriginal\n=======\nnew\n>>>>>>>\nhi\n',
          hasConflict: true,
          exitCode: 1,
        ),
      ],
      addedFiles: <FilePendingMigration>[FilePendingMigration('added_file', fileSystem.file('added_file'))],
      deletedFiles: <FilePendingMigration>[FilePendingMigration('deleted_file', fileSystem.file('deleted_file'))],
      // The following are ignored by the manifest.
      mergeTypeMap: <String, MergeType>{'test': MergeType.threeWay},
      diffMap: <String, DiffResult>{},
      tempDirectories: <Directory>[],
      sdkDirs: <String, Directory>{},
    ));
    manifest.writeFile();

    expect(workingDir.existsSync(), true);
    final Future<void> commandFuture = createTestCommandRunner(command).run(
      <String>[
        'migrate',
        'resolve-conflicts',
        '--working-directory=${workingDir.path}',
        '--project-directory=${appDir.path}',
      ]
    );

    terminal.simulateStdin('n');
    terminal.simulateStdin('n');

    await commandFuture;
    expect(logger.statusText, contains('''
Cyan = Original lines.  Green = New lines.

  2    <<<<<<<
  3    original
  4    =======
  5    new
  6    >>>>>>>
  7    hi'''));
    expect(logger.statusText, contains('''
Conflict in conflict_file.
Accept the (o)riginal lines, (n)ew lines, or (s)kip and resolve the conflict manually? [o|n|s]: n


Conflicts in conflict_file complete.

You chose to:
  Skip 0 conflicts
  Acccept the original lines for 0 conflicts
  Accept the new lines for 1 conflicts

Commit the changes to the working directory? (y)es, (n)o, (r)etry this file [y|n|r]:'''));
    expect(conflictFile.readAsStringSync(), equals('hello\nwow a bunch of lines\n<<<<<<<\noriginal\n=======\nnew\n>>>>>>>\nhi\n'));
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
    Platform: () => platform,
  });

  testUsingContext('commits original simple conflict', () async {
    final File conflictFile = workingDir.childFile('conflict_file');
    conflictFile.createSync(recursive: true);
    conflictFile.writeAsStringSync('hello\nwow a bunch of lines\n<<<<<<<\noriginal\n=======\nnew\n>>>>>>>\nhi\n', flush: true);

    final MigrateManifest manifest = MigrateManifest(migrateRootDir: workingDir, migrateResult: MigrateResult(
      mergeResults: <MergeResult>[
        StringMergeResult.explicit(
          localPath: 'merged_file',
          mergedString: 'str',
          hasConflict: false,
          exitCode: 0,
        ),
        StringMergeResult.explicit(
          localPath: 'conflict_file',
          mergedString: 'hello\nwow a bunch of lines\n<<<<<<<\noriginal\n=======\nnew\n>>>>>>>\nhi\n',
          hasConflict: true,
          exitCode: 1,
        ),
      ],
      addedFiles: <FilePendingMigration>[FilePendingMigration('added_file', fileSystem.file('added_file'))],
      deletedFiles: <FilePendingMigration>[FilePendingMigration('deleted_file', fileSystem.file('deleted_file'))],
      // The following are ignored by the manifest.
      mergeTypeMap: <String, MergeType>{'test': MergeType.threeWay},
      diffMap: <String, DiffResult>{},
      tempDirectories: <Directory>[],
      sdkDirs: <String, Directory>{},
    ));
    manifest.writeFile();

    expect(workingDir.existsSync(), true);
    final Future<void> commandFuture = createTestCommandRunner(command).run(
      <String>[
        'migrate',
        'resolve-conflicts',
        '--working-directory=${workingDir.path}',
        '--project-directory=${appDir.path}',
      ]
    );

    terminal.simulateStdin('o');
    terminal.simulateStdin('y');

    await commandFuture;
    expect(logger.statusText, contains('''
Cyan = Original lines.  Green = New lines.

  2    <<<<<<<
  3    original
  4    =======
  5    new
  6    >>>>>>>
  7    hi'''));
    expect(logger.statusText, contains('''
Conflict in conflict_file.
Accept the (o)riginal lines, (n)ew lines, or (s)kip and resolve the conflict manually? [o|n|s]: o


Conflicts in conflict_file complete.

You chose to:
  Skip 0 conflicts
  Acccept the original lines for 1 conflicts
  Accept the new lines for 0 conflicts

Commit the changes to the working directory? (y)es, (n)o, (r)etry this file [y|n|r]:'''));
    expect(conflictFile.readAsStringSync(), equals('hello\nwow a bunch of lines\noriginal\nhi\n'));
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
    Platform: () => platform,
  });

  testUsingContext('skip conflict leaves file unchanged', () async {
    final File conflictFile = workingDir.childFile('conflict_file');
    conflictFile.createSync(recursive: true);
    conflictFile.writeAsStringSync('hello\nwow a bunch of lines\n<<<<<<<\noriginal\n=======\nnew\n>>>>>>>\nhi\n', flush: true);

    final MigrateManifest manifest = MigrateManifest(migrateRootDir: workingDir, migrateResult: MigrateResult(
      mergeResults: <MergeResult>[
        StringMergeResult.explicit(
          localPath: 'merged_file',
          mergedString: 'str',
          hasConflict: false,
          exitCode: 0,
        ),
        StringMergeResult.explicit(
          localPath: 'conflict_file',
          mergedString: 'hello\nwow a bunch of lines\n<<<<<<<\noriginal\n=======\nnew\n>>>>>>>\nhi\n',
          hasConflict: true,
          exitCode: 1,
        ),
      ],
      addedFiles: <FilePendingMigration>[FilePendingMigration('added_file', fileSystem.file('added_file'))],
      deletedFiles: <FilePendingMigration>[FilePendingMigration('deleted_file', fileSystem.file('deleted_file'))],
      // The following are ignored by the manifest.
      mergeTypeMap: <String, MergeType>{'test': MergeType.threeWay},
      diffMap: <String, DiffResult>{},
      tempDirectories: <Directory>[],
      sdkDirs: <String, Directory>{},
    ));
    manifest.writeFile();

    expect(workingDir.existsSync(), true);
    final Future<void> commandFuture = createTestCommandRunner(command).run(
      <String>[
        'migrate',
        'resolve-conflicts',
        '--working-directory=${workingDir.path}',
        '--project-directory=${appDir.path}',
      ]
    );

    terminal.simulateStdin('s');
    terminal.simulateStdin('y');

    await commandFuture;
    expect(logger.statusText, contains('''
Cyan = Original lines.  Green = New lines.

  2    <<<<<<<
  3    original
  4    =======
  5    new
  6    >>>>>>>
  7    hi'''));
    expect(conflictFile.readAsStringSync(), equals('hello\nwow a bunch of lines\n<<<<<<<\noriginal\n=======\nnew\n>>>>>>>\nhi\n'));
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
    Platform: () => platform,
  });

  testUsingContext('partial conflict skipped.', () async {
    final File conflictFile = workingDir.childFile('conflict_file');
    conflictFile.createSync(recursive: true);
    conflictFile.writeAsStringSync('hello\nwow a bunch of lines\n<<<<<<<\noriginal\n=======\nnew\n>>>>>>>\nhi\n<<<<<<<\nskip this partial conflict\n=======\nblah blah', flush: true);

    final MigrateManifest manifest = MigrateManifest(migrateRootDir: workingDir, migrateResult: MigrateResult(
      mergeResults: <MergeResult>[
        StringMergeResult.explicit(
          localPath: 'merged_file',
          mergedString: 'str',
          hasConflict: false,
          exitCode: 0,
        ),
        StringMergeResult.explicit(
          localPath: 'conflict_file',
          mergedString: 'hello\nwow a bunch of lines\n<<<<<<<\noriginal\n=======\nnew\n>>>>>>>\nhi\n<<<<<<<\nskip this partial conflict\n=======\nblah blah',
          hasConflict: true,
          exitCode: 1,
        ),
      ],
      addedFiles: <FilePendingMigration>[FilePendingMigration('added_file', fileSystem.file('added_file'))],
      deletedFiles: <FilePendingMigration>[FilePendingMigration('deleted_file', fileSystem.file('deleted_file'))],
      // The following are ignored by the manifest.
      mergeTypeMap: <String, MergeType>{'test': MergeType.threeWay},
      diffMap: <String, DiffResult>{},
      tempDirectories: <Directory>[],
      sdkDirs: <String, Directory>{},
    ));
    manifest.writeFile();

    expect(workingDir.existsSync(), true);
    final Future<void> commandFuture = createTestCommandRunner(command).run(
      <String>[
        'migrate',
        'resolve-conflicts',
        '--working-directory=${workingDir.path}',
        '--project-directory=${appDir.path}',
      ]
    );

    terminal.simulateStdin('o');
    terminal.simulateStdin('y');

    await commandFuture;
    expect(logger.statusText, contains('''
Cyan = Original lines.  Green = New lines.

  2    <<<<<<<
  3    original
  4    =======
  5    new
  6    >>>>>>>
  7    hi'''));
    expect(logger.statusText, contains('''
Conflict in conflict_file.
Accept the (o)riginal lines, (n)ew lines, or (s)kip and resolve the conflict manually? [o|n|s]: o


Conflicts in conflict_file complete.

You chose to:
  Skip 0 conflicts
  Acccept the original lines for 1 conflicts
  Accept the new lines for 0 conflicts

Commit the changes to the working directory? (y)es, (n)o, (r)etry this file [y|n|r]:'''));
    expect(conflictFile.readAsStringSync(), equals('hello\nwow a bunch of lines\noriginal\nhi\n<<<<<<<\nskip this partial conflict\n=======\nblah blah\n'));
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
    Platform: () => platform,
  });

  testUsingContext('multiple files sequence', () async {
    final File conflictFile = workingDir.childFile('conflict_file');
    conflictFile.createSync(recursive: true);
    conflictFile.writeAsStringSync('hello\nwow a bunch of lines\n<<<<<<<\noriginal\n=======\nnew\n>>>>>>>\nhi\n', flush: true);
    final File conflictFile2 = workingDir.childFile('conflict_file2');
    conflictFile2.createSync(recursive: true);
    conflictFile2.writeAsStringSync('MoreConflicts\n<<<<<<<\noriginal\nmultiple\nlines\n=======\nnew\n>>>>>>>\nhi\n', flush: true);

    final MigrateManifest manifest = MigrateManifest(migrateRootDir: workingDir, migrateResult: MigrateResult(
      mergeResults: <MergeResult>[
        StringMergeResult.explicit(
          localPath: 'merged_file',
          mergedString: 'str',
          hasConflict: false,
          exitCode: 0,
        ),
        StringMergeResult.explicit(
          localPath: 'conflict_file',
          mergedString: 'hello\nwow a bunch of lines\n<<<<<<<\noriginal\n=======\nnew\n>>>>>>>\nhi\n',
          hasConflict: true,
          exitCode: 1,
        ),
        StringMergeResult.explicit(
          localPath: 'conflict_file2',
          mergedString: 'MoreConflicts\n<<<<<<<\noriginal\nmultiple\nlines\n=======\nnew\n>>>>>>>\nhi\n',
          hasConflict: true,
          exitCode: 1,
        ),
      ],
      addedFiles: <FilePendingMigration>[FilePendingMigration('added_file', fileSystem.file('added_file'))],
      deletedFiles: <FilePendingMigration>[FilePendingMigration('deleted_file', fileSystem.file('deleted_file'))],
      // The following are ignored by the manifest.
      mergeTypeMap: <String, MergeType>{'test': MergeType.threeWay},
      diffMap: <String, DiffResult>{},
      tempDirectories: <Directory>[],
      sdkDirs: <String, Directory>{},
    ));
    manifest.writeFile();

    expect(workingDir.existsSync(), true);
    final Future<void> commandFuture = createTestCommandRunner(command).run(
      <String>[
        'migrate',
        'resolve-conflicts',
        '--working-directory=${workingDir.path}',
        '--project-directory=${appDir.path}',
      ]
    );

    terminal.simulateStdin('n');
    terminal.simulateStdin('y');
    terminal.simulateStdin('o');
    terminal.simulateStdin('y');

    await commandFuture;
    expect(logger.statusText, contains('''
Cyan = Original lines.  Green = New lines.

  2    <<<<<<<
  3    original
  4    =======
  5    new
  6    >>>>>>>
  7    hi'''));
    expect(logger.statusText, contains('''
Conflict in conflict_file.
Accept the (o)riginal lines, (n)ew lines, or (s)kip and resolve the conflict manually? [o|n|s]: n


Conflicts in conflict_file complete.

You chose to:
  Skip 0 conflicts
  Acccept the original lines for 0 conflicts
  Accept the new lines for 1 conflicts

Commit the changes to the working directory? (y)es, (n)o, (r)etry this file [y|n|r]:'''));
        expect(logger.statusText, contains('''
Cyan = Original lines.  Green = New lines.

  1    <<<<<<<
  2    original
  3    multiple
  4    lines
  5    =======
  6    new
  7    >>>>>>>
  8    hi'''));
    expect(logger.statusText, contains('''
Conflict in conflict_file2.
Accept the (o)riginal lines, (n)ew lines, or (s)kip and resolve the conflict manually? [o|n|s]: o


Conflicts in conflict_file2 complete.

You chose to:
  Skip 0 conflicts
  Acccept the original lines for 1 conflicts
  Accept the new lines for 0 conflicts

Commit the changes to the working directory? (y)es, (n)o, (r)etry this file [y|n|r]:'''));
    expect(conflictFile.readAsStringSync(), equals('hello\nwow a bunch of lines\nnew\nhi\n'));
    expect(conflictFile2.readAsStringSync(), equals('MoreConflicts\noriginal\nmultiple\nlines\nhi\n'));
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
    Platform: () => platform,
  });

  testUsingContext('retry works', () async {
    final File conflictFile = workingDir.childFile('conflict_file');
    conflictFile.createSync(recursive: true);
    conflictFile.writeAsStringSync('hello\nwow a bunch of lines\n<<<<<<<\noriginal\n=======\nnew\n>>>>>>>\nhi\n<<<<<<<\noriginal2\n=======\nnew2\n>>>>>>>\n', flush: true);

    final MigrateManifest manifest = MigrateManifest(migrateRootDir: workingDir, migrateResult: MigrateResult(
      mergeResults: <MergeResult>[
        StringMergeResult.explicit(
          localPath: 'merged_file',
          mergedString: 'str',
          hasConflict: false,
          exitCode: 0,
        ),
        StringMergeResult.explicit(
          localPath: 'conflict_file',
          mergedString: 'hello\nwow a bunch of lines\n<<<<<<<\noriginal\n=======\nnew\n>>>>>>>\nhi\n<<<<<<<\noriginal2\n=======\nnew2\n>>>>>>>\n',
          hasConflict: true,
          exitCode: 1,
        ),
      ],
      addedFiles: <FilePendingMigration>[FilePendingMigration('added_file', fileSystem.file('added_file'))],
      deletedFiles: <FilePendingMigration>[FilePendingMigration('deleted_file', fileSystem.file('deleted_file'))],
      // The following are ignored by the manifest.
      mergeTypeMap: <String, MergeType>{'test': MergeType.threeWay},
      diffMap: <String, DiffResult>{},
      tempDirectories: <Directory>[],
      sdkDirs: <String, Directory>{},
    ));
    manifest.writeFile();

    expect(workingDir.existsSync(), true);
    final Future<void> commandFuture = createTestCommandRunner(command).run(
      <String>[
        'migrate',
        'resolve-conflicts',
        '--working-directory=${workingDir.path}',
        '--project-directory=${appDir.path}',
      ]
    );

    terminal.simulateStdin('n');
    terminal.simulateStdin('o');
    terminal.simulateStdin('r');
    // Retry with different choices
    terminal.simulateStdin('o');
    terminal.simulateStdin('n');
    terminal.simulateStdin('y');

    await commandFuture;
    expect(logger.statusText, contains('''
Cyan = Original lines.  Green = New lines.

  2    <<<<<<<
  3    original
  4    =======
  5    new
  6    >>>>>>>
  7    hi'''));
    expect(logger.statusText, contains('''
Commit the changes to the working directory? (y)es, (n)o, (r)etry this file [y|n|r]: r


Cyan = Original lines.  Green = New lines.'''));
    expect(logger.statusText, contains('''
Conflict in conflict_file.
Accept the (o)riginal lines, (n)ew lines, or (s)kip and resolve the conflict manually? [o|n|s]: n


Conflicts in conflict_file complete.

You chose to:
  Skip 0 conflicts
  Acccept the original lines for 1 conflicts
  Accept the new lines for 1 conflicts

Commit the changes to the working directory? (y)es, (n)o, (r)etry this file [y|n|r]:'''));
    expect(conflictFile.readAsStringSync(), equals('hello\nwow a bunch of lines\noriginal\nhi\nnew2\n'));
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
    Platform: () => platform,
  });
}

class FakeTerminal extends Fake implements Terminal {
  factory FakeTerminal({Platform platform}) {
    return FakeTerminal._private(
        stdio: FakeStdio(),
        platform: platform
    );
  }

  FakeTerminal._private({
    this.stdio,
    Platform platform
  }) :
    terminal = AnsiTerminal(
      stdio: stdio,
      platform: platform
    );

  final FakeStdio stdio;
  final AnsiTerminal terminal;

  void simulateStdin(String line) {
    stdio.simulateStdin(line);
  }

  @override
  set usesTerminalUi(bool value) => terminal.usesTerminalUi = value;

  @override
  bool get usesTerminalUi => terminal.usesTerminalUi;

  @override
  String clearScreen() => terminal.clearScreen();

  @override
  Future<String> promptForCharInput(
    List<String> acceptedCharacters, {
    Logger logger,
    String prompt,
    int defaultChoiceIndex,
    bool displayAcceptedCharacters = true
  }) => terminal.promptForCharInput(
      acceptedCharacters,
      logger: logger,
      prompt: prompt,
      defaultChoiceIndex: defaultChoiceIndex,
      displayAcceptedCharacters: displayAcceptedCharacters
    );
}
