// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/cmake_project.dart';
import 'package:flutter_tools/src/windows/migrations/engine_symbols_migration.dart';
import 'package:test/fake.dart';

import '../../../src/common.dart';

void main () {
  group('Windows Flutter engine symbols migration', () {
    group('migrate CMake to copy engine symbols', () {
      late MemoryFileSystem memoryFileSystem;
      late BufferLogger testLogger;
      late FakeWindowsProject mockProject;
      late File cmakeFile;
      late File managedCmakeFile;

      setUp(() {
        memoryFileSystem = MemoryFileSystem.test();
        cmakeFile = memoryFileSystem.file('CmakeLists1.txt');
        managedCmakeFile = memoryFileSystem.file('CMakeLists2.txt');

        testLogger = BufferLogger(
          terminal: Terminal.test(),
          outputPreferences: OutputPreferences.test(),
        );

        mockProject = FakeWindowsProject(cmakeFile, managedCmakeFile);
      });

      testWithoutContext('skipped if files are missing', () {
        final EngineSymbolsMigration migration = EngineSymbolsMigration(
          mockProject,
          testLogger,
        );
        migration.migrate();
        expect(cmakeFile.existsSync(), isFalse);
        expect(managedCmakeFile.existsSync(), isFalse);

        expect(testLogger.traceText, contains('CMake project files not found, skipping engine symbols migration'));
        expect(testLogger.statusText, isEmpty);
      });

      testWithoutContext('skipped if nothing to migrate', () {
        const String cmakeContents = 'Nothing to migrate';
        const String managedCmakeContents = 'Nothing to migrate';

        cmakeFile.writeAsStringSync(cmakeContents);
        managedCmakeFile.writeAsStringSync(managedCmakeContents);

        final DateTime cmakeUpdatedAt = cmakeFile.lastModifiedSync();
        final DateTime managedCmakeUpdatedAt = managedCmakeFile.lastModifiedSync();

        final EngineSymbolsMigration cmakeProjectMigration = EngineSymbolsMigration(
          mockProject,
          testLogger,
        );
        cmakeProjectMigration.migrate();

        expect(cmakeFile.lastModifiedSync(), cmakeUpdatedAt);
        expect(cmakeFile.readAsStringSync(), cmakeContents);
        expect(managedCmakeFile.lastModifiedSync(), managedCmakeUpdatedAt);
        expect(managedCmakeFile.readAsStringSync(), managedCmakeContents);

        expect(testLogger.statusText, isEmpty);
      });

      testWithoutContext('skipped if already migrated', () {
        const String cmakeContents =
          'install(FILES "\${FLUTTER_LIBRARY}" DESTINATION "\${INSTALL_BUNDLE_LIB_DIR}"\r\n'
          '  COMPONENT Runtime)\r\n'
          '\r\n'
          'install(FILES "\${FLUTTER_SYMBOLS}" DESTINATION "\${INSTALL_BUNDLE_LIB_DIR}"\r\n'
          '  COMPONENT Runtime)\r\n'
          '\r\n'
          'if(PLUGIN_BUNDLED_LIBRARIES)\r\n';
        const String managedCmakeContents =
          'set(FLUTTER_LIBRARY "\${EPHEMERAL_DIR}/flutter_windows.dll")\r\n'
          'set(FLUTTER_SYMBOLS "\${EPHEMERAL_DIR}/flutter_windows.dll.pdb")\r\n'
          '\r\n'
          'set(FLUTTER_LIBRARY \${FLUTTER_LIBRARY} PARENT_SCOPE)\r\n'
          'set(FLUTTER_SYMBOLS \${FLUTTER_SYMBOLS} PARENT_SCOPE)\r\n'
          'set(FLUTTER_ICU_DATA_FILE "\${EPHEMERAL_DIR}/icudtl.dat" PARENT_SCOPE)\r\n';

        cmakeFile.writeAsStringSync(cmakeContents);
        managedCmakeFile.writeAsStringSync(managedCmakeContents);

        final DateTime cmakeUpdatedAt = cmakeFile.lastModifiedSync();
        final DateTime managedCmakeUpdatedAt = managedCmakeFile.lastModifiedSync();

        final EngineSymbolsMigration cmakeProjectMigration = EngineSymbolsMigration(
          mockProject,
          testLogger,
        );
        cmakeProjectMigration.migrate();

        expect(cmakeFile.lastModifiedSync(), cmakeUpdatedAt);
        expect(cmakeFile.readAsStringSync(), cmakeContents);
        expect(managedCmakeFile.lastModifiedSync(), managedCmakeUpdatedAt);
        expect(managedCmakeFile.readAsStringSync(), managedCmakeContents);

        expect(testLogger.statusText, isEmpty);
      });

      testWithoutContext('is migrated to copy engine symbols', () {
        cmakeFile.writeAsStringSync(
          'install(FILES "\${FLUTTER_LIBRARY}" DESTINATION "\${INSTALL_BUNDLE_LIB_DIR}"\r\n'
          '  COMPONENT Runtime)\r\n'
          '\r\n'
          'if(PLUGIN_BUNDLED_LIBRARIES)\r\n'
        );
        managedCmakeFile.writeAsStringSync(
          'set(FLUTTER_LIBRARY "\${EPHEMERAL_DIR}/flutter_windows.dll")\r\n'
          '\r\n'
          'set(FLUTTER_LIBRARY \${FLUTTER_LIBRARY} PARENT_SCOPE)\r\n'
          'set(FLUTTER_ICU_DATA_FILE "\${EPHEMERAL_DIR}/icudtl.dat" PARENT_SCOPE)\r\n'
        );

        final EngineSymbolsMigration cmakeProjectMigration = EngineSymbolsMigration(
          mockProject,
          testLogger,
        );
        cmakeProjectMigration.migrate();

        expect(cmakeFile.readAsStringSync(),
          'install(FILES "\${FLUTTER_LIBRARY}" DESTINATION "\${INSTALL_BUNDLE_LIB_DIR}"\r\n'
          '  COMPONENT Runtime)\r\n'
          '\r\n'
          'install(FILES "\${FLUTTER_SYMBOLS}" DESTINATION "\${INSTALL_BUNDLE_LIB_DIR}"\r\n'
          '  COMPONENT Runtime)\r\n'
          '\r\n'
          'if(PLUGIN_BUNDLED_LIBRARIES)\r\n'
        );
        expect(managedCmakeFile.readAsStringSync(),
          'set(FLUTTER_LIBRARY "\${EPHEMERAL_DIR}/flutter_windows.dll")\r\n'
          'set(FLUTTER_SYMBOLS "\${EPHEMERAL_DIR}/flutter_windows.dll.pdb")\r\n'
          '\r\n'
          'set(FLUTTER_LIBRARY \${FLUTTER_LIBRARY} PARENT_SCOPE)\r\n'
          'set(FLUTTER_SYMBOLS \${FLUTTER_SYMBOLS} PARENT_SCOPE)\r\n'
          'set(FLUTTER_ICU_DATA_FILE "\${EPHEMERAL_DIR}/icudtl.dat" PARENT_SCOPE)\r\n'
        );

        expect(testLogger.statusText, contains('windows/CMakeLists.txt does not install engine symbols, updating.'));
        expect(testLogger.statusText, contains('windows/flutter/CMakeLists.txt does not define engine symbols, updating.'));
      });
    });
  });
}

class FakeWindowsProject extends Fake implements WindowsProject {
  FakeWindowsProject(this.cmakeFile, this.managedCmakeFile);

  @override
  final File cmakeFile;

  @override
  final File managedCmakeFile;
}
