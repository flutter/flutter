// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../base/file_system.dart';
import '../../base/project_migrator.dart';
import '../../cmake_project.dart';

const String _cmakeTrigger1 =
'install(FILES "\${FLUTTER_LIBRARY}" DESTINATION "\${INSTALL_BUNDLE_LIB_DIR}"\r\n'
'  COMPONENT Runtime)\r\n'
'\r\n'
'if(PLUGIN_BUNDLED_LIBRARIES)\r\n';
const String _cmakeReplacement1 =
'install(FILES "\${FLUTTER_LIBRARY}" DESTINATION "\${INSTALL_BUNDLE_LIB_DIR}"\r\n'
'  COMPONENT Runtime)\r\n'
'\r\n'
'install(FILES "\${FLUTTER_SYMBOLS}" DESTINATION "\${INSTALL_BUNDLE_LIB_DIR}"\r\n'
'  COMPONENT Runtime)\r\n'
'\r\n'
'if(PLUGIN_BUNDLED_LIBRARIES)\r\n';

const String _managedCmakeTrigger1 =
'set(FLUTTER_LIBRARY "\${EPHEMERAL_DIR}/flutter_windows.dll")\r\n'
'\r\n';
const String _managedCmakeReplacement1 =
'set(FLUTTER_LIBRARY "\${EPHEMERAL_DIR}/flutter_windows.dll")\r\n'
'set(FLUTTER_SYMBOLS "\${EPHEMERAL_DIR}/flutter_windows.dll.pdb")\r\n'
'\r\n';

const String _managedCmakeTrigger2 =
'set(FLUTTER_LIBRARY \${FLUTTER_LIBRARY} PARENT_SCOPE)\r\n'
'set(FLUTTER_ICU_DATA_FILE "\${EPHEMERAL_DIR}/icudtl.dat" PARENT_SCOPE)\r\n'
'\r\n';
const String _managedCmakeReplacement2 =
'set(FLUTTER_LIBRARY \${FLUTTER_LIBRARY} PARENT_SCOPE)\r\n'
'set(FLUTTER_SYMBOLS \${FLUTTER_SYMBOLS} PARENT_SCOPE)\r\n'
'set(FLUTTER_ICU_DATA_FILE "\${EPHEMERAL_DIR}/icudtl.dat" PARENT_SCOPE)\r\n'
'\r\n';

// The Flutter engine symbols should be copied to the build directory.
// See https://github.com/flutter/flutter/issues/119363.
class EngineSymbolsMigration extends ProjectMigrator {
  EngineSymbolsMigration(WindowsProject project, super.logger)
    : _cmakeFile = project.cmakeFile, _managedCmakeFile = project.managedCmakeFile;

  final File _cmakeFile;
  final File _managedCmakeFile;

  @override
  void migrate() {
    if (!_cmakeFile.existsSync() || !_managedCmakeFile.existsSync()) {
      logger.printTrace('CMake project files not found, skipping engine symbols migration');
      return;
    }

    // Migrate the windows/CMakeLists.txt.
    final String originalCmakeContents = _cmakeFile.readAsStringSync();
    final String newCmakeContents = originalCmakeContents.replaceFirst(_cmakeTrigger1, _cmakeReplacement1);
    if (originalCmakeContents != newCmakeContents) {
      logger.printStatus('windows/CMakeLists.txt does not install engine symbols, updating.');
      _cmakeFile.writeAsStringSync(newCmakeContents);
    }

    // Migrate windows/flutter/CMakeLists.txt.
    final String originalManagedCmakeContents = _managedCmakeFile.readAsStringSync();
    final String newManagedCmakeContents = originalManagedCmakeContents
      .replaceFirst(_managedCmakeTrigger1, _managedCmakeReplacement1)
      .replaceFirst(_managedCmakeTrigger2, _managedCmakeReplacement2);
    if (originalManagedCmakeContents != newManagedCmakeContents) {
      logger.printStatus('windows/flutter/CMakeLists.txt does not define engine symbols, updating.');
      _managedCmakeFile.writeAsStringSync(newManagedCmakeContents);
    }
  }
}
