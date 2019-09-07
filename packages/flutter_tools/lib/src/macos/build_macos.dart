// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/process_manager.dart';
import '../build_info.dart';
import '../convert.dart';
import '../globals.dart';
import '../ios/xcodeproj.dart';
import '../project.dart';
import '../reporting/reporting.dart';

import 'cocoapod_utils.dart';

/// Builds the macOS project through xcodebuild.
// TODO(jonahwilliams): refactor to share code with the existing iOS code.
Future<void> buildMacOS({
  FlutterProject flutterProject,
  BuildInfo buildInfo,
  String targetOverride,
}) async {
  final Directory flutterBuildDir = fs.directory(getMacOSBuildDirectory());
  if (!flutterBuildDir.existsSync()) {
    flutterBuildDir.createSync(recursive: true);
  }
  // Write configuration to an xconfig file in a standard location.
  await updateGeneratedXcodeProperties(
    project: flutterProject,
    buildInfo: buildInfo,
    targetOverride: targetOverride,
    useMacOSConfig: true,
    setSymroot: false,
  );
  await processPodsIfNeeded(flutterProject.macos, getMacOSBuildDirectory(), buildInfo.mode);
  // If the xcfilelists do not exist, create empty version.
  if (!flutterProject.macos.inputFileList.existsSync()) {
     flutterProject.macos.inputFileList.createSync(recursive: true);
  }
  if (!flutterProject.macos.outputFileList.existsSync()) {
    flutterProject.macos.outputFileList.createSync(recursive: true);
  }

  final Directory xcodeProject = flutterProject.macos.xcodeProject;

  final XcodeProjectInfo projectInfo = await xcodeProjectInterpreter.getInfo(
    xcodeProject.parent.path,
    projectFilename: xcodeProject.basename,
  );
  final String scheme = projectInfo.schemeFor(buildInfo);
  if (scheme == null) {
    throwToolExit('Unable to find expected scheme in Xcode project.');
  }
  final String configuration = projectInfo.buildConfigurationFor(buildInfo, scheme);
  if (configuration == null) {
    throwToolExit('Unable to find expected configuration in Xcode project.');
  }

  // Run the Xcode build.
  final Stopwatch sw = Stopwatch()..start();
  final Process process = await processManager.start(<String>[
    '/usr/bin/env',
    'xcrun',
    'xcodebuild',
    '-workspace', flutterProject.macos.xcodeWorkspace.path,
    '-configuration', '$configuration',
    '-scheme', 'Runner',
    '-derivedDataPath', flutterBuildDir.absolute.path,
    'OBJROOT=${fs.path.join(flutterBuildDir.absolute.path, 'Build', 'Intermediates.noindex')}',
    'SYMROOT=${fs.path.join(flutterBuildDir.absolute.path, 'Build', 'Products')}',
    'COMPILER_INDEX_STORE_ENABLE=NO',
  ]);
  final Status status = logger.startProgress(
    'Building macOS application...',
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
  flutterUsage.sendTiming('build', 'xcode-macos', Duration(milliseconds: sw.elapsedMilliseconds));
}
