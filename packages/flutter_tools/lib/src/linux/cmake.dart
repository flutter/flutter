// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../project.dart';

/// Extracts the `BINARY_NAME` from a Linux project CMake file.
///
/// Returns `null` if it cannot be found.
String getCmakeExecutableName(LinuxProject project) {
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

/// Writes a generated CMake configuration file for [project], including
/// variables expected by the build template and an environment variable list
/// for calling back into Flutter.
void writeGeneratedCmakeConfig(String flutterRoot, LinuxProject project, Map<String, String> environment) {
  // Only a limited set of variables are needed by the CMake files themselves,
  // the rest are put into a list to pass to the re-entrant build step.
  final StringBuffer buffer = StringBuffer('''
# Generated code do not commit.
set(FLUTTER_ROOT "$flutterRoot")
set(PROJECT_DIR "${project.project.directory.path}")

# Environment variables to pass to tool_backend.sh
list(APPEND FLUTTER_TOOL_ENVIRONMENT
  "FLUTTER_ROOT=\\"\${FLUTTER_ROOT}\\""
  "PROJECT_DIR=\\"\${PROJECT_DIR}\\""
''');
  for (final String key in environment.keys) {
    final String value = environment[key];
    buffer.writeln('  "$key=\\"$value\\""');
  }
  buffer.writeln(')');

  project.generatedCmakeConfigFile
    ..createSync(recursive: true)
    ..writeAsStringSync(buffer.toString());
}
