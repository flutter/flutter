// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../analyze_project.dart';
import '../analyze_project_validator.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../project.dart';
import '../runner/flutter_command.dart';

class ValidateProjectCommand extends FlutterCommand {
  ValidateProjectCommand({
    required FileSystem fileSystem,
    required Logger logger,
    required List<ProjectValidator> allProjectValidators,
    bool verbose = false
  }): fileSystem = fileSystem,
      logger = logger,
      allProjectValidators = allProjectValidators,
      verbose = verbose;

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
    final List<Future<List<ProjectValidatorResult>>> results = <Future<List<ProjectValidatorResult>>>[];
    final Set<ProjectValidator> ranValidators = <ProjectValidator>{};

    bool hasCrash = false;
    for (final ProjectValidator validator in allProjectValidators) {
      if (!ranValidators.contains(validator) && validator.supportsProject(project)) {
          results.add(validator.start(project).catchError((Object exception, StackTrace trace) {
            hasCrash = true;
            return <ProjectValidatorResult>[ProjectValidatorResult.crash(exception, trace)];
          }));
        ranValidators.add(validator);
      }
    }

    printResults(await Future.wait(results));
    if (hasCrash) {
      return const FlutterCommandResult(ExitStatus.fail);
    }
    return const FlutterCommandResult(ExitStatus.success);
  }

  void printResults(final List<List<ProjectValidatorResult>> futureResults) {
    final StringBuffer buffer = StringBuffer();

    for (final List<ProjectValidatorResult> resultList in futureResults) {
      for (final ProjectValidatorResult result in resultList) {
        addToBufferResult(result, buffer);
      }
    }

    logger.printBox(buffer.toString());
  }

  void addToBufferResult(ProjectValidatorResult result, StringBuffer buffer) {
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

    buffer.writeln('$icon $result');
  }

  String getUserPath(){
    return (argResults == null || argResults!.rest.isEmpty) ? '' : argResults!.rest[0];
  }
}
