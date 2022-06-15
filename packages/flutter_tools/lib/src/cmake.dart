// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:pub_semver/pub_semver.dart';

import 'build_info.dart';
import 'cmake_project.dart';
import 'flutter_manifest.dart';
import 'globals.dart' as globals;

/// Extracts the `BINARY_NAME` from a project's CMake file.
///
/// Returns `null` if it cannot be found.
String? getCmakeExecutableName(CmakeBasedProject project) {
  if (!project.cmakeFile.existsSync()) {
    return null;
  }
  final RegExp nameSetPattern = RegExp(r'^\s*set\(BINARY_NAME\s*"(.*)"\s*\)\s*$');
  for (final String line in project.cmakeFile.readAsLinesSync()) {
    final RegExpMatch? match = nameSetPattern.firstMatch(line);
    if (match != null) {
      return match.group(1);
    }
  }
  return null;
}

String _escapeBackslashes(String s) {
  return s.replaceAll(r'\', r'\\');
}

Version _parseBuildName(String buildName) {
  try {
    return Version.parse(buildName);
  } on FormatException {
    globals.printWarning('Warning: could not parse build name $buildName, defaulting to 1.0.0.');

    return Version(1, 0, 0);
  }
}

/// Writes a generated CMake configuration file for [project], including
/// variables expected by the build template and an environment variable list
/// for calling back into Flutter.
void writeGeneratedCmakeConfig(
  String flutterRoot,
  CmakeBasedProject project,
  BuildInfo buildInfo,
  Map<String, String> environment) {
  // Only a limited set of variables are needed by the CMake files themselves,
  // the rest are put into a list to pass to the re-entrant build step.
  final String escapedFlutterRoot = _escapeBackslashes(flutterRoot);
  final String escapedProjectDir = _escapeBackslashes(project.parent.directory.path);
  final FlutterManifest manifest = project.parent.manifest;
  final String buildName = buildInfo.buildName ?? manifest.buildName ?? '1.0.0';
  final String buildNumber = buildInfo.buildNumber ?? manifest.buildNumber ?? '1';
  final Version buildVersion = _parseBuildName(buildName);
  final StringBuffer buffer = StringBuffer('''
# Generated code do not commit.
file(TO_CMAKE_PATH "$escapedFlutterRoot" FLUTTER_ROOT)
file(TO_CMAKE_PATH "$escapedProjectDir" PROJECT_DIR)

set(FLUTTER_BUILD_NAME "$buildVersion" PARENT_SCOPE)
set(FLUTTER_BUILD_MAJOR ${buildVersion.major} PARENT_SCOPE)
set(FLUTTER_BUILD_MINOR ${buildVersion.minor} PARENT_SCOPE)
set(FLUTTER_BUILD_PATCH ${buildVersion.patch} PARENT_SCOPE)
set(FLUTTER_BUILD_NUMBER $buildNumber PARENT_SCOPE)

# Environment variables to pass to tool_backend.sh
list(APPEND FLUTTER_TOOL_ENVIRONMENT
  "FLUTTER_ROOT=$escapedFlutterRoot"
  "PROJECT_DIR=$escapedProjectDir"
''');
  environment.forEach((String key, String value) {
    final String configValue = _escapeBackslashes(value);
    buffer.writeln('  "$key=$configValue"');
  });
  buffer.writeln(')');

  project.generatedCmakeConfigFile
    ..createSync(recursive: true)
    ..writeAsStringSync(buffer.toString());
}
