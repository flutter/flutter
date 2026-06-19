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
    late MemoryFileSystem memoryFileSystem;
    late BufferLogger testLogger;
    late FakeFlutterProject mockProject;
    late File analysisOptionsFile;

    setUp(() {
      memoryFileSystem = MemoryFileSystem.test();
      analysisOptionsFile = memoryFileSystem.file('analysis_options.yaml');

      testLogger = BufferLogger(
        terminal: Terminal.test(),
        outputPreferences: OutputPreferences.test(),
      );

      mockProject = FakeFlutterProject(directory: memoryFileSystem.currentDirectory);
    });

    testWithoutContext('skipped if analysis_options.yaml file is missing', () async {
      final migration = AnalysisOptionsMigration(mockProject, testLogger);
      await migration.migrate();
      expect(analysisOptionsFile.existsSync(), isFalse);
      expect(testLogger.traceText, isEmpty);
      expect(testLogger.statusText, isEmpty);
    });

    testWithoutContext('skipped if already migrated', () async {
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

      analysisOptionsFile.writeAsStringSync(analysisOptionsContents);

      final migration = AnalysisOptionsMigration(mockProject, testLogger);
      await migration.migrate();

      expect(analysisOptionsFile.readAsStringSync(), analysisOptionsContents);
      expect(testLogger.statusText, isEmpty);
    });

    testWithoutContext('skipped if not a YamlMap', () async {
      const analysisOptionsContents = 'not a map';
      analysisOptionsFile.writeAsStringSync(analysisOptionsContents);

      final migration = AnalysisOptionsMigration(mockProject, testLogger);
      await migration.migrate();

      expect(analysisOptionsFile.readAsStringSync(), analysisOptionsContents);
      expect(
        testLogger.traceText,
        contains('analysis_options.yaml is not a YAML map, skipping migration.'),
      );
      expect(testLogger.statusText, isEmpty);
    });

    testWithoutContext('skipped if malformed YAML', () async {
      const analysisOptionsContents = 'analyzer: [unclosed list';
      analysisOptionsFile.writeAsStringSync(analysisOptionsContents);

      final migration = AnalysisOptionsMigration(mockProject, testLogger);
      await migration.migrate();

      expect(analysisOptionsFile.readAsStringSync(), analysisOptionsContents);
      expect(testLogger.traceText, contains('Failed to parse analysis_options.yaml:'));
      expect(testLogger.statusText, isEmpty);
    });

    testWithoutContext('migrates when analyzer section is missing', () async {
      const analysisOptionsContents = '''
include: package:flutter_lints/flutter.yaml
''';

      analysisOptionsFile.writeAsStringSync(analysisOptionsContents);

      final migration = AnalysisOptionsMigration(mockProject, testLogger);
      await migration.migrate();

      expect(
        analysisOptionsFile.readAsStringSync(),
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
        testLogger.statusText,
        contains('Upgrading analysis_options.yaml to exclude build and platform directories.'),
      );
    });

    testWithoutContext('migrates when exclude section is missing', () async {
      const analysisOptionsContents = '''
analyzer:
  strong-mode: true
include: package:flutter_lints/flutter.yaml
''';

      analysisOptionsFile.writeAsStringSync(analysisOptionsContents);

      final migration = AnalysisOptionsMigration(mockProject, testLogger);
      await migration.migrate();

      final String migratedContents = analysisOptionsFile.readAsStringSync();
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
      const analysisOptionsContents = '''
analyzer:
  exclude:
    - foo/**
    - build/**
''';

      analysisOptionsFile.writeAsStringSync(analysisOptionsContents);

      final migration = AnalysisOptionsMigration(mockProject, testLogger);
      await migration.migrate();

      final String migratedContents = analysisOptionsFile.readAsStringSync();
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
      const analysisOptionsContents = '''
analyzer:
  exclude:
    # Some important comment about why we exclude this
    - foo/**
''';

      analysisOptionsFile.writeAsStringSync(analysisOptionsContents);

      final migration = AnalysisOptionsMigration(mockProject, testLogger);
      await migration.migrate();

      final String migratedContents = analysisOptionsFile.readAsStringSync();
      expect(migratedContents, contains('# Some important comment about why we exclude this'));
      expect(migratedContents, contains('- foo/**'));
      expect(migratedContents, contains('- build/**'));
    });

    testWithoutContext('migrates and merges excludes when list is in flow style', () async {
      const analysisOptionsContents = '''
analyzer:
  exclude: [foo/**, build/**]
''';

      analysisOptionsFile.writeAsStringSync(analysisOptionsContents);

      final migration = AnalysisOptionsMigration(mockProject, testLogger);
      await migration.migrate();

      final String migratedContents = analysisOptionsFile.readAsStringSync();
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

class FakeFlutterProject extends Fake implements FlutterProject {
  FakeFlutterProject({required this.directory});

  @override
  final Directory directory;
}
