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
import 'visual_studio.dart';

// From https://cmake.org/cmake/help/v3.15/manual/cmake-generators.7.html#visual-studio-generators
// This may need to become a getter on VisualStudio in the future to support
// future major versions of Visual Studio.
const String _cmakeVisualStudioGeneratorIdentifier = 'Visual Studio 16 2019';

/// Builds the Windows project using msbuild.
Future<void> buildWindows(WindowsProject windowsProject, BuildInfo buildInfo, {
  String target,
  VisualStudio visualStudioOverride,
  SizeAnalyzer sizeAnalyzer,
}) async {
  if (!windowsProject.cmakeFile.existsSync()) {
    throwToolExit(
      'No Windows desktop project configured. '
      'See https://github.com/flutter/flutter/wiki/Desktop-shells#create '
      'to learn about adding Windows support to a project.');
  }

  // Check for incompatibility between the Flutter tool version and the project
  // template version, since the tempalte isn't stable yet.
  final int templateCompareResult = _compareTemplateVersions(windowsProject);
  if (templateCompareResult < 0) {
    throwToolExit('The Windows runner was created with an earlier version of '
      'the template, which is not yet stable.\n\n'
      'Delete the windows/ directory and re-run \'flutter create .\', '
      're-applying any previous changes.');
  } else if (templateCompareResult > 0) {
    throwToolExit('The Windows runner was created with a newer version of the '
      'template, which is not yet stable.\n\n'
      'Upgrade Flutter and try again.');
  }

  // Ensure that necessary emphemeral files are generated and up to date.
  _writeGeneratedFlutterConfig(windowsProject, buildInfo, target);
  createPluginSymlinks(windowsProject.parent);

  final VisualStudio visualStudio = visualStudioOverride ?? VisualStudio(
    fileSystem: globals.fs,
    platform: globals.platform,
    logger: globals.logger,
    processManager: globals.processManager,
  );
  final String cmakePath = visualStudio.cmakePath;
  if (cmakePath == null) {
    throwToolExit('Unable to find suitable Visual Studio toolchain. '
        'Please run `flutter doctor` for more details.');
  }

  final String buildModeName = getNameForBuildMode(buildInfo.mode ?? BuildMode.release);
  final Directory buildDirectory = globals.fs.directory(getWindowsBuildDirectory());
  final Status status = globals.logger.startProgress(
    'Building Windows application...',
    timeout: null,
  );
  try {
    await _runCmakeGeneration(cmakePath, buildDirectory, windowsProject.cmakeFile.parent);
    await _runBuild(cmakePath, buildDirectory, buildModeName);
  } finally {
    status.cancel();
  }
  if (buildInfo.codeSizeDirectory != null && sizeAnalyzer != null) {
    final String arch = getNameForTargetPlatform(TargetPlatform.windows_x64);
    final File codeSizeFile = globals.fs.directory(buildInfo.codeSizeDirectory)
      .childFile('snapshot.$arch.json');
    final File precompilerTrace = globals.fs.directory(buildInfo.codeSizeDirectory)
      .childFile('trace.$arch.json');
    final Map<String, Object> output = await sizeAnalyzer.analyzeAotSnapshot(
      aotSnapshot: codeSizeFile,
      // This analysis is only supported for release builds.
      outputDirectory: globals.fs.directory(
        globals.fs.path.join(getWindowsBuildDirectory(), 'runner', 'Release'),
      ),
      precompilerTrace: precompilerTrace,
      type: 'windows',
    );
    final File outputFile = globals.fsUtils.getUniqueFile(
      globals.fs.directory(getBuildDirectory()),'windows-code-size-analysis', 'json',
    )..writeAsStringSync(jsonEncode(output));
    // This message is used as a sentinel in analyze_apk_size_test.dart
    globals.printStatus(
      'A summary of your Windows bundle analysis can be found at: ${outputFile.path}',
    );
  }
}

