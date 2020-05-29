// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../artifacts.dart';
import '../base/common.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/process.dart';
import '../base/utils.dart';
import '../build_info.dart';
import '../cache.dart';
import '../globals.dart' as globals;
import '../plugins.dart';
import '../project.dart';
import 'cmake.dart';

/// Builds the Linux project through the Makefile.
Future<void> buildLinux(
  LinuxProject linuxProject,
  BuildInfo buildInfo, {
    String target = 'lib/main.dart',
  }) async {
  if (!linuxProject.cmakeFile.existsSync()) {
    throwToolExit('No Linux desktop project configured. See '
      'https://github.com/flutter/flutter/wiki/Desktop-shells#create '
      'to learn about adding Linux support to a project.');
  }

  // Check for incompatibility between the Flutter tool version and the project
  // template version, since the tempalte isn't stable yet.
  final int templateCompareResult = _compareTemplateVersions(linuxProject);
  if (templateCompareResult < 0) {
    throwToolExit('The Linux runner was created with an earlier version of the '
      'template, which is not yet stable.\n\n'
      'Delete the linux/ directory and re-run \'flutter create .\', '
      're-applying any previous changes.');
  } else if (templateCompareResult > 0) {
    throwToolExit('The Linux runner was created with a newer version of the '
      'template, which is not yet stable.\n\n'
      'Upgrade Flutter and try again.');
  }

  // Build the environment that needs to be set for the re-entrant flutter build
  // step.
  final Map<String, String> environmentConfig = buildInfo.toEnvironmentConfig();
  environmentConfig['FLUTTER_TARGET'] = target;
  if (globals.artifacts is LocalEngineArtifacts) {
    final LocalEngineArtifacts localEngineArtifacts = globals.artifacts as LocalEngineArtifacts;
    final String engineOutPath = localEngineArtifacts.engineOutPath;
    environmentConfig['FLUTTER_ENGINE'] = globals.fs.path.dirname(globals.fs.path.dirname(engineOutPath));
    environmentConfig['LOCAL_ENGINE'] = globals.fs.path.basename(engineOutPath);
  }
  writeGeneratedCmakeConfig(Cache.flutterRoot, linuxProject, environmentConfig);

  createPluginSymlinks(linuxProject.project);

  if (!buildInfo.isDebug) {
    const String warning = '🚧 ';
    globals.printStatus(warning * 20);
    globals.printStatus('Warning: Only debug is currently implemented for Linux. This is effectively a debug build.');
    globals.printStatus('See https://github.com/flutter/flutter/issues/38478 for details and updates.');
    globals.printStatus(warning * 20);
    globals.printStatus('');
  }

  final Status status = globals.logger.startProgress(
    'Building Linux application...',
    timeout: null,
  );
  try {
    final String buildModeName = getNameForBuildMode(buildInfo.mode ?? BuildMode.release);
    final Directory buildDirectory = globals.fs.directory(getLinuxBuildDirectory()).childDirectory(buildModeName);
    await _runCmake(buildModeName, linuxProject.cmakeFile.parent, buildDirectory);
    await _runBuild(buildDirectory);
  } finally {
    status.cancel();
  }
}

Future<void> _runCmake(String buildModeName, Directory sourceDir, Directory buildDir) async {
  final Stopwatch sw = Stopwatch()..start();

  await buildDir.create(recursive: true);

  final String buildFlag = toTitleCase(buildModeName);
  int result;
  try {
    result = await processUtils.stream(
      <String>[
        'cmake',
        '-G',
        'Ninja',
        '-DCMAKE_BUILD_TYPE=$buildFlag',
        sourceDir.path,
      ],
      workingDirectory: buildDir.path,
      environment: <String, String>{
        'CC': 'clang',
        'CXX': 'clang++'
      },
      trace: true,
    );
  } on ArgumentError {
    throwToolExit("cmake not found. Run 'flutter doctor' for more information.");
  }
  if (result != 0) {
    throwToolExit('Unable to generate build files');
  }
  globals.flutterUsage.sendTiming('build', 'cmake-linux', Duration(milliseconds: sw.elapsedMilliseconds));
}

Future<void> _runBuild(Directory buildDir) async {
  final Stopwatch sw = Stopwatch()..start();

  int result;
  try {
    result = await processUtils.stream(
      <String>[
        'ninja',
        '-C',
        buildDir.path,
        'install',
      ],
      environment: <String, String>{
        if (globals.logger.isVerbose)
          'VERBOSE_SCRIPT_LOGGING': 'true'
      },
      trace: true,
    );
  } on ArgumentError {
    throwToolExit("ninja not found. Run 'flutter doctor' for more information.");
  }
  if (result != 0) {
    throwToolExit('Build process failed');
  }
  globals.flutterUsage.sendTiming('build', 'linux-ninja', Duration(milliseconds: sw.elapsedMilliseconds));
}

// Checks the template version of [project] against the current template
// version. Returns < 0 if the project is older than the current template, > 0
// if it's newer, and 0 if they match.
int _compareTemplateVersions(LinuxProject project) {
  const String projectVersionBasename = '.template_version';
  final int expectedVersion = int.parse(globals.fs.file(globals.fs.path.join(
    globals.fs.path.absolute(Cache.flutterRoot),
    'packages',
    'flutter_tools',
    'templates',
    'app',
    'linux.tmpl',
    'flutter',
    projectVersionBasename,
  )).readAsStringSync());
  final File projectVersionFile = project.managedDirectory.childFile(projectVersionBasename);
  final int version = projectVersionFile.existsSync()
      ? int.tryParse(projectVersionFile.readAsStringSync())
      : 0;
  return version.compareTo(expectedVersion);
}
