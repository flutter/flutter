// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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
import '../cmake_project.dart';
import '../convert.dart';
import '../flutter_plugins.dart';
import '../globals.dart' as globals;
import '../migrations/cmake_custom_command_migration.dart';
import 'visual_studio.dart';

/// Builds the Windows project using msbuild.
Future<void> buildWindows(WindowsProject windowsProject, BuildInfo buildInfo, {
  String? target,
  VisualStudio? visualStudioOverride,
  SizeAnalyzer? sizeAnalyzer,
}) async {
  if (!windowsProject.cmakeFile.existsSync()) {
    throwToolExit(
      'No Windows desktop project configured. See '
      'https://docs.flutter.dev/desktop#add-desktop-support-to-an-existing-flutter-app '
      'to learn about adding Windows support to a project.');
  }

  final List<ProjectMigrator> migrators = <ProjectMigrator>[
    CmakeCustomCommandMigration(windowsProject, globals.logger),
  ];

  final ProjectMigration migration = ProjectMigration(migrators);
  if (!migration.run()) {
    throwToolExit('Unable to migrate project files');
  }

  // Ensure that necessary ephemeral files are generated and up to date.
  _writeGeneratedFlutterConfig(windowsProject, buildInfo, target);
  createPluginSymlinks(windowsProject.parent);

  final VisualStudio visualStudio = visualStudioOverride ?? VisualStudio(
    fileSystem: globals.fs,
    platform: globals.platform,
    logger: globals.logger,
    processManager: globals.processManager,
  );
  final String? cmakePath = visualStudio.cmakePath;
  final String? cmakeGenerator = visualStudio.cmakeGenerator;
  if (cmakePath == null || cmakeGenerator == null) {
    throwToolExit('Unable to find suitable Visual Studio toolchain. '
        'Please run `flutter doctor` for more details.');
  }

  final String buildModeName = getNameForBuildMode(buildInfo.mode);
  final Directory buildDirectory = globals.fs.directory(getWindowsBuildDirectory());
  final Status status = globals.logger.startProgress(
    'Building Windows application...',
  );
  try {
    await _runCmakeGeneration(
      cmakePath: cmakePath,
      generator: cmakeGenerator,
      buildDir: buildDirectory,
      sourceDir: windowsProject.cmakeFile.parent,
    );
    if (visualStudio.displayVersion == '17.1.0') {
      _fixBrokenCmakeGeneration(buildDirectory);
    }
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
    final Map<String, Object?> output = await sizeAnalyzer.analyzeAotSnapshot(
      aotSnapshot: codeSizeFile,
      // This analysis is only supported for release builds.
      outputDirectory: globals.fs.directory(
        globals.fs.path.join(getWindowsBuildDirectory(), 'runner', 'Release'),
      ),
      precompilerTrace: precompilerTrace,
      type: 'windows',
    );
    final File outputFile = globals.fsUtils.getUniqueFile(
      globals.fs
        .directory(globals.fsUtils.homeDirPath)
        .childDirectory('.flutter-devtools'), 'windows-code-size-analysis', 'json',
    )..writeAsStringSync(jsonEncode(output));
    // This message is used as a sentinel in analyze_apk_size_test.dart
    globals.printStatus(
      'A summary of your Windows bundle analysis can be found at: ${outputFile.path}',
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

Future<void> _runCmakeGeneration({
  required String cmakePath,
  required String generator,
  required Directory buildDir,
  required Directory sourceDir,
}) async {
  final Stopwatch sw = Stopwatch()..start();

  await buildDir.create(recursive: true);
  int result;
  try {
    result = await globals.processUtils.stream(
      <String>[
        cmakePath,
        '-S',
        sourceDir.path,
        '-B',
        buildDir.path,
        '-G',
        generator,
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

Future<void> _runBuild(
  String cmakePath,
  Directory buildDir,
  String buildModeName,
  { bool install = true }
) async {
  final Stopwatch sw = Stopwatch()..start();

  // MSBuild sends all output to stdout, including build errors. This surfaces
  // known error patterns.
  final RegExp errorMatcher = RegExp(r':\s*(?:warning|(?:fatal )?error).*?:');

  int result;
  try {
    result = await globals.processUtils.stream(
      <String>[
        cmakePath,
        '--build',
        buildDir.path,
        '--config',
        sentenceCase(buildModeName),
        if (install)
          ...<String>['--target', 'INSTALL'],
        if (globals.logger.isVerbose)
          '--verbose',
      ],
      environment: <String, String>{
        if (globals.logger.isVerbose)
          'VERBOSE_SCRIPT_LOGGING': 'true',
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
  String? target,
) {
  final Map<String, String> environment = <String, String>{
    'FLUTTER_ROOT': Cache.flutterRoot!,
    'FLUTTER_EPHEMERAL_DIR': windowsProject.ephemeralDirectory.path,
    'PROJECT_DIR': windowsProject.parent.directory.path,
    if (target != null)
      'FLUTTER_TARGET': target,
    ...buildInfo.toEnvironmentConfig(),
  };
  final Artifacts artifacts = globals.artifacts!;
  if (artifacts is LocalEngineArtifacts) {
    final String engineOutPath = artifacts.engineOutPath;
    environment['FLUTTER_ENGINE'] = globals.fs.path.dirname(globals.fs.path.dirname(engineOutPath));
    environment['LOCAL_ENGINE'] = globals.fs.path.basename(engineOutPath);
  }
  writeGeneratedCmakeConfig(Cache.flutterRoot!, windowsProject, buildInfo, environment);
}

// Works around the Visual Studio 17.1.0 CMake bug described in
// https://github.com/flutter/flutter/issues/97086
//
// Rather than attempt to remove all the duplicate entries within the
// <CustomBuild> element, which would require a more complicated parser, this
// just fixes the incorrect duplicates to have the correct `$<CONFIG>` value,
// making the duplication harmless.
//
// TODO(stuartmorgan): Remove this workaround either once 17.1.0 is
// sufficiently old that we no longer need to support it, or when
// dropping VS 2022 support.
void _fixBrokenCmakeGeneration(Directory buildDirectory) {
  final File assembleProject = buildDirectory
    .childDirectory('flutter')
    .childFile('flutter_assemble.vcxproj');
  if (assembleProject.existsSync()) {
    // E.g.: <Command Condition="'$(Configuration)|$(Platform)'=='Debug|x64'">
    final RegExp commandRegex = RegExp(
      r'<Command Condition=.*\(Configuration\)\|\$\(Platform\).==.(Debug|Profile|Release)\|');
    // E.g.: [...]/flutter_tools/bin/tool_backend.bat windows-x64 Debug
    final RegExp assembleCallRegex = RegExp(
      r'^.*/tool_backend\.bat windows[^ ]* (Debug|Profile|Release)');
    String? lastCommandConditionConfig;
    final StringBuffer newProjectContents = StringBuffer();
    // vcxproj files contain a BOM, which readAsLinesSync drops; re-add it.
    newProjectContents.writeCharCode(unicodeBomCharacterRune);
    for (final String line in assembleProject.readAsLinesSync()) {
      final RegExpMatch? commandMatch = commandRegex.firstMatch(line);
      if (commandMatch != null) {
        lastCommandConditionConfig = commandMatch.group(1);
      } else if (lastCommandConditionConfig != null) {
        final RegExpMatch? assembleCallMatch = assembleCallRegex.firstMatch(line);
        if (assembleCallMatch != null) {
          final String callConfig = assembleCallMatch.group(1)!;
          if (callConfig != lastCommandConditionConfig) {
            // The config is the end of the line; make sure to replace that one,
            // in case config-matching strings appear anywhere else in the line
            // (e.g., the project path).
            final int badConfigIndex = line.lastIndexOf(assembleCallMatch.group(1)!);
            final String correctedLine = line.replaceFirst(
              callConfig, lastCommandConditionConfig, badConfigIndex);
            newProjectContents.writeln('$correctedLine\r');
            continue;
          }
        }
      }
      newProjectContents.writeln('$line\r');
    }
    assembleProject.writeAsStringSync(newProjectContents.toString());
  }
}
