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

/// Builds the macOS project through xcode build.
// TODO(jonahwilliams): support target option.
// TODO(jonahwilliams): refactor to share code with the existing iOS code.
Future<void> buildMacOS(FlutterProject flutterProject, BuildInfo buildInfo) async {
  final Directory flutterBuildDir = fs.directory(getMacOSBuildDirectory());
  final String symrootOverride = fs.path.join(flutterBuildDir.absolute.path, 'Build', 'Products');
  if (!flutterBuildDir.existsSync()) {
    flutterBuildDir.createSync(recursive: true);
  }
  // Write configuration to an xconfig file in a standard location.
  await updateGeneratedXcodeProperties(
    project: flutterProject,
    buildInfo: buildInfo,
    useMacOSConfig: true,
    symrootOverride: symrootOverride,
  );
  // Set debug or release mode.
  String config = 'Debug';
  if (buildInfo.isRelease) {
    config = 'Release';
  }
  // Run build script provided by application.
  final Process process = await processManager.start(<String>[
    '/usr/bin/env',
    'xcrun',
    'xcodebuild',
    '-project', flutterProject.macos.xcodeProjectFile.path,
    '-configuration', '$config',
    '-scheme', 'Runner',
    '-derivedDataPath', flutterBuildDir.absolute.path,
    'OBJROOT=${fs.path.join(flutterBuildDir.absolute.path, 'Build', 'Intermediates.noindex')}',
    'SYMROOT=$symrootOverride',
  ], runInShell: true);
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
}
