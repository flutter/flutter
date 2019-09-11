// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io'; // ignore: dart_io_import.
import 'package:path/path.dart' as path; // ignore: package_path_import.

/// Executes the required flutter tasks for a desktop build.
Future<void> main(List<String> arguments) async {
  final String targetPlatform = arguments[0];
  final String buildMode = arguments[1];

  final String projectDirectory = Platform.environment['PROJECT_DIR'];
  final bool verbose = Platform.environment['VERBOSE_SCRIPT_LOGGING'] != null;
  final bool trackWidgetCreation = Platform.environment['TRACK_WIDGET_CREATION'] != null;
  final String flutterTarget = Platform.environment['FLUTTER_TARGET'] ?? path.join('lib', 'main.dart');
  final String flutterEngine = Platform.environment['FLUTTER_ENGINE'];
  final String localEngine = Platform.environment['LOCAL_ENGINE'];
  final String flutterRoot = Platform.environment['FLUTTER_ROOT'];

  Directory.current = projectDirectory;

  if (localEngine != null && !localEngine.contains(buildMode)) {
    stderr.write('''
ERROR: Requested build with Flutter local engine at '$localEngine'
This engine is not compatible with FLUTTER_BUILD_MODE: '$buildMode'.
You can fix this by updating the LOCAL_ENGINE environment variable, or
by running:
  flutter build <platform> --local-engine=host_$buildMode
or
  flutter build <platform> --local-engine=host_${buildMode}_unopt
========================================================================
''');
    exit(1);
  }

  String cacheDirectory;
  switch (targetPlatform) {
    case 'linux-x64':
      cacheDirectory = 'linux/flutter';
      break;
    case 'windows-x64':
      cacheDirectory = 'windows/flutter/ephemeral';
      break;
    default:
      stderr.write('Unsupported target platform $targetPlatform');
      exit(1);
  }

  final String flutterExecutable = path.join(
      flutterRoot, 'bin', Platform.isWindows ? 'flutter.bat' : 'flutter');
  final ProcessResult unpackResult = await Process.run(
    flutterExecutable,
    <String>[
      '--suppress-analytics',
      if (verbose) '--verbose',
      'unpack',
      '--target-platform=$targetPlatform',
      '--cache-dir=$cacheDirectory',
      if (flutterEngine != null) '--local-engine-src-path=$flutterEngine',
      if (localEngine != null) '--local-engine=$localEngine',
    ]);
  if (unpackResult.exitCode != 0) {
    stderr.write(unpackResult.stderr);
    exit(1);
  }
  final ProcessResult buildResult = await Process.run(
    flutterExecutable,
    <String>[
      '--suppress-analytics',
      if (verbose) '--verbose',
      'build',
      'bundle',
      '--target=$flutterTarget',
      '--target-platform=$targetPlatform',
      if (trackWidgetCreation) '--track-widget-creation',
      if (flutterEngine != null) '--local-engine-src-path=$flutterEngine',
      if (localEngine != null) '--local-engine=$localEngine',
    ]);
  if (buildResult.exitCode != 0) {
    stderr.write(buildResult.stderr);
    exit(1);
  }
  exit(0);
}
