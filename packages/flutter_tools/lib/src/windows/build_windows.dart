// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file

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
import 'msbuild_utils.dart';

/// Builds the Windows project using msbuild.
Future<void> buildWindows(WindowsProject windowsProject, BuildInfo buildInfo, {String target = 'lib/main.dart'}) async {
  final Map<String, String> environment = <String, String>{
    'FLUTTER_ROOT': Cache.flutterRoot,
    'FLUTTER_TARGET': target,
    'PROJECT_DIR': windowsProject.project.directory.path,
    'TRACK_WIDGET_CREATION': (buildInfo?.trackWidgetCreation == true).toString(),
  };
  writePropertySheet(windowsProject.generatedPropertySheetFile, environment);

  final String vcvarsScript = await findVcvars();
  if (vcvarsScript == null) {
    throwToolExit('Unable to build: could not find vcvars64.bat');
  }

  final String buildScript = fs.path.join(
    Cache.flutterRoot,
    'packages',
    'flutter_tools',
    'bin',
    'vs_build.bat',
  );

  final String configuration = buildInfo.isDebug ? 'Debug' : 'Release';
  final String projectPath = windowsProject.vcprojFile.path;
  // Run the script with a relative path to the project using the enclosing
  // directory as the workingDirectory, to avoid hitting the limit on command
  // lengths in batch scripts if the absolute path to the project is long.
  final Process process = await processManager.start(<String>[
    buildScript,
    vcvarsScript,
    fs.path.basename(projectPath),
    configuration,
  ], workingDirectory: fs.path.dirname(projectPath));
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
    throwToolExit('Build process failed');
  }
}
