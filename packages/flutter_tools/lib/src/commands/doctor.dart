// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../android/android_workflow.dart';
import '../base/common.dart';
import '../base/file_system.dart';
import '../doctor_project_validators.dart';
import '../doctor_validator.dart';
import '../globals.dart' as globals;
import '../project.dart';
import '../runner/flutter_command.dart';

class DoctorCommand extends FlutterCommand {
  DoctorCommand({this.verbose = false}) {
    argParser.addFlag(
      'android-licenses',
      negatable: false,
      help: "Run the Android SDK manager tool to accept the SDK's licenses.",
    );
    argParser.addOption(
      'check-for-remote-artifacts',
      hide: !verbose,
      help:
          'Used to determine if Flutter engine artifacts for all platforms '
          'are available for download.',
      valueHelp: 'engine revision git hash',
    );
    argParser.addOption(
      'project-path',
      abbr: 'p',
      help: 'The path to the current Flutter project.',
      valueHelp: 'path',
    );
    argParser.addFlag(
      'disable-project-validators',
      negatable: false,
      help: 'Disable project-specific validators.',
    );
  }

  final bool verbose;

  @override
  final name = 'doctor';

  @override
  final description = 'Show information about the installed tooling.';

  @override
  final String category = FlutterCommandCategory.sdk;

  @override
  Future<FlutterCommandResult> runCommand() async {
    if (argResults?.wasParsed('check-for-remote-artifacts') ?? false) {
      final String engineRevision = stringArg('check-for-remote-artifacts')!;
      if (engineRevision.startsWith(RegExp(r'[a-f0-9]{1,40}'))) {
        final bool success = await globals.doctor?.checkRemoteArtifacts(engineRevision) ?? false;
        if (success) {
          throwToolExit(
            'Artifacts for engine $engineRevision are missing or are '
            'not yet available.',
            exitCode: 1,
          );
        }
      } else {
        throwToolExit(
          'Remote artifact revision $engineRevision is not a valid '
          'git hash.',
        );
      }
    }

    var success = false; // Initialize success here

    final String? projectPath = stringArg('project-path');
    final Directory projectDir = projectPath != null
        ? globals.fs.directory(projectPath)
        : globals.fs.currentDirectory;
    final FlutterProject project = FlutterProject.fromDirectory(projectDir);
    final bool isProject = project.manifest.appName.isNotEmpty;
    final bool disableProjectValidators = boolArg('disable-project-validators');

    if (isProject && !disableProjectValidators) {
      final projectAnalysisValidator = ProjectAnalysisValidator(
        project: project,
        fileSystem: globals.fs,
        platform: globals.platform,
        processManager: globals.processManager,
        terminal: globals.terminal,
        artifacts: globals.artifacts!,
      );
      // final projectSuggestionsValidator = ProjectSuggestionsValidator(
      //   project: project,
      //   fileSystem: globals.fs,
      //   allProjectValidators: <ProjectValidator>[
      //     // Add default validators here or get them from somewhere
      //     // For now, let's assume we want GeneralInfoProjectValidator
      //     GeneralInfoProjectValidator(),
      //   ],
      //   processManager: globals.processManager,
      //   terminal: globals.terminal,
      // );
      final projectValidatorTasks = <ValidatorTask>[
        ValidatorTask(projectAnalysisValidator, projectAnalysisValidator.validate()),
        // TODO(jwren): ProjectSuggestionsValidator takes too long, should we include with a flag, include it anyways...?
        // ValidatorTask(projectSuggestionsValidator, projectSuggestionsValidator.validate()),
      ];
      final List<ValidatorTask> defaultTasks = globals.doctor!.startValidatorTasks();
      final combinedTasks = <ValidatorTask>[...defaultTasks, ...projectValidatorTasks];
      success =
          await globals.doctor?.diagnose(
            androidLicenses: boolArg('android-licenses'),
            verbose: verbose,
            androidLicenseValidator: androidLicenseValidator,
            startedValidatorTasks: combinedTasks,
          ) ??
          false;
    } else {
      success =
          await globals.doctor?.diagnose(
            androidLicenses: boolArg('android-licenses'),
            verbose: verbose,
            androidLicenseValidator: androidLicenseValidator,
          ) ??
          false;
      if (projectPath == null) {
        globals.logger.printStatus(
          'To see project-specific issues, run doctor in some project or specify with "flutter doctor --project-path <path>"',
        );
      }
    }

    return FlutterCommandResult(success ? ExitStatus.success : ExitStatus.warning);
  }
}
