// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../../src/macos/xcode.dart';
import '../base/common.dart';
import '../base/error_handling_io.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../build_info.dart';
import '../globals.dart' as globals;
import '../ios/xcodeproj.dart';
import '../project.dart';
import '../runner/flutter_command.dart';

enum XcodeCleanScope { workspace, app, skip }

class CleanCommand extends FlutterCommand {
  CleanCommand({bool verbose = false}) : _verbose = verbose {
    requiresPubspecYaml();
    argParser.addOption(
      'scheme',
      help: 'When cleaning Xcode schemes, clean only the specified scheme.',
    );
    argParser.addOption(
      'xcode-clean',
      defaultsTo: 'workspace',
      help: 'Controls Xcode workspace cleanup.',
      allowed: <String>['workspace', 'app', 'skip'],
      allowedHelp: <String, String>{
        'workspace': 'Clean all Xcode schemes (default).',
        'app': 'Clean only application schemes.',
        'skip': 'Skip Xcode workspace cleaning.',
      },
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
    // Clean Xcode to remove intermediate DerivedData artifacts.
    // Do this before removing ephemeral directory, which would delete the xcworkspace.
    final FlutterProject flutterProject = FlutterProject.current();
    final Xcode? xcode = globals.xcode;
    if (xcode != null && xcode.isInstalledAndMeetsVersionCheck) {
      final XcodeCleanScope xcodeCleanScope = switch (argResults?['xcode-clean'] as String) {
        'workspace' => XcodeCleanScope.workspace,
        'skip' => XcodeCleanScope.skip,
        'app' => XcodeCleanScope.app,
        _ => XcodeCleanScope.workspace,
      };
      await _cleanXcode(xcodeProject: flutterProject.ios, xcodeCleanScope: xcodeCleanScope);
      await _cleanXcode(xcodeProject: flutterProject.macos, xcodeCleanScope: xcodeCleanScope);
    }

    final Directory buildDir = globals.fs.directory(getBuildDirectory());
    deleteFile(buildDir);

    deleteFile(flutterProject.dartTool);

    deleteFile(flutterProject.android.ephemeralDirectory);

    deleteFile(flutterProject.ios.ephemeralDirectory);
    deleteFile(flutterProject.ios.ephemeralModuleDirectory);
    deleteFile(flutterProject.ios.generatedXcodePropertiesFile);
    deleteFile(flutterProject.ios.generatedEnvironmentVariableExportScript);
    deleteFile(flutterProject.ios.deprecatedCompiledDartFramework);
    deleteFile(flutterProject.ios.deprecatedProjectFlutterFramework);
    deleteFile(flutterProject.ios.flutterPodspec);

    deleteFile(flutterProject.linux.ephemeralDirectory);
    deleteFile(flutterProject.macos.ephemeralDirectory);
    deleteFile(flutterProject.windows.ephemeralDirectory);
    deleteFile(flutterProject.flutterPluginsDependenciesFile);

    return const FlutterCommandResult(ExitStatus.success);
  }

  Future<void> _cleanXcode({
    required XcodeBasedProject xcodeProject,
    required XcodeCleanScope xcodeCleanScope,
  }) async {
    final Directory? xcodeWorkspace = xcodeProject.xcodeWorkspace;
    if (xcodeWorkspace == null) {
      return;
    }

    if (xcodeCleanScope == XcodeCleanScope.skip) {
      globals.printTrace('Skipping Xcode workspace cleaning.');
      return;
    }

    final Status xcodeStatus = globals.logger.startProgress('Cleaning Xcode workspace...');
    try {
      final XcodeProjectInterpreter xcodeProjectInterpreter = globals.xcodeProjectInterpreter!;
      final XcodeProjectInfo projectInfo = (await xcodeProjectInterpreter.getInfo(
        xcodeWorkspace.parent.path,
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
          xcodeWorkspace.path,
          scheme,
          verbose: _verbose,
        );
      } else {
        final Iterable<String> schemesToClean = switch (xcodeCleanScope) {
          XcodeCleanScope.skip => const <String>[],
          XcodeCleanScope.workspace => projectInfo.schemes,
          XcodeCleanScope.app => _applicationSchemes(
            projectInfo: projectInfo,
            xcodeProject: xcodeProject,
          ),
        };
        if (schemesToClean.isEmpty) {
          globals.printTrace('No Xcode schemes selected for cleaning for the current clean scope.');
        } else {
          globals.printTrace(
            'Cleaning ${schemesToClean.length} Xcode scheme(s): '
            '${schemesToClean.join(', ')}',
          );
          for (final scheme in schemesToClean) {
            await xcodeProjectInterpreter.cleanWorkspace(
              xcodeWorkspace.path,
              scheme,
              verbose: _verbose,
            );
          }
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
  void deleteFile(FileSystemEntity file) {
    try {
      ErrorHandlingFileSystem.noExitOnFailure(() {
        _deleteFile(file);
      });
    } on Exception catch (e) {
      globals.printError('Failed to remove ${file.path}: $e');
    }
  }

  void _deleteFile(FileSystemEntity file) {
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
      final String path = file.path;
      if (globals.platform.isWindows) {
        globals.printError(
          'Failed to remove $path. '
          'A program may still be using a file in the directory or the directory itself. '
          'To find and stop such a program, see: '
          'https://superuser.com/questions/1333118/cant-delete-empty-folder-because-it-is-used',
        );
      } else {
        globals.printError('Failed to remove $path: $error');
      }
    } finally {
      deletionStatus.stop();
    }
  }

  Iterable<String> _applicationSchemes({
    required XcodeProjectInfo projectInfo,
    required XcodeBasedProject xcodeProject,
  }) {
    final String hostProjectName = xcodeProject.hostAppProjectName;
    final applicationSchemePrefix = '$hostProjectName-';
    return projectInfo.schemes.where((String scheme) {
      if (scheme == hostProjectName) {
        globals.printTrace('Including Xcode scheme "$scheme" (application scheme).');
        return true;
      }

      if (scheme.startsWith(applicationSchemePrefix)) {
        globals.printTrace('Including Xcode scheme "$scheme" (application flavor).');
        return true;
      }

      if (projectInfo.targets.contains(scheme)) {
        globals.printTrace('Including Xcode scheme "$scheme" (application target).');
        return true;
      }

      globals.printTrace('Skipping Xcode scheme "$scheme" (non-application scheme).');
      return false;
    });
  }
}
