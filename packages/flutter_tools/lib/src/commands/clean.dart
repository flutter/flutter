// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../base/common.dart';
import '../base/config.dart';
import '../base/error_handling_io.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/platform.dart';
import '../base/terminal.dart';
import '../build_info.dart';
import '../context/tool_context.dart';
import '../ios/xcodeproj.dart';
import '../macos/xcode.dart';
import '../project.dart';
import '../runner/flutter_command.dart';

class CleanCommand extends FlutterCommand {
  CleanCommand({
    required ToolContext toolContext,
    required Xcode xcode,
    required XcodeProjectInterpreter xcodeProjectInterpreter,
    bool verbose = false,
  }) : _toolContext = toolContext,
       _xcode = xcode,
       _xcodeProjectInterpreter = xcodeProjectInterpreter,
       _verbose = verbose,
       super(toolContext: toolContext) {
    requiresPubspecYaml();
    argParser.addOption(
      'scheme',
      help: 'When cleaning Xcode schemes, clean only the specified scheme.',
    );
    argParser.addFlag(
      'include-example',
      negatable: false,
      help:
          'Also clean the example directory, if one exists. '
          'Useful when developing in a package project.',
    );
    argParser.addFlag(
      'stop-gradle',
      negatable: false,
      help:
          'Force stop active Gradle daemons before or during clean. '
          'Useful on Windows when files in build/ are locked by background processes.',
    );
  }

  final ToolContext _toolContext;
  final Xcode _xcode;
  final XcodeProjectInterpreter _xcodeProjectInterpreter;
  final bool _verbose;

  @override
  final name = 'clean';

  @override
  final description = 'Delete the build/ and .dart_tool/ directories.';

  @override
  String get category => FlutterCommandCategory.project;

  @override
  Future<Set<DevelopmentArtifact>> get requiredArtifacts async => const <DevelopmentArtifact>{};

  @override
  Future<FlutterCommandResult> runCommand() async {
    final FileSystem fs = _toolContext.fs;
    final FlutterProject flutterProject = _toolContext.projectFactory.fromDirectory(
      fs.currentDirectory,
    );
    final Xcode xcode = _xcode;
    final bool cleanXcode = xcode.isInstalledAndMeetsVersionCheck;

    await _cleanProject(flutterProject, cleanXcode: cleanXcode);
    if (boolArg('include-example')) {
      if (flutterProject.hasExampleApp) {
        await _cleanProject(flutterProject.example, cleanXcode: cleanXcode);
      } else {
        _toolContext.logger.printStatus('No example app found, skipping example cleaning.');
      }
    }

    return const FlutterCommandResult(ExitStatus.success);
  }

  /// Cleans all build artifacts, Xcode workspaces, and ephemeral files for
  /// the given [flutterProject]. When [cleanXcode] is true, also cleans
  /// Xcode's DerivedData for iOS and macOS workspaces.
  Future<void> _cleanProject(FlutterProject flutterProject, {required bool cleanXcode}) async {
    // Clean Xcode's intermediate DerivedData artifacts before removing
    // ephemeral directory, which would delete the xcworkspace.
    if (cleanXcode) {
      await _cleanXcode(flutterProject.ios);
      await _cleanXcode(flutterProject.macos);
    }

    final Config config = _toolContext.config;
    final FileSystem fs = _toolContext.fs;
    final Directory buildDir = flutterProject.directory.childDirectory(
      getBuildDirectory(config, fs),
    );
    await deleteFile(buildDir, flutterProject);

    await deleteFile(flutterProject.dartTool, flutterProject);

    await deleteFile(flutterProject.android.ephemeralDirectory, flutterProject);

    await deleteFile(flutterProject.ios.ephemeralDirectory, flutterProject);
    await deleteFile(flutterProject.ios.ephemeralModuleDirectory, flutterProject);
    await deleteFile(flutterProject.ios.generatedXcodePropertiesFile, flutterProject);
    await deleteFile(flutterProject.ios.generatedEnvironmentVariableExportScript, flutterProject);
    await deleteFile(flutterProject.ios.deprecatedCompiledDartFramework, flutterProject);
    await deleteFile(flutterProject.ios.deprecatedProjectFlutterFramework, flutterProject);
    await deleteFile(flutterProject.ios.flutterPodspec, flutterProject);

    await deleteFile(flutterProject.linux.ephemeralDirectory, flutterProject);
    await deleteFile(flutterProject.macos.ephemeralDirectory, flutterProject);
    await deleteFile(flutterProject.windows.ephemeralDirectory, flutterProject);
    await deleteFile(flutterProject.flutterPluginsDependenciesFile, flutterProject);
  }

