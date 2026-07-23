// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/migrations/analysis_options_migration.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';

void main() {
  group('Analysis options migration', () {
    testWithoutContext('skipped if analysis_options.yaml file is missing', () async {
      final _TestContext context = _createTestContext();
      final migration = AnalysisOptionsMigration(context.mockProject, context.testLogger);
      await migration.migrate();
      expect(context.analysisOptionsFile.existsSync(), isFalse);
      expect(context.testLogger.traceText, isEmpty);
      expect(context.testLogger.statusText, isEmpty);
    });

    testWithoutContext('skipped if already migrated', () async {
      final _TestContext context = _createTestContext();
      const analysisOptionsContents = '''
analyzer:
  exclude:
    - build/**
    - android/**
    - ios/**
    - web/**
    - windows/**
    - macos/**
    - linux/**
include: package:flutter_lints/flutter.yaml
''';

      context.analysisOptionsFile.writeAsStringSync(analysisOptionsContents);

      final migration = AnalysisOptionsMigration(context.mockProject, context.testLogger);
      await migration.migrate();

      expect(context.analysisOptionsFile.readAsStringSync(), analysisOptionsContents);
      expect(context.testLogger.statusText, isEmpty);
    });

    testWithoutContext('skipped if not a YamlMap', () async {
      final _TestContext context = _createTestContext();
      const analysisOptionsContents = 'not a map';
      context.analysisOptionsFile.writeAsStringSync(analysisOptionsContents);

      final migration = AnalysisOptionsMigration(context.mockProject, context.testLogger);
      await migration.migrate();

      expect(context.analysisOptionsFile.readAsStringSync(), analysisOptionsContents);
      expect(
        context.testLogger.traceText,
        contains('analysis_options.yaml is not a YAML map, skipping migration.'),
      );
      expect(context.testLogger.statusText, isEmpty);
    });

    testWithoutContext('skipped if malformed YAML', () async {
      final _TestContext context = _createTestContext();
      const analysisOptionsContents = 'analyzer: [unclosed list';
      context.analysisOptionsFile.writeAsStringSync(analysisOptionsContents);

      final migration = AnalysisOptionsMigration(context.mockProject, context.testLogger);
      await migration.migrate();

      expect(context.analysisOptionsFile.readAsStringSync(), analysisOptionsContents);
      expect(context.testLogger.traceText, contains('Failed to parse analysis_options.yaml:'));
      expect(context.testLogger.statusText, isEmpty);
    });

    testWithoutContext('migrates when analyzer section is missing', () async {
      final _TestContext context = _createTestContext();
      const analysisOptionsContents = '''
include: package:flutter_lints/flutter.yaml
''';

      context.analysisOptionsFile.writeAsStringSync(analysisOptionsContents);

      final migration = AnalysisOptionsMigration(context.mockProject, context.testLogger);
      await migration.migrate();

      expect(
        context.analysisOptionsFile.readAsStringSync(),
        contains('''
analyzer:
  exclude:
    - build/**
    - android/**
    - ios/**
    - web/**
    - windows/**
    - macos/**
    - linux/**'''),
      );
      expect(
        context.testLogger.statusText,
        contains('Upgrading analysis_options.yaml to exclude build and platform directories.'),
      );
    });

    testWithoutContext('migrates when exclude section is missing', () async {
      final _TestContext context = _createTestContext();
      const analysisOptionsContents = '''
analyzer:
  strong-mode: true
include: package:flutter_lints/flutter.yaml
''';

      context.analysisOptionsFile.writeAsStringSync(analysisOptionsContents);

      final migration = AnalysisOptionsMigration(context.mockProject, context.testLogger);
      await migration.migrate();

      final String migratedContents = context.analysisOptionsFile.readAsStringSync();
      expect(migratedContents, contains('strong-mode: true'));
      expect(
        migratedContents,
        contains('''
  exclude:
    - build/**
    - android/**
    - ios/**
    - web/**
    - windows/**
    - macos/**
    - linux/**'''),
      );
    });

    testWithoutContext('migrates and merges excludes', () async {
      final _TestContext context = _createTestContext();
      const analysisOptionsContents = '''
analyzer:
  exclude:
    - foo/**
    - build/**
''';

      context.analysisOptionsFile.writeAsStringSync(analysisOptionsContents);

      final migration = AnalysisOptionsMigration(context.mockProject, context.testLogger);
      await migration.migrate();

      final String migratedContents = context.analysisOptionsFile.readAsStringSync();
      expect(migratedContents, contains('- foo/**'));
      expect(migratedContents, contains('- build/**'));
      expect(migratedContents, contains('- android/**'));
      expect(migratedContents, contains('- ios/**'));
      expect(migratedContents, contains('- web/**'));
      expect(migratedContents, contains('- windows/**'));
      expect(migratedContents, contains('- macos/**'));
      expect(migratedContents, contains('- linux/**'));
    });

    testWithoutContext('migrates and preserves comments inside exclude list', () async {
      final _TestContext context = _createTestContext();
      const analysisOptionsContents = '''
analyzer:
  exclude:
    # Some important comment about why we exclude this
    - foo/**
''';

      context.analysisOptionsFile.writeAsStringSync(analysisOptionsContents);

      final migration = AnalysisOptionsMigration(context.mockProject, context.testLogger);
      await migration.migrate();

      final String migratedContents = context.analysisOptionsFile.readAsStringSync();
      expect(migratedContents, contains('# Some important comment about why we exclude this'));
      expect(migratedContents, contains('- foo/**'));
      expect(migratedContents, contains('- build/**'));
    });

    testWithoutContext('migrates and merges excludes when list is in flow style', () async {
      final _TestContext context = _createTestContext();
      const analysisOptionsContents = '''
analyzer:
  exclude: [foo/**, build/**]
''';

      context.analysisOptionsFile.writeAsStringSync(analysisOptionsContents);

      final migration = AnalysisOptionsMigration(context.mockProject, context.testLogger);
      await migration.migrate();

      final String migratedContents = context.analysisOptionsFile.readAsStringSync();
      expect(migratedContents, contains('foo/**'));
      expect(migratedContents, contains('build/**'));
      expect(migratedContents, contains('android/**'));
      expect(migratedContents, contains('ios/**'));
      expect(migratedContents, contains('web/**'));
      expect(migratedContents, contains('windows/**'));
      expect(migratedContents, contains('macos/**'));
      expect(migratedContents, contains('linux/**'));
    });
  });
}

typedef _TestContext = ({
  MemoryFileSystem memoryFileSystem,
  File analysisOptionsFile,
  BufferLogger testLogger,
  FakeFlutterProject mockProject,
});

_TestContext _createTestContext() {
  final memoryFileSystem = MemoryFileSystem.test();
  final File analysisOptionsFile = memoryFileSystem.file('analysis_options.yaml');
  final testLogger = BufferLogger(
    terminal: Terminal.test(),
    outputPreferences: OutputPreferences.test(),
  );
  final mockProject = FakeFlutterProject(directory: memoryFileSystem.currentDirectory);
  return (
    memoryFileSystem: memoryFileSystem,
    analysisOptionsFile: analysisOptionsFile,
    testLogger: testLogger,
    mockProject: mockProject,
  );
}

class FakeFlutterProject extends Fake implements FlutterProject {
  FakeFlutterProject({required this.directory});

  @override
  final Directory directory;
}
