// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../artifacts.dart';
import '../base/analyze_size.dart';
import '../base/common.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/process.dart';
import '../base/utils.dart';
import '../build_info.dart';
import '../cache.dart';
import '../cmake.dart';
import '../convert.dart';
import '../globals.dart' as globals;
import '../plugins.dart';
import '../project.dart';

/// Builds the Linux project through the Makefile.
Future<void> buildLinux(
  LinuxProject linuxProject,
  BuildInfo buildInfo, {
    String target = 'lib/main.dart',
    SizeAnalyzer sizeAnalyzer,
  }) async {
  if (!linuxProject.cmakeFile.existsSync()) {
    throwToolExit('No Linux desktop project configured. See '
      'https://github.com/flutter/flutter/wiki/Desktop-shells#create '
      'to learn about adding Linux support to a project.');
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

  createPluginSymlinks(linuxProject.parent);

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
  if (buildInfo.codeSizeDirectory != null && sizeAnalyzer != null) {
    final String arch = getNameForTargetPlatform(TargetPlatform.linux_x64);
    final File codeSizeFile = globals.fs.directory(buildInfo.codeSizeDirectory)
      .childFile('snapshot.$arch.json');
    final File precompilerTrace = globals.fs.directory(buildInfo.codeSizeDirectory)
      .childFile('trace.$arch.json');
    final Map<String, Object> output = await sizeAnalyzer.analyzeAotSnapshot(
      aotSnapshot: codeSizeFile,
      // This analysis is only supported for release builds.
      outputDirectory: globals.fs.directory(
        globals.fs.path.join(getLinuxBuildDirectory(), 'release', 'bundle'),
      ),
      precompilerTrace: precompilerTrace,
      type: 'linux',
    );
    final File outputFile = globals.fsUtils.getUniqueFile(
      globals.fs.directory(getBuildDirectory()),'linux-code-size-analysis', 'json',
    )..writeAsStringSync(jsonEncode(output));
    // This message is used as a sentinel in analyze_apk_size_test.dart
    globals.printStatus(
      'A summary of your Linux bundle analysis can be found at: ${outputFile.path}',
    );
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
