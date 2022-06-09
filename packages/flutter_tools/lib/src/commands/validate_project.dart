// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/file_system.dart';
import '../base/logger.dart';
import '../project.dart';
import '../project_validator.dart';
import '../project_validator_result.dart';
import '../runner/flutter_command.dart';

class ValidateProjectCommand extends FlutterCommand {
  ValidateProjectCommand({
    required this.fileSystem,
    required this.logger,
    required this.allProjectValidators,
    this.verbose = false
  });

  final FileSystem fileSystem;
  final Logger logger;
  final bool verbose;
  final List<ProjectValidator> allProjectValidators;

  @override
  final String name = 'validate-project';

  @override
  final String description = 'Show information about the current project.';

  @override
  final String category = FlutterCommandCategory.project;

  @override
  Future<FlutterCommandResult> runCommand() async {
    final String userPath = getUserPath();
    final Directory workingDirectory = userPath.isEmpty ? fileSystem.currentDirectory : fileSystem.directory(userPath);

    final FlutterProject project =  FlutterProject.fromDirectory(workingDirectory);
    final Map<ProjectValidator, Future<List<ProjectValidatorResult>>> results = <ProjectValidator, Future<List<ProjectValidatorResult>>>{};

    bool hasCrash = false;
    for (final ProjectValidator validator in allProjectValidators) {
      if (!results.containsKey(validator) && validator.supportsProject(project)) {
        results[validator] = validator.start(project).catchError((Object exception, StackTrace trace) {
          hasCrash = true;
          return <ProjectValidatorResult>[ProjectValidatorResult.crash(exception, trace)];
        });
      }
    }

    final StringBuffer buffer = StringBuffer();
    final List<String> resultsString = <String>[];
    for (final ProjectValidator validator in results.keys) {
      if (results[validator] != null) {
        resultsString.add(validator.title);
        addResultString(validator.title, await results[validator], resultsString);
      }
    }
    buffer.writeAll(resultsString, '\n');
    logger.printBox(buffer.toString());

    if (hasCrash) {
      return const FlutterCommandResult(ExitStatus.fail);
    }
    return const FlutterCommandResult(ExitStatus.success);
  }


  void addResultString(final String title, final List<ProjectValidatorResult>? results, final List<String> resultsString) {
    if (results != null) {
      for (final ProjectValidatorResult result in results) {
        resultsString.add(getStringResult(result));
      }
    }
  }

  String getStringResult(ProjectValidatorResult result) {
    final String icon;
    switch(result.status) {
      case StatusProjectValidator.error:
        icon = '[✗]';
        break;
      case StatusProjectValidator.success:
        icon = '[✓]';
        break;
      case StatusProjectValidator.warning:
        icon = '[!]';
        break;
      case StatusProjectValidator.crash:
        icon = '[☠]';
        break;
    }

    return '$icon $result';
  }

  String getUserPath(){
    return (argResults == null || argResults!.rest.isEmpty) ? '' : argResults!.rest[0];
  }
}
