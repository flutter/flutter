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
import '../build_system/output_formats.dart';
import '../build_system/targets/dart.dart';
import '../convert.dart';
import '../globals.dart';
import '../ios/xcodeproj.dart';
import '../project.dart';
import '../usage.dart';
import 'application_package.dart';

/// Builds the macOS project through xcodebuild and returns the executable path.
// TODO(jonahwilliams): refactor to share code with the existing iOS code.
Future<String> buildMacOS({
  FlutterProject flutterProject,
  BuildInfo buildInfo,
  String targetOverride,
}) async {
  final Stopwatch sw = Stopwatch()..start();
  final Map<String, String> defines = buildSystem.collectDefines('debug_macos_application', <String, String>{
    kBuildMode: 'debug',
    kTargetFile: fs.path.absolute(targetOverride ?? 'lib/main.dart'),
  });
  final Environment environment = Environment(
    projectDir: flutterProject.directory, defines: defines);

  // Write configuration to an xconfig file in a standard location.
  await updateGeneratedXcodeProperties(
    project: flutterProject,
    buildInfo: buildInfo,
    targetOverride: targetOverride,
    useMacOSConfig: true,
    setSymroot: false,
    buildDirOverride: environment.buildDir,
  );
  final Status status = logger.startProgress(
    'Building macOS application...',
    timeout: null,
  );
  final BuildResult buildResult = await buildSystem.build(
      'debug_macos_application', environment, const BuildSystemConfig());
  if (buildResult.hasException) {
    for (ExceptionMeasurement exception in buildResult.exceptions.values) {
      printError(exception.exception.toString());
      printError(exception.stackTrace.toString());
    }
    throwToolExit('error building macOS application');
  }
  generateXcFileList('debug_macos_application',
      environment, flutterProject.directory.childDirectory('macos').path);

  // Set debug or release mode.
  const String config = 'Debug';
  final Process process = await processManager.start(<String>[
    '/usr/bin/env',
    'xcrun',
    'xcodebuild',
    '-workspace', flutterProject.macos.xcodeWorkspace.path,
    '-configuration', '$config',
    '-scheme', 'Runner',
    '-derivedDataPath', environment.buildDir.absolute.path,
    'OBJROOT=${fs.path.join(environment.buildDir.absolute.path, 'Build', 'Intermediates.noindex')}',
    'SYMROOT=${fs.path.join(environment.buildDir.absolute.path, 'Build', 'Products')}',
  ], runInShell: true);
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
  printStatus('build macos took ${sw.elapsedMilliseconds}');
  final File appBundleNameFile = flutterProject.macos.nameFile;
  if (!appBundleNameFile.existsSync()) {
    printError('Unable to find app name. ${appBundleNameFile.path} does not exist');
    return null;
  }
  final String applicationBundle = fs.path.join(
    environment.buildDir.path,
    'Build',
    'Products',
    'Debug',
    appBundleNameFile.readAsStringSync().trim());
  final ExecutableAndId executableAndId = MacOSApp.executableFromBundle(fs.directory(applicationBundle));
  return executableAndId.executable;
}
