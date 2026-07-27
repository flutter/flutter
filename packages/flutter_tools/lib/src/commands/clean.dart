// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../build_info.dart';
import '../globals.dart' as globals;
import '../ios/xcodeproj.dart';
import '../macos/xcode.dart';
import '../project.dart';
import '../runner/flutter_command.dart';

class CleanCommand extends FlutterCommand {
  CleanCommand({bool verbose = false}) : _verbose = verbose {
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
    final FlutterProject flutterProject = FlutterProject.current();
    final Xcode? xcode = globals.xcode;
    final bool cleanXcode = xcode != null && xcode.isInstalledAndMeetsVersionCheck;

    await _cleanProject(flutterProject, cleanXcode: cleanXcode);
    if (boolArg('include-example')) {
      if (flutterProject.hasExampleApp) {
        await _cleanProject(flutterProject.example, cleanXcode: cleanXcode);
      } else {
        globals.printStatus('No example app found, skipping example cleaning.');
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

    final Directory buildDir = flutterProject.directory.childDirectory(getBuildDirectory());
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
    final Status xcodeStatus = globals.logger.startProgress('Cleaning Xcode workspace...');
    try {
      final XcodeProjectInterpreter xcodeProjectInterpreter = globals.xcodeProjectInterpreter!;
      final XcodeProjectInfo projectInfo = (await xcodeProjectInterpreter.getInfo(
        xcodeProject,
        buildDirectory: globals.fs.directory(xcodeProject.darwinPlatform.buildDirectory()),
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
          buildDirectory: globals.fs.directory(xcodeProject.darwinPlatform.buildDirectory()),
        );
      } else {
        for (final String scheme in projectInfo.schemes) {
          await xcodeProjectInterpreter.cleanWorkspace(
            xcodeProject,
            xcodeWorkspace.path,
            scheme,
            verbose: _verbose,
            buildDirectory: globals.fs.directory(xcodeProject.darwinPlatform.buildDirectory()),
          );
        }
      }
    } on Exception catch (error) {
      final message = 'Could not clean Xcode workspace: $error';
      if (argResults?.wasParsed('scheme') ?? false) {
        throwToolExit(message);
      } else {
        globals.printTrace(message);
      }
    } finally {
      xcodeStatus.stop();
    }
  }

  @visibleForTesting
  Future<void> deleteFile(FileSystemEntity file, [FlutterProject? project]) async {
    try {
      await _deleteFile(file, project);
    } on Exception catch (e) {
      globals.printError('Failed to remove ${file.path}: $e');
    }
  }

  Future<void> _deleteFile(FileSystemEntity file, FlutterProject? project) async {
    // This will throw a FileSystemException if the directory is missing permissions.
    try {
      if (!file.existsSync()) {
        return;
      }
    } on FileSystemException catch (err) {
      globals.printError('Cannot clean ${file.path}.\n$err');
      return;
    }
    final Status deletionStatus = globals.logger.startProgress('Deleting ${file.basename}...');
    try {
      file.deleteSync(recursive: true);
    } on FileSystemException catch (error) {
      deletionStatus.stop();
      final String path = file.path;
      if (globals.platform.isWindows) {
        if (await _tryStopGradleAndRetryDelete(file, project)) {
          return;
        }

        globals.printError(
          'Failed to remove $path. '
          'A background process (e.g. Gradle daemon or Java) is locking files in the directory.\n'
          'To automatically stop Gradle daemons during clean, run:\n'
          '  flutter clean --stop-gradle\n'
          'Or manually stop daemons:\n'
          '  cd android && ./gradlew --stop',
        );
      } else {
        globals.printError('Failed to remove $path: $error');
      }
    }
  }

  Future<bool> _tryStopGradleAndRetryDelete(FileSystemEntity file, FlutterProject? project) async {
    final bool stopGradleFlag =
        (argResults?.wasParsed('stop-gradle') ?? false) && boolArg('stop-gradle');
    final bool isInteractive = globals.terminal.stdinHasTerminal && globals.terminal.usesTerminalUi;
    var shouldStopGradle = stopGradleFlag;

    if (!stopGradleFlag && isInteractive) {
      try {
        final String choice = await globals.terminal.promptForCharInput(
          <String>['y', 'n'],
          logger: globals.logger,
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

    final FlutterProject flutterProject = project ?? FlutterProject.current();
    final File gradlewFile = flutterProject.android.hostAppGradleRoot.childFile('gradlew.bat');
    if (!gradlewFile.existsSync()) {
      return false;
    }

    final Status stopStatus = globals.logger.startProgress('Stopping Gradle daemons...');
    try {
      await globals.processUtils.run(<String>[
        gradlewFile.path,
        '--stop',
      ], workingDirectory: gradlewFile.parent.path);
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