  Future<void> _cleanXcode(XcodeBasedProject xcodeProject) async {
    final Directory? xcodeWorkspace = xcodeProject.xcodeWorkspace;
    if (xcodeWorkspace == null) {
      return;
    }
    final Logger logger = _toolContext.logger;
    final FileSystem fs = _toolContext.fs;
    final Config config = _toolContext.config;
    final Status xcodeStatus = logger.startProgress('Cleaning Xcode workspace...');
    try {
      final XcodeProjectInterpreter xcodeProjectInterpreter = _xcodeProjectInterpreter;
      final Directory darwinBuildDirectory = fs.directory(
        xcodeProject.darwinPlatform.buildDirectory(config: config, fileSystem: fs),
      );
      final XcodeProjectInfo projectInfo = (await xcodeProjectInterpreter.getInfo(
        xcodeProject,
        buildDirectory: darwinBuildDirectory,
      ))!;
      if (argResults?.wasParsed('scheme') ?? false) {
        final scheme = argResults!['scheme'] as String;
        if (scheme.isEmpty) {
          throwToolExit('No scheme was specified for --scheme');
        }
        if (!projectInfo.schemes.contains(scheme)) {
          throwToolExit('Scheme "$scheme" not found in ${projectInfo.schemes}');
        }
        await xcodeProjectInterpreter.cleanWorkspace(
          xcodeProject,
          xcodeWorkspace.path,
          scheme,
          verbose: _verbose,
          buildDirectory: darwinBuildDirectory,
        );
      } else {
        for (final String scheme in projectInfo.schemes) {
          await xcodeProjectInterpreter.cleanWorkspace(
            xcodeProject,
            xcodeWorkspace.path,
            scheme,
            verbose: _verbose,
            buildDirectory: darwinBuildDirectory,
          );
        }
      }
    } on Exception catch (error) {
      final message = 'Could not clean Xcode workspace: $error';
      if (argResults?.wasParsed('scheme') ?? false) {
        throwToolExit(message);
      } else {
        logger.printTrace(message);
      }
    } finally {
      xcodeStatus.stop();
    }
  }

  @visibleForTesting
  Future<void> deleteFile(FileSystemEntity file, [FlutterProject? project]) async {
    try {
      await ErrorHandlingFileSystem.noExitOnFailure(() => _deleteFile(file, project));
    } on Exception catch (e) {
      _toolContext.logger.printError('Failed to remove ${file.path}: $e');
    }
  }

  Future<void> _deleteFile(FileSystemEntity file, FlutterProject? project) async {
    final Logger logger = _toolContext.logger;
    final Platform platform = _toolContext.platform;
    // This will throw a FileSystemException if the directory is missing permissions.
    try {
      if (!file.existsSync()) {
        return;
      }
    } on FileSystemException catch (err) {
      logger.printError('Cannot clean ${file.path}.\n$err');
      return;
    }
    final Status deletionStatus = logger.startProgress('Deleting ${file.basename}...');
    try {
      file.deleteSync(recursive: true);
    } on FileSystemException catch (error) {
      deletionStatus.stop();
      final String path = file.path;
      if (platform.isWindows) {
        if (await _tryStopGradleAndRetryDelete(file, project)) {
          return;
        }

        logger.printError(
          'Failed to remove $path. '
          'A background process (e.g. Gradle daemon or Java) is locking files in the directory.\n'
          'To automatically stop Gradle daemons during clean, run:\n'
          '  flutter clean --stop-gradle\n'
          'Or manually stop daemons:\n'
          '  cd android && ./gradlew --stop',
        );
      } else {
        logger.printError('Failed to remove $path: $error');
      }
    }
  }

  /// Attempts to stop active Gradle daemons via `gradlew --stop` when Windows file locks
  /// prevent deletion of build files, either via the `--stop-gradle` flag or an interactive prompt.
  ///
  /// Retries file deletion after stopping Gradle daemons and returns `true` if deletion succeeds.
  Future<bool> _tryStopGradleAndRetryDelete(FileSystemEntity file, FlutterProject? project) async {
    final AnsiTerminal terminal = _toolContext.terminal;
    final Logger logger = _toolContext.logger;
    final FileSystem fs = _toolContext.fs;
    final bool stopGradleFlag =
        (argResults?.wasParsed('stop-gradle') ?? false) && boolArg('stop-gradle');
    final bool isInteractive = terminal.stdinHasTerminal && terminal.usesTerminalUi;
    var shouldStopGradle = stopGradleFlag;

    if (!stopGradleFlag && isInteractive) {
      try {
        final String choice = await terminal.promptForCharInput(
          <String>['y', 'n'],
          logger: logger,
          prompt:
              'Files in build/ are locked by background processes (likely Gradle).\n'
              'Stop active Gradle daemons ("gradlew --stop") and retry clean? [y/N]',
          defaultChoiceIndex: 1,
        );
        shouldStopGradle = choice.toLowerCase() == 'y';
      } on StateError {
        shouldStopGradle = false;
      }
    }

    if (!shouldStopGradle) {
      return false;
    }

    final FlutterProject flutterProject =
        project ?? _toolContext.projectFactory.fromDirectory(fs.currentDirectory);
    final File gradlewFile = flutterProject.android.hostAppGradleRoot.childFile('gradlew.bat');
    if (!gradlewFile.existsSync()) {
      return false;
    }

    final Status stopStatus = logger.startProgress('Stopping Gradle daemons...');
    try {
      await _toolContext.processUtils.run(<String>[
        gradlewFile.path,
        '--stop',
      ], workingDirectory: gradlewFile.parent.path);
    } on Exception catch (e) {
      logger.printTrace('Failed to stop Gradle daemons: $e');
    } finally {
      stopStatus.stop();
    }

    try {
      file.deleteSync(recursive: true);
      return true;
    } on FileSystemException {
      return false;
    }
  }
}
