// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert'; // ignore: dart_convert_import.
import 'dart:io'; // ignore: dart_io_import.
import 'package:path/path.dart' as path; // ignore: package_path_import.

/// Executes the required flutter tasks for a desktop build.
Future<void> main(List<String> arguments) async {
  final String targetPlatform = arguments[0];
  final String buildMode = arguments[1].toLowerCase();

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

  final String flutterExecutable = path.join(
    flutterRoot, 'bin', Platform.isWindows ? 'flutter.bat' : 'flutter');
  final String target = targetPlatform == 'windows-x64'
    ? 'debug_bundle_windows_assets'
    : 'debug_bundle_linux_assets';

  // TODO(jonahwilliams): currently all builds are debug builds. Remove the
  // hardcoded mode when profile and release support is added.
  final Process assembleProcess = await Process.start(
    flutterExecutable,
    <String>[
      if (verbose)
        '--verbose',
      if (flutterEngine != null) '--local-engine-src-path=$flutterEngine',
      if (localEngine != null) '--local-engine=$localEngine',
      'assemble',
      if (trackWidgetCreation)
        '-dTrackWidgetCreation=$trackWidgetCreation',
      '-dTargetPlatform=$targetPlatform',
      '-dBuildMode=debug',
      '-dTargetFile=$flutterTarget',
      '--output=build',
      target,
    ],
  );
  assembleProcess.stdout
    .transform(utf8.decoder)
    .transform(const LineSplitter())
    .listen(stdout.writeln);
  assembleProcess.stderr
    .transform(utf8.decoder)
    .transform(const LineSplitter())
    .listen(stderr.writeln);

  if (await assembleProcess.exitCode != 0) {
    exit(1);
  }
}
