// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/process.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/migrate.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/project.dart';
// import 'package:test/fake.dart';
// import 'package:process/process.dart';


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
    // fileSystem = MemoryFileSystem.test();
    appDir = fileSystem.systemTempDirectory.createTempSync('apptestdir');
    logger = BufferLogger.test();
    platform = FakePlatform();
    terminal = Terminal.test();
    // processManager = FakeProcessManager.any();
    processManager = globals.processManager;
    // processManager = const LocalProcessManager();
  });

  setUpAll(() {
    Cache.disableLocking();
  });

  testUsingContext('Status succeeds', () async {
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

    await createTestCommandRunner(command).run(
      <String>[
        'migrate',
        'status',
        '--working-directory=${workingDir.path}',
      ]
    );
    expect(logger.statusText, contains('''
Newly addded file at added.file:

new file contents'''));
    expect(logger.statusText, contains('''
Added files:
  - added.file
Modified files:
  - pubspec.yaml

All conflicts resolved. Review changes above and apply the migration with:

    \$ flutter migrate apply
'''));

    expect(logger.statusText, contains('''
-name: flutter_tools
-description: Tools for building Flutter applications
-homepage: https://flutter.dev
-
+name: newname
+description: new description of the test project
+version: 1.0.0+1
 environment:
-  sdk: ">=2.17.0-0 <3.0.0"
-
+  sdk: \'>=2.18.0-58.0.dev <3.0.0\''''));
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
    Platform: () => platform,
  });
}
