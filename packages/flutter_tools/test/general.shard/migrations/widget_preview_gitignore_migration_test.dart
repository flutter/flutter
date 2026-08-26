// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/migrations/widget_preview_gitignore_migration.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';

void main() {
  group('Widget Preview .gitignore migration', () {
    late MemoryFileSystem memoryFileSystem;
    late BufferLogger testLogger;
    late FakeFlutterProject mockProject;
    late File gitignoreFile;

    setUp(() {
      memoryFileSystem = MemoryFileSystem.test();
      gitignoreFile = memoryFileSystem.file('.gitignore');

      testLogger = BufferLogger(
        terminal: Terminal.test(),
        outputPreferences: OutputPreferences.test(),
      );

      mockProject = FakeFlutterProject(fileSystem: memoryFileSystem);
    });

    testWithoutContext('skipped if .gitignore file is missing', () async {
      final migration = WidgetPreviewGitignoreMigration(mockProject, testLogger);
      await migration.migrate();
      expect(gitignoreFile.existsSync(), isFalse);

      expect(
        testLogger.traceText,
        contains('.gitignore file not found, skipping widget preview .gitignore migration.'),
      );
      expect(testLogger.warningText, isEmpty);
    });

    testWithoutContext('skipped if already migrated', () async {
      const gitignoreFileContents = '''
.DS_Store
.widget_preview/
''';

      gitignoreFile.writeAsStringSync(gitignoreFileContents);

      final DateTime updatedAt = gitignoreFile.lastModifiedSync();

      final migration = WidgetPreviewGitignoreMigration(mockProject, testLogger);
      await migration.migrate();

      expect(gitignoreFile.lastModifiedSync(), updatedAt);
      expect(gitignoreFile.readAsStringSync(), gitignoreFileContents);
      expect(testLogger.warningText, isEmpty);
    });

    testWithoutContext('migrates project to ignore .widget_preview directory', () async {
      gitignoreFile.writeAsStringSync(
        '.DS_Store\n'
        '.atom/\n',
      );

      final migration = WidgetPreviewGitignoreMigration(mockProject, testLogger);
      await migration.migrate();

      expect(
        gitignoreFile.readAsStringSync(),
        '.DS_Store\n'
        '.atom/\n'
        '# Widget Preview related\n'
        '.widget_preview/\n',
      );

      expect(
        testLogger.traceText,
        contains('.gitignore does not ignore .widget_preview/ directory, updating.'),
      );
    });
  });
}

class FakeFlutterProject extends Fake implements FlutterProject {
  FakeFlutterProject({required MemoryFileSystem fileSystem})
    : gitignoreFile = fileSystem.file('.gitignore');

  @override
  File gitignoreFile;
}
