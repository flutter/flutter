// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../build_info.dart';
import '../globals.dart' as globals;
import '../ios/xcodeproj.dart';
import '../project.dart';
import 'cocoapod_utils.dart';

/// Builds the macOS project through xcodebuild.
// TODO(jonahwilliams): refactor to share code with the existing iOS code.
Future<void> buildMacOS({
  FlutterProject flutterProject,
  BuildInfo buildInfo,
  String targetOverride,
}) async {
  if (!flutterProject.macos.xcodeWorkspace.existsSync()) {
    throwToolExit('No macOS desktop project configured. '
      'See https://flutter.dev/desktop#add-desktop-support-to-an-existing-flutter-project '
      'to learn about adding macOS support to a project.');
  }

  final Directory flutterBuildDir = globals.fs.directory(getMacOSBuildDirectory());
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

  // If the standard project exists, specify it to getInfo to handle the case where there are
  // other Xcode projects in the macos/ directory. Otherwise pass no name, which will work
  // regardless of the project name so long as there is exactly one project.
  final String xcodeProjectName = xcodeProject.existsSync() ? xcodeProject.basename : null;
  final XcodeProjectInfo projectInfo = await globals.xcodeProjectInterpreter.getInfo(
    xcodeProject.parent.path,
    projectFilename: xcodeProjectName,
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
  final Status status = globals.logger.startProgress(
    'Building macOS application...',
    timeout: null,
  );
  int result;
  try {
    result = await globals.processUtils.stream(<String>[
      '/usr/bin/env',
      'xcrun',
      'xcodebuild',
      '-workspace', flutterProject.macos.xcodeWorkspace.path,
      '-configuration', configuration,
      '-scheme', 'Runner',
      '-derivedDataPath', flutterBuildDir.absolute.path,
      'OBJROOT=${globals.fs.path.join(flutterBuildDir.absolute.path, 'Build', 'Intermediates.noindex')}',
      'SYMROOT=${globals.fs.path.join(flutterBuildDir.absolute.path, 'Build', 'Products')}',
      'COMPILER_INDEX_STORE_ENABLE=NO',
      ...environmentVariablesAsXcodeBuildSettings(globals.platform)
    ], trace: true);
  } finally {
    status.cancel();
  }
  if (result != 0) {
    throwToolExit('Build process failed');
  }
  globals.flutterUsage.sendTiming('build', 'xcode-macos', Duration(milliseconds: sw.elapsedMilliseconds));
}
