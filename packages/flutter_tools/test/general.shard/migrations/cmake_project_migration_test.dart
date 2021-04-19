// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/project_migrator.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/migrations/cmake_custom_command_migration.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:meta/meta.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';

void main () {
  group('CMake project migration', () {
    testWithoutContext('migrators succeed', () {
      final FakeCmakeMigrator fakeCmakeMigrator = FakeCmakeMigrator(succeeds: true);
      final ProjectMigration migration = ProjectMigration(<ProjectMigrator>[fakeCmakeMigrator]);
      expect(migration.run(), isTrue);
    });

    testWithoutContext('migrators fail', () {
      final FakeCmakeMigrator fakeCmakeMigrator = FakeCmakeMigrator(succeeds: false);
      final ProjectMigration migration = ProjectMigration(<ProjectMigrator>[fakeCmakeMigrator]);
      expect(migration.run(), isFalse);
    });

    group('migrate add_custom_command() to use VERBATIM', () {
      MemoryFileSystem memoryFileSystem;
      BufferLogger testLogger;
      FakeCmakeProject mockCmakeProject;
      File managedCmakeFile;

      setUp(() {
        memoryFileSystem = MemoryFileSystem.test();
        managedCmakeFile = memoryFileSystem.file('CMakeLists.txtx');

        testLogger = BufferLogger(
          terminal: AnsiTerminal(
            stdio: null,
            platform: const LocalPlatform(),
          ),
          outputPreferences: OutputPreferences.test(),
        );

        mockCmakeProject = FakeCmakeProject(managedCmakeFile);
      });

      testWithoutContext('skipped if files are missing', () {
        final CmakeCustomCommandMigration cmakeProjectMigration = CmakeCustomCommandMigration(
          mockCmakeProject,
          testLogger,
        );
        expect(cmakeProjectMigration.migrate(), isTrue);
        expect(managedCmakeFile.existsSync(), isFalse);

        expect(testLogger.traceText, contains('CMake project not found, skipping add_custom_command() VERBATIM migration'));
        expect(testLogger.statusText, isEmpty);
      });

      testWithoutContext('skipped if nothing to migrate', () {
        const String contents = 'Nothing to migrate';
        managedCmakeFile.writeAsStringSync(contents);
        final DateTime projectLastModified = managedCmakeFile.lastModifiedSync();

        final CmakeCustomCommandMigration cmakeProjectMigration = CmakeCustomCommandMigration(
          mockCmakeProject,
          testLogger,
        );
        expect(cmakeProjectMigration.migrate(), isTrue);

        expect(managedCmakeFile.lastModifiedSync(), projectLastModified);
        expect(managedCmakeFile.readAsStringSync(), contents);

        expect(testLogger.statusText, isEmpty);
      });

      testWithoutContext('skipped if already migrated', () {
        const String contents = r'''
add_custom_command(
  OUTPUT ${FLUTTER_LIBRARY} ${FLUTTER_LIBRARY_HEADERS}
    ${CMAKE_CURRENT_BINARY_DIR}/_phony_
  COMMAND ${CMAKE_COMMAND} -E env
    ${FLUTTER_TOOL_ENVIRONMENT}
    "${FLUTTER_ROOT}/packages/flutter_tools/bin/tool_backend.sh"
      ${FLUTTER_TARGET_PLATFORM} ${CMAKE_BUILD_TYPE}
  VERBATIM
)
''';
        managedCmakeFile.writeAsStringSync(contents);
        final DateTime projectLastModified = managedCmakeFile.lastModifiedSync();

        final CmakeCustomCommandMigration cmakeProjectMigration = CmakeCustomCommandMigration(
          mockCmakeProject,
          testLogger,
        );
        expect(cmakeProjectMigration.migrate(), isTrue);

        expect(managedCmakeFile.lastModifiedSync(), projectLastModified);
        expect(managedCmakeFile.readAsStringSync(), contents);

        expect(testLogger.statusText, isEmpty);
      });

      testWithoutContext('is migrated to use VERBATIM', () {
        managedCmakeFile.writeAsStringSync(r'''
add_custom_command(
  OUTPUT ${FLUTTER_LIBRARY} ${FLUTTER_LIBRARY_HEADERS}
    ${CMAKE_CURRENT_BINARY_DIR}/_phony_
  COMMAND ${CMAKE_COMMAND} -E env
    ${FLUTTER_TOOL_ENVIRONMENT}
    "${FLUTTER_ROOT}/packages/flutter_tools/bin/tool_backend.sh"
      ${FLUTTER_TARGET_PLATFORM} ${CMAKE_BUILD_TYPE}
)
''');

        final CmakeCustomCommandMigration cmakeProjectMigration = CmakeCustomCommandMigration(
          mockCmakeProject,
          testLogger,
        );
        expect(cmakeProjectMigration.migrate(), isTrue);

        expect(managedCmakeFile.readAsStringSync(), r'''
add_custom_command(
  OUTPUT ${FLUTTER_LIBRARY} ${FLUTTER_LIBRARY_HEADERS}
    ${CMAKE_CURRENT_BINARY_DIR}/_phony_
  COMMAND ${CMAKE_COMMAND} -E env
    ${FLUTTER_TOOL_ENVIRONMENT}
    "${FLUTTER_ROOT}/packages/flutter_tools/bin/tool_backend.sh"
      ${FLUTTER_TARGET_PLATFORM} ${CMAKE_BUILD_TYPE}
  VERBATIM
)
''');

        expect(testLogger.statusText, contains('add_custom_command() missing VERBATIM or FLUTTER_TARGET_PLATFORM, updating.'));
      });

      testWithoutContext('is migrated to use FLUTTER_TARGET_PLATFORM', () {
        managedCmakeFile.writeAsStringSync(r'''
add_custom_command(
  OUTPUT ${FLUTTER_LIBRARY} ${FLUTTER_LIBRARY_HEADERS}
    ${CMAKE_CURRENT_BINARY_DIR}/_phony_
  COMMAND ${CMAKE_COMMAND} -E env
    ${FLUTTER_TOOL_ENVIRONMENT}
    "${FLUTTER_ROOT}/packages/flutter_tools/bin/tool_backend.sh"
      linux-x64 ${CMAKE_BUILD_TYPE}
  VERBATIM
)
''');

        final CmakeCustomCommandMigration cmakeProjectMigration = CmakeCustomCommandMigration(
          mockCmakeProject,
          testLogger,
        );
        expect(cmakeProjectMigration.migrate(), isTrue);

        expect(managedCmakeFile.readAsStringSync(), r'''
add_custom_command(
  OUTPUT ${FLUTTER_LIBRARY} ${FLUTTER_LIBRARY_HEADERS}
    ${CMAKE_CURRENT_BINARY_DIR}/_phony_
  COMMAND ${CMAKE_COMMAND} -E env
    ${FLUTTER_TOOL_ENVIRONMENT}
    "${FLUTTER_ROOT}/packages/flutter_tools/bin/tool_backend.sh"
      ${FLUTTER_TARGET_PLATFORM} ${CMAKE_BUILD_TYPE}
  VERBATIM
)
''');

        expect(testLogger.statusText, contains('add_custom_command() missing VERBATIM or FLUTTER_TARGET_PLATFORM, updating.'));
      });
    });
  });
}

class FakeCmakeProject extends Fake implements CmakeBasedProject {
  FakeCmakeProject(this.managedCmakeFile);

  @override
  final File managedCmakeFile;
}

class FakeCmakeMigrator extends ProjectMigrator {
  FakeCmakeMigrator({@required this.succeeds})
    : super(null);

  final bool succeeds;

  @override
  bool migrate() {
    return succeeds;
  }

  @override
  String migrateLine(String line) {
    return line;
  }
}
