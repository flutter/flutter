// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import '../artifacts.dart';
import '../base/analyze_size.dart';
import '../base/common.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/project_migrator.dart';
import '../base/utils.dart';
import '../build_info.dart';
import '../cache.dart';
import '../cmake.dart';
import '../convert.dart';
import '../globals.dart' as globals;
import '../migrations/cmake_custom_command_migration.dart';
import '../plugins.dart';
import '../project.dart';

// Matches the following error and warning patterns:
// - <file path>:<line>:<column>: (fatal) error: <error...>
// - <file path>:<line>:<column>: warning: <warning...>
// - clang: error: <link error...>
// - Error: <tool error...>
final RegExp errorMatcher = RegExp(r'(?:(?:.*:\d+:\d+|clang):\s)?(fatal\s)?(?:error|warning):\s.*', caseSensitive: false);

/// Builds the Linux project through the Makefile.
Future<void> buildLinux(
  LinuxProject linuxProject,
  BuildInfo buildInfo, {
    String target = 'lib/main.dart',
    SizeAnalyzer sizeAnalyzer,
    bool needCrossBuild = false,
    TargetPlatform targetPlatform = TargetPlatform.linux_x64,
    String targetSysroot = '/',
  }) async {
  if (!linuxProject.cmakeFile.existsSync()) {
    throwToolExit('No Linux desktop project configured. See '
      'https://flutter.dev/desktop#add-desktop-support-to-an-existing-flutter-app '
      'to learn about adding Linux support to a project.');
  }

  final List<ProjectMigrator> migrators = <ProjectMigrator>[
    CmakeCustomCommandMigration(linuxProject, globals.logger),
  ];

  final ProjectMigration migration = ProjectMigration(migrators);
  if (!migration.run()) {
    throwToolExit('Unable to migrate project files');
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
  );
  try {
    final String buildModeName = getNameForBuildMode(buildInfo.mode ?? BuildMode.release);
    final Directory buildDirectory =
        globals.fs.directory(getLinuxBuildDirectory(targetPlatform)).childDirectory(buildModeName);
    await _runCmake(buildModeName, linuxProject.cmakeFile.parent, buildDirectory,
                    needCrossBuild, targetPlatform, targetSysroot);
    await _runBuild(buildDirectory);
  } finally {
    status.cancel();
  }
  if (buildInfo.codeSizeDirectory != null && sizeAnalyzer != null) {
    final String arch = getNameForTargetPlatform(targetPlatform);
    final File codeSizeFile = globals.fs.directory(buildInfo.codeSizeDirectory)
      .childFile('snapshot.$arch.json');
    final File precompilerTrace = globals.fs.directory(buildInfo.codeSizeDirectory)
      .childFile('trace.$arch.json');
    final Map<String, Object> output = await sizeAnalyzer.analyzeAotSnapshot(
      aotSnapshot: codeSizeFile,
      // This analysis is only supported for release builds.
      outputDirectory: globals.fs.directory(
        globals.fs.path.join(getLinuxBuildDirectory(targetPlatform), 'release', 'bundle'),
      ),
      precompilerTrace: precompilerTrace,
      type: 'linux',
    );
    final File outputFile = globals.fsUtils.getUniqueFile(
      globals.fs
        .directory(globals.fsUtils.homeDirPath)
        .childDirectory('.flutter-devtools'), 'linux-code-size-analysis', 'json',
    )..writeAsStringSync(jsonEncode(output));
    // This message is used as a sentinel in analyze_apk_size_test.dart
    globals.printStatus(
      'A summary of your Linux bundle analysis can be found at: ${outputFile.path}',
    );

    // DevTools expects a file path relative to the .flutter-devtools/ dir.
    final String relativeAppSizePath = outputFile.path.split('.flutter-devtools/').last.trim();
    globals.printStatus(
      '\nTo analyze your app size in Dart DevTools, run the following command:\n'
      'flutter pub global activate devtools; flutter pub global run devtools '
      '--appSizeBase=$relativeAppSizePath'
    );
  }
}

Future<void> _runCmake(String buildModeName, Directory sourceDir, Directory buildDir,
    bool needCrossBuild, TargetPlatform targetPlatform, String targetSysroot) async {
  final Stopwatch sw = Stopwatch()..start();

  await buildDir.create(recursive: true);

  final String buildFlag = toTitleCase(buildModeName);
  final bool needCrossBuildOptionsForArm64 = needCrossBuild
      && targetPlatform == TargetPlatform.linux_arm64;
  int result;
  try {
    result = await globals.processUtils.stream(
      <String>[
        'cmake',
        '-G',
        'Ninja',
        '-DCMAKE_BUILD_TYPE=$buildFlag',
        '-DFLUTTER_TARGET_PLATFORM=' + getNameForTargetPlatform(targetPlatform),
        // Support cross-building for arm64 targets on x64 hosts.
        // (Cross-building for x64 on arm64 hosts isn't supported now.)
        if (needCrossBuild)
          '-DFLUTTER_TARGET_PLATFORM_SYSROOT=$targetSysroot',
        if (needCrossBuildOptionsForArm64)
          '-DCMAKE_C_COMPILER_TARGET=aarch64-linux-gnu',
        if (needCrossBuildOptionsForArm64)
          '-DCMAKE_CXX_COMPILER_TARGET=aarch64-linux-gnu',
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
    result = await globals.processUtils.stream(
      <String>[
        'ninja',
        '-C',
        buildDir.path,
        'install',
      ],
      environment: <String, String>{
        if (globals.logger.isVerbose)
          'VERBOSE_SCRIPT_LOGGING': 'true',
        if (!globals.logger.isVerbose)
          'PREFIXED_ERROR_LOGGING': 'true',
      },
      trace: true,
      stdoutErrorMatcher: errorMatcher,
    );
  } on ArgumentError {
    throwToolExit("ninja not found. Run 'flutter doctor' for more information.");
  }
  if (result != 0) {
    throwToolExit('Build process failed');
  }
  globals.flutterUsage.sendTiming('build', 'linux-ninja', Duration(milliseconds: sw.elapsedMilliseconds));
}
