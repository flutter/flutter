// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/process_manager.dart';
import '../build_info.dart';
import '../build_system/build_system.dart';
import '../build_system/targets/dart.dart';
import '../convert.dart';
import '../globals.dart';
import '../ios/xcodeproj.dart';
import '../project.dart';
import '../reporting/reporting.dart';
import 'application_package.dart';

/// Builds the macOS project through xcodebuild and returns the app bundle.
Future<PrebuiltMacOSApp> buildMacOS({
  FlutterProject flutterProject,
  BuildInfo buildInfo,
  String targetOverride = 'lib/main.dart',
}) async {
  // Create the environment used to process the build. This needs to match what
  // is provided in bin/macos_build_flutter_assets.sh otherwise the directories
  // will be different.
  final Environment environment = Environment(
    projectDir: flutterProject.directory,
    buildDir: flutterProject.dartTool.childDirectory('flutter_build'),
    defines: <String, String>{
      kBuildMode: buildInfo.isDebug == true ? 'debug' : 'release',
      kTargetPlatform: 'darwin-x64',
      kTargetFile: fs.file(targetOverride).absolute.path
    },
  );

  // Write configuration to an xconfig file in a standard location.
  await updateGeneratedXcodeProperties(
    project: flutterProject,
    buildInfo: buildInfo,
    targetOverride: targetOverride,
    useMacOSConfig: true,
    setSymroot: false,
    buildDirOverride: environment.buildDir.path,
  );
  // If the xcfilelists do not exist, create empty version.
  if (!flutterProject.macos.inputFileList.existsSync()) {
    flutterProject.macos.inputFileList.createSync(recursive: true);
  }
  if (!flutterProject.macos.outputFileList.existsSync()) {
    flutterProject.macos.outputFileList.createSync(recursive: true);
  }
  // Set debug or release mode.
  String config = 'Debug';
  if (buildInfo.isRelease ?? false) {
    config = 'Release';
  }
  // Invoke Xcode with correct configuration.
  final Stopwatch sw = Stopwatch()..start();
  final List<String> command = <String>[
    '/usr/bin/env',
    'xcrun',
    'xcodebuild',
    '-workspace', flutterProject.macos.xcodeWorkspace.path,
    '-configuration', config,
    '-scheme', 'Runner',
    '-derivedDataPath', environment.buildDir.path,
    'OBJROOT=${fs.path.join(environment.buildDir.path, 'Build', 'Intermediates.noindex')}',
    'SYMROOT=${fs.path.join(environment.buildDir.path, 'Build', 'Products')}',
  ];
  final Process process = await processManager.start(command);
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
  final File appBundleNameFile = flutterProject.macos.nameFile;
  final Directory bundleDir = fs.directory(fs.path.join(
    environment.buildDir.path,
    'Build',
    'Products',
    buildInfo.mode == BuildMode.debug ? 'Debug' : 'Release',
    appBundleNameFile.readAsStringSync().trim(),
  ));
  return MacOSApp.fromPrebuiltApp(bundleDir);
}