Future<void> _runCmakeGeneration(String cmakePath, Directory buildDir, Directory sourceDir) async {
  final Stopwatch sw = Stopwatch()..start();

  await buildDir.create(recursive: true);
  int result;
  try {
    result = await processUtils.stream(
      <String>[
        cmakePath,
        '-S',
        sourceDir.path,
        '-B',
        buildDir.path,
        '-G',
        _cmakeVisualStudioGeneratorIdentifier,
      ],
      trace: true,
    );
  } on ArgumentError {
    throwToolExit("cmake not found. Run 'flutter doctor' for more information.");
  }
  if (result != 0) {
    throwToolExit('Unable to generate build files');
  }
  globals.flutterUsage.sendTiming('build', 'windows-cmake-generation', Duration(milliseconds: sw.elapsedMilliseconds));
}

Future<void> _runBuild(String cmakePath, Directory buildDir, String buildModeName) async {
  final Stopwatch sw = Stopwatch()..start();

  // MSBuild sends all output to stdout, including build errors. This surfaces
  // known error patterns.
  final RegExp errorMatcher = RegExp(r':\s*(?:warning|(?:fatal )?error).*?:');

  int result;
  try {
    result = await processUtils.stream(
      <String>[
        cmakePath,
        '--build',
        buildDir.path,
        '--config',
        toTitleCase(buildModeName),
        '--target',
        'INSTALL',
        if (globals.logger.isVerbose)
          '--verbose'
      ],
      environment: <String, String>{
        if (globals.logger.isVerbose)
          'VERBOSE_SCRIPT_LOGGING': 'true'
      },
      trace: true,
      stdoutErrorMatcher: errorMatcher,
    );
  } on ArgumentError {
    throwToolExit("cmake not found. Run 'flutter doctor' for more information.");
  }
  if (result != 0) {
    throwToolExit('Build process failed.');
  }
  globals.flutterUsage.sendTiming('build', 'windows-cmake-build', Duration(milliseconds: sw.elapsedMilliseconds));
}

/// Writes the generated CMake file with the configuration for the given build.
void _writeGeneratedFlutterConfig(
  WindowsProject windowsProject,
  BuildInfo buildInfo,
  String target,
) {
  final Map<String, String> environment = <String, String>{
    'FLUTTER_ROOT': Cache.flutterRoot,
    'FLUTTER_EPHEMERAL_DIR': windowsProject.ephemeralDirectory.path,
    'PROJECT_DIR': windowsProject.parent.directory.path,
    if (target != null)
      'FLUTTER_TARGET': target,
    ...buildInfo.toEnvironmentConfig(),
  };
  if (globals.artifacts is LocalEngineArtifacts) {
    final LocalEngineArtifacts localEngineArtifacts = globals.artifacts as LocalEngineArtifacts;
    final String engineOutPath = localEngineArtifacts.engineOutPath;
    environment['FLUTTER_ENGINE'] = globals.fs.path.dirname(globals.fs.path.dirname(engineOutPath));
    environment['LOCAL_ENGINE'] = globals.fs.path.basename(engineOutPath);
  }
  writeGeneratedCmakeConfig(Cache.flutterRoot, windowsProject, environment);
}

// Checks the template version of [project] against the current template
// version. Returns < 0 if the project is older than the current template, > 0
// if it's newer, and 0 if they match.
int _compareTemplateVersions(WindowsProject project) {
  const String projectVersionBasename = '.template_version';
  final int expectedVersion = int.parse(globals.fs.file(globals.fs.path.join(
    globals.fs.path.absolute(Cache.flutterRoot),
    'packages',
    'flutter_tools',
    'templates',
    'app',
    'windows.tmpl',
    'flutter',
    projectVersionBasename,
  )).readAsStringSync());
  final File projectVersionFile = project.managedDirectory.childFile(projectVersionBasename);
  final int version = projectVersionFile.existsSync()
      ? int.tryParse(projectVersionFile.readAsStringSync())
      : 0;
  return version.compareTo(expectedVersion);
}
