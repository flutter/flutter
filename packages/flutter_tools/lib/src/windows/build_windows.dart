// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file

import '../artifacts.dart';
import '../base/common.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/process_manager.dart';
import '../build_info.dart';
import '../cache.dart';
import '../convert.dart';
import '../globals.dart';
import '../project.dart';
import '../reporting/reporting.dart';

import 'msbuild_utils.dart';
import 'visual_studio.dart';

/// Builds the Windows project using msbuild.
Future<void> buildWindows(WindowsProject windowsProject, BuildInfo buildInfo, {String target}) async {
  final Map<String, String> environment = <String, String>{
    'FLUTTER_ROOT': Cache.flutterRoot,
    'FLUTTER_EPHEMERAL_DIR': windowsProject.ephemeralDirectory.path,
    'PROJECT_DIR': windowsProject.project.directory.path,
    'TRACK_WIDGET_CREATION': (buildInfo?.trackWidgetCreation == true).toString(),
  };
  if (target != null) {
    environment['FLUTTER_TARGET'] = target;
  }
  if (artifacts is LocalEngineArtifacts) {
    final LocalEngineArtifacts localEngineArtifacts = artifacts;
    final String engineOutPath = localEngineArtifacts.engineOutPath;
    environment['FLUTTER_ENGINE'] = fs.path.dirname(fs.path.dirname(engineOutPath));
    environment['LOCAL_ENGINE'] = fs.path.basename(engineOutPath);
  }
  writePropertySheet(windowsProject.generatedPropertySheetFile, environment);

  final String vcvarsScript = visualStudio.vcvarsPath;
  if (vcvarsScript == null) {
    throwToolExit('Unable to find suitable Visual Studio toolchain. '
        'Please run `flutter doctor` for more details.');
  }

  if (!buildInfo.isDebug) {
    const String warning = '🚧 ';
    printStatus(warning * 20);
    printStatus('Warning: Only debug is currently implemented for Windows. This is effectively a debug build.');
    printStatus('See https://github.com/flutter/flutter/issues/38477 for details and updates.');
    printStatus(warning * 20);
    printStatus('');
  }

  final String buildScript = fs.path.join(
    Cache.flutterRoot,
    'packages',
    'flutter_tools',
    'bin',
    'vs_build.bat',
  );

  final String configuration = buildInfo.isDebug ? 'Debug' : 'Release';
  final String solutionPath = windowsProject.solutionFile.path;
  final Stopwatch sw = Stopwatch()..start();
  // Run the script with a relative path to the project using the enclosing
  // directory as the workingDirectory, to avoid hitting the limit on command
  // lengths in batch scripts if the absolute path to the project is long.
  final Process process = await processManager.start(<String>[
    buildScript,
    vcvarsScript,
    fs.path.basename(solutionPath),
    configuration,
  ], workingDirectory: fs.path.dirname(solutionPath));
  final Status status = logger.startProgress(
    'Building Windows application...',
    timeout: null,
  );
  int result;
  try {
    process.stderr
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen(printError);
    process.stdout
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen(printTrace);
    result = await process.exitCode;
  } finally {
    status.cancel();
  }
  if (result != 0) {
    throwToolExit('Build process failed. To view the stack trace, please run `flutter run -d windows -v`.');
  }
  flutterUsage.sendTiming('build', 'vs_build', Duration(milliseconds: sw.elapsedMilliseconds));
}
