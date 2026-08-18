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

const _allPlatforms = <String>['android', 'ios', 'web', 'windows', 'macos', 'linux'];

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

    testWithoutContext(
      'skipped entirely for a Dart-only package (no flutter dependency)',
      () async {
        final _TestContext context = _createTestContext(
          isFlutterProject: false,
          platforms: <String>['web'],
        );
        const analysisOptionsContents = '''
include: package:lints/recommended.yaml
''';
        context.analysisOptionsFile.writeAsStringSync(analysisOptionsContents);

        final migration = AnalysisOptionsMigration(context.mockProject, context.testLogger);
        await migration.migrate();

        expect(context.analysisOptionsFile.readAsStringSync(), analysisOptionsContents);
        expect(context.testLogger.statusText, isEmpty);
      },
    );

    testWithoutContext('only excludes platform directories that actually exist', () async {
      final _TestContext context = _createTestContext(platforms: <String>['android', 'ios']);
      const analysisOptionsContents = '''
include: package:flutter_lints/flutter.yaml
''';

      context.analysisOptionsFile.writeAsStringSync(analysisOptionsContents);

      final migration = AnalysisOptionsMigration(context.mockProject, context.testLogger);
      await migration.migrate();

      final String migratedContents = context.analysisOptionsFile.readAsStringSync();
      expect(migratedContents, contains('- build/**'));
      expect(migratedContents, contains('- android/**'));
      expect(migratedContents, contains('- ios/**'));
      expect(migratedContents, isNot(contains('- web/**')));
      expect(migratedContents, isNot(contains('- windows/**')));
      expect(migratedContents, isNot(contains('- macos/**')));
      expect(migratedContents, isNot(contains('- linux/**')));
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
  FlutterProject mockProject,
});

/// Builds a test context backed by a real [FlutterProject] view of an
/// in-memory directory, so that platform existence checks (`android.existsSync()`,
/// etc.) reflect the directories actually created here, matching production
/// behavior instead of being separately mocked.
_TestContext _createTestContext({
  bool isFlutterProject = true,
  List<String> platforms = _allPlatforms,
}) {
  final memoryFileSystem = MemoryFileSystem.test();
  final Directory projectDirectory = memoryFileSystem.currentDirectory;
  final File analysisOptionsFile = projectDirectory.childFile('analysis_options.yaml');
  final testLogger = BufferLogger(
    terminal: Terminal.test(),
    outputPreferences: OutputPreferences.test(),
  );

  projectDirectory
      .childFile('pubspec.yaml')
      .writeAsStringSync(
        isFlutterProject
            ? '''
name: test_project
dependencies:
  flutter:
    sdk: flutter
'''
            : '''
name: test_project
''',
      );

  if (platforms.contains('android')) {
    projectDirectory.childDirectory('android').createSync(recursive: true);
  }
  if (platforms.contains('ios')) {
    projectDirectory.childDirectory('ios').createSync(recursive: true);
  }
  if (platforms.contains('web')) {
    projectDirectory.childDirectory('web').childFile('index.html').createSync(recursive: true);
  }
  if (platforms.contains('windows')) {
    projectDirectory
        .childDirectory('windows')
        .childFile('CMakeLists.txt')
        .createSync(recursive: true);
  }
  if (platforms.contains('macos')) {
    projectDirectory.childDirectory('macos').createSync(recursive: true);
  }
  if (platforms.contains('linux')) {
    projectDirectory.childDirectory('linux').createSync(recursive: true);
  }

  final FlutterProject mockProject = FlutterProject.fromDirectoryTest(projectDirectory);
  return (
    memoryFileSystem: memoryFileSystem,
    analysisOptionsFile: analysisOptionsFile,
    testLogger: testLogger,
    mockProject: mockProject,
  );
}
