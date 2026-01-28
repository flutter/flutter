// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io' as io;

import 'package:args/args.dart';

import 'package:process/process.dart';

import 'artifacts.dart';
import 'base/common.dart';
import 'base/file_system.dart';
import 'base/logger.dart';
import 'base/platform.dart';
import 'base/terminal.dart';
import 'commands/analyze_once.dart';
import 'commands/validate_project.dart';
import 'doctor_validator.dart';
import 'project.dart';
import 'project_validator.dart';
import 'runner/flutter_command.dart';

/// A validator that runs project analysis using `dart analyze`.
class ProjectAnalysisValidator extends DoctorValidator {
  ProjectAnalysisValidator({
    required FlutterProject project,
    required FileSystem fileSystem,
    required Platform platform,
    required ProcessManager processManager,
    required Terminal terminal,
    required Artifacts artifacts,
  }) : _project = project,
       _fileSystem = fileSystem,
       _platform = platform,
       _processManager = processManager,
       _terminal = terminal,
       _artifacts = artifacts,
       super('Project Analysis');

  final FlutterProject _project;
  final FileSystem _fileSystem;
  final Platform _platform;
  final ProcessManager _processManager;
  final Terminal _terminal;
  final Artifacts _artifacts;

  @override
  Future<ValidationResult> validateImpl() async {
    final argParser = ArgParser();
    argParser.addFlag('congratulate', defaultsTo: true);
    argParser.addFlag('preamble', defaultsTo: true);
    argParser.addFlag('fatal-infos', defaultsTo: true);
    argParser.addFlag('fatal-warnings', defaultsTo: true);
    argParser.addOption('write');
    argParser.addFlag('pub', defaultsTo: true);
    argParser.addFlag('current-package', defaultsTo: true);
    argParser.addFlag('flutter-repo');
    argParser.addOption('dart-sdk');
    argParser.addFlag('developer');
    argParser.addFlag('machine');
    argParser.addFlag('benchmark');
    argParser.addOption('protocol-traffic-log');

    final ArgResults argResults = argParser.parse(<String>[]);

    final bufferLogger = BufferLogger.test(
      terminal: _terminal,
      outputPreferences: OutputPreferences.test(wrapText: true, wrapColumn: 80),
    );

    final analyzeOnce = AnalyzeOnce(
      argResults,
      <Directory>[], // repoPackages
      workingDirectory: _project.directory,
      fileSystem: _fileSystem,
      logger: bufferLogger,
      platform: _platform,
      processManager: _processManager,
      terminal: _terminal,
      artifacts: _artifacts,
      suppressAnalytics: true,
    );

    try {
      await analyzeOnce.analyze();
      final messages = <ValidationMessage>[];
      if (bufferLogger.statusText.isNotEmpty) {
        messages.add(ValidationMessage(bufferLogger.statusText));
      }
      await _runPubOutdated(messages);
      return ValidationResult(ValidationType.success, messages, statusInfo: 'No issues found');
    } on ToolExit catch (e) {
      final messages = <ValidationMessage>[];
      if (e.message != null) {
        messages.add(ValidationMessage.error('${e.message!} Run `flutter analyze` for details.'));
      }
      // Also include any output from the buffer logger
      if (bufferLogger.statusText.isNotEmpty) {
        messages.add(ValidationMessage(bufferLogger.statusText));
      }
      await _runPubOutdated(messages);
      return ValidationResult(ValidationType.partial, messages, statusInfo: 'Issues found');
    } on Exception catch (e) {
      return ValidationResult(ValidationType.partial, <ValidationMessage>[
        ValidationMessage.error(e.toString()),
      ], statusInfo: 'Issues found');
    }
  }

  Future<void> _runPubOutdated(List<ValidationMessage> messages) async {
    try {
      final String dartSdkPath = _artifacts.getArtifactPath(Artifact.engineDartSdkPath);
      final String dartBinary = _fileSystem.path.join(
        dartSdkPath,
        'bin',
        _platform.isWindows ? 'dart.exe' : 'dart',
      );
      final io.ProcessResult pubOutdatedResult = await _processManager.run(<String>[
        dartBinary,
        'pub',
        'outdated',
        '--json',
      ], workingDirectory: _project.directory.path);

      if (pubOutdatedResult.exitCode == 0) {
        final output = pubOutdatedResult.stdout as String;
        final jsonOutput = json.decode(output) as Map<String, dynamic>;
        final List<dynamic> packages = (jsonOutput['packages'] as List<dynamic>)
            .where((dynamic p) => p is Map<String, dynamic> && p['current'] != null)
            .toList();
        final int outdatedCount = packages.length;
        if (outdatedCount > 0) {
          messages.add(
            ValidationMessage.error(
              '$outdatedCount outdated package${outdatedCount == 1 ? '' : 's'} found. Run `flutter pub outdated` for details.',
            ),
          );
        }
      }
    } on Exception {
      // ignore
    }
  }
}

/// A validator that runs project suggestions using `flutter analyze --suggestions`.
class ProjectSuggestionsValidator extends DoctorValidator {
  ProjectSuggestionsValidator({
    required FlutterProject project,
    required FileSystem fileSystem,
    required List<ProjectValidator> allProjectValidators,
    required ProcessManager processManager,
    required Terminal terminal,
  }) : _project = project,
       _fileSystem = fileSystem,
       _allProjectValidators = allProjectValidators,
       _processManager = processManager,
       _terminal = terminal,
       super('Project Validation');

  final FlutterProject _project;
  final FileSystem _fileSystem;
  final List<ProjectValidator> _allProjectValidators;
  final ProcessManager _processManager;
  final Terminal _terminal;

  @override
  Future<ValidationResult> validateImpl() async {
    final bufferLogger = BufferLogger.test(
      terminal: _terminal,
      outputPreferences: OutputPreferences.test(wrapText: true, wrapColumn: 80),
    );

    final validator = ValidateProject(
      fileSystem: _fileSystem,
      logger: bufferLogger,
      allProjectValidators: _allProjectValidators,
      userPath: _project.directory.path,
      processManager: _processManager,
    );

    final FlutterCommandResult result = await validator.run();
    if (result.exitStatus == ExitStatus.success) {
      return ValidationResult(
        ValidationType.success,
        <ValidationMessage>[],
        statusInfo: 'No issues found',
      );
    } else {
      return ValidationResult(
        ValidationType.partial,
        <ValidationMessage>[],
        statusInfo: 'Issues found',
      );
    }
  }
}
