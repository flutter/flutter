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
import 'package:flutter_tools/src/migrate/migrate_utils.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/test_flutter_command_runner.dart';

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

  testUsingContext('Status produces all outputs', () async {
    final MigrateCommand command = MigrateCommand(
      verbose: true,
      logger: logger,
      fileSystem: fileSystem,
      terminal: terminal,
      platform: platform,
      processManager: processManager,
    );
    final Directory stagingDir = appDir.childDirectory(kDefaultMigrateStagingDirectoryName);
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

    await createTestCommandRunner(command).run(
      <String>[
        'migrate',
        'status',
        '--staging-directory=${stagingDir.path}',
        '--project-directory=${appDir.path}',
      ]
    );

    expect(logger.statusText, contains('''
Newly added file at added.file:

new file contents'''));
    expect(logger.statusText, contains(r'''
Added files:
  - added.file
Modified files:
  - pubspec.yaml

All conflicts resolved. Review changes above and apply the migration with:

    $ flutter migrate apply
'''));

    expect(logger.statusText, contains(r'''
@@ -1,5 +1,5 @@
-name: originalname
-description: A new Flutter project.
+name: newname
+description: new description of the test project
 version: 1.0.0+1
 environment:
   sdk: '>=2.18.0-58.0.dev <3.0.0'
@@ -10,4 +10,5 @@ dev_dependencies:
   flutter_test:
     sdk: flutter
 flutter:
-  uses-material-design: true
\ No newline at end of file
+  uses-material-design: false
+  EXTRALINE'''));

    // Add conflict file
    final File conflictFile = stagingDir.childDirectory('conflict').childFile('conflict.file');
    conflictFile.createSync(recursive: true);
    conflictFile.writeAsStringSync('''
line1
<<<<<<< /conflcit/conflict.file
line2
=======
linetwo
>>>>>>> /var/folders/md/gm0zgfcj07vcsj6jkh_mp_wh00ff02/T/flutter_tools.4Xdep8/generatedTargetTemplatetlN44S/conflict/conflict.file
line3
''', flush: true);
    final File conflictFileOriginal = appDir.childDirectory('conflict').childFile('conflict.file');
    conflictFileOriginal.createSync(recursive: true);
    conflictFileOriginal.writeAsStringSync('''
line1
line2
line3
''', flush: true);

    manifestFile.writeAsStringSync('''
merged_files:
  - pubspec.yaml
conflict_files:
  - conflict/conflict.file
added_files:
  - added.file
deleted_files:
''');

    logger.clear();
    await createTestCommandRunner(command).run(
      <String>[
        'migrate',
        'status',
        '--staging-directory=${stagingDir.path}',
        '--project-directory=${appDir.path}',
      ]
    );

    expect(logger.statusText, contains('''
@@ -1,3 +1,7 @@
 line1
+<<<<<<< /conflcit/conflict.file
 line2
+=======
+linetwo
+>>>>>>>'''));
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
    Platform: () => platform,
  });
}
