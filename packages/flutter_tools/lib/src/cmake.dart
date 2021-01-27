// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'project.dart';

/// Extracts the `BINARY_NAME` from a project's CMake file.
///
/// Returns `null` if it cannot be found.
String getCmakeExecutableName(CmakeBasedProject project) {
  if (!project.cmakeFile.existsSync()) {
    return null;
  }
  final RegExp nameSetPattern = RegExp(r'^\s*set\(BINARY_NAME\s*"(.*)"\s*\)\s*$');
  for (final String line in project.cmakeFile.readAsLinesSync()) {
    final RegExpMatch match = nameSetPattern.firstMatch(line);
    if (match != null) {
      return match.group(1);
    }
  }
  return null;
}

String _escapeBackslashes(String s) {
  return s.replaceAll(r'\', r'\\');
}

/// Writes a generated CMake configuration file for [project], including
/// variables expected by the build template and an environment variable list
/// for calling back into Flutter.
void writeGeneratedCmakeConfig(String flutterRoot, CmakeBasedProject project, Map<String, String> environment) {
  // Only a limited set of variables are needed by the CMake files themselves,
  // the rest are put into a list to pass to the re-entrant build step.
  final String escapedFlutterRoot = _escapeBackslashes(flutterRoot);
  final String escapedProjectDir = _escapeBackslashes(project.parent.directory.path);
  final StringBuffer buffer = StringBuffer('''
# Generated code do not commit.
file(TO_CMAKE_PATH "$escapedFlutterRoot" FLUTTER_ROOT)
file(TO_CMAKE_PATH "$escapedProjectDir" PROJECT_DIR)

# Environment variables to pass to tool_backend.sh
list(APPEND FLUTTER_TOOL_ENVIRONMENT
  "FLUTTER_ROOT=$escapedFlutterRoot"
  "PROJECT_DIR=$escapedProjectDir"
''');
  for (final String key in environment.keys) {
    final String value = _escapeBackslashes(environment[key]);
    buffer.writeln('  "$key=$value"');
  }
  buffer.writeln(')');

  project.generatedCmakeConfigFile
    ..createSync(recursive: true)
    ..writeAsStringSync(buffer.toString());
}
