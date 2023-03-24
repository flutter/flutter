// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../base/file_system.dart';
import '../../base/project_migrator.dart';
import '../../cmake_project.dart';

const String _cmakeFileBefore =
'# Apply the standard set of build settings. This can be removed for applications\r\n'
'# that need different build settings.\r\n'
'apply_standard_settings(\${BINARY_NAME})\r\n'
'\r\n'
'# Disable Windows macros that collide with C++ standard library functions.\r\n'
'target_compile_definitions(\${BINARY_NAME} PRIVATE "NOMINMAX")\r\n';
const String _cmakeFileAfter =
'# Apply the standard set of build settings. This can be removed for applications\r\n'
'# that need different build settings.\r\n'
'apply_standard_settings(\${BINARY_NAME})\r\n'
'\r\n'
'# Add preprocessor definitions for the build version.\r\n'
'target_compile_definitions(\${BINARY_NAME} PRIVATE "FLUTTER_VERSION=\\"\${FLUTTER_VERSION}\\"")\r\n'
'target_compile_definitions(\${BINARY_NAME} PRIVATE "FLUTTER_VERSION_MAJOR=\${FLUTTER_VERSION_MAJOR}")\r\n'
'target_compile_definitions(\${BINARY_NAME} PRIVATE "FLUTTER_VERSION_MINOR=\${FLUTTER_VERSION_MINOR}")\r\n'
'target_compile_definitions(\${BINARY_NAME} PRIVATE "FLUTTER_VERSION_PATCH=\${FLUTTER_VERSION_PATCH}")\r\n'
'target_compile_definitions(\${BINARY_NAME} PRIVATE "FLUTTER_VERSION_BUILD=\${FLUTTER_VERSION_BUILD}")\r\n'
'\r\n'
'# Disable Windows macros that collide with C++ standard library functions.\r\n'
'target_compile_definitions(\${BINARY_NAME} PRIVATE "NOMINMAX")\r\n';

const String _resourceFileBefore =
'#ifdef FLUTTER_BUILD_NUMBER\r\n'
'#define VERSION_AS_NUMBER FLUTTER_BUILD_NUMBER\r\n'
'#else\r\n'
'#define VERSION_AS_NUMBER 1,0,0\r\n'
'#endif\r\n'
'\r\n'
'#ifdef FLUTTER_BUILD_NAME\r\n'
'#define VERSION_AS_STRING #FLUTTER_BUILD_NAME\r\n'
'#else\r\n'
'#define VERSION_AS_STRING "1.0.0"\r\n'
'#endif\r\n';
const String _resourceFileAfter =
'#if defined(FLUTTER_VERSION_MAJOR) && defined(FLUTTER_VERSION_MINOR) && defined(FLUTTER_VERSION_PATCH) && defined(FLUTTER_VERSION_BUILD)\r\n'
'#define VERSION_AS_NUMBER FLUTTER_VERSION_MAJOR,FLUTTER_VERSION_MINOR,FLUTTER_VERSION_PATCH,FLUTTER_VERSION_BUILD\r\n'
'#else\r\n'
'#define VERSION_AS_NUMBER 1,0,0,0\r\n'
'#endif\r\n'
'\r\n'
'#if defined(FLUTTER_VERSION)\r\n'
'#define VERSION_AS_STRING FLUTTER_VERSION\r\n'
'#else\r\n'
'#define VERSION_AS_STRING "1.0.0"\r\n'
'#endif\r\n';

// Flutter should set the Windows app's version information.
// See https://github.com/flutter/flutter/issues/73652.
class VersionMigration extends ProjectMigrator {
  VersionMigration(WindowsProject project, super.logger)
    : _cmakeFile = project.runnerCmakeFile, _resourceFile = project.runnerResourceFile;

  final File _cmakeFile;
  final File _resourceFile;

  @override
  void migrate() {
    if (!_cmakeFile.existsSync()) {
      logger.printTrace('windows/runner/CMakeLists.txt file not found, skipping version migration');
      return;
    }

    if (!_resourceFile.existsSync()) {
      logger.printTrace('windows/runner/Runner.rc file not found, skipping version migration');
      return;
    }

    // Migrate the windows/runner/CMakeLists.txt file.
    final String originalCmakeContents = _cmakeFile.readAsStringSync();
    final String newCmakeContents = originalCmakeContents
      .replaceFirst(_cmakeFileBefore, _cmakeFileAfter);
    if (originalCmakeContents != newCmakeContents) {
      logger.printStatus('windows/runner/CMakeLists.txt does not define version information, updating.');
      _cmakeFile.writeAsStringSync(newCmakeContents);
    }

    // Migrate the windows/runner/Runner.rc file.
    final String originalResourceFileContents = _resourceFile.readAsStringSync();
    final String newResourceFileContents = originalResourceFileContents
      .replaceFirst(_resourceFileBefore, _resourceFileAfter);
    if (originalResourceFileContents != newResourceFileContents) {
      logger.printStatus(
        'windows/runner/Runner.rc does not define use Flutter version information, updating.',
      );
      _resourceFile.writeAsStringSync(newResourceFileContents);
    }
  }
}
