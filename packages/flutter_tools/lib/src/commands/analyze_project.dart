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
  ValidateProjectCommand(this.fileSystem, this.logger, {this.verbose = false});

  final FileSystem fileSystem;
  final Logger logger;
  final bool verbose;

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
    final List<ProjectValidatorResult> results = <ProjectValidatorResult>[];
    final Set<ProjectValidator> ranValidators = <ProjectValidator>{};

    for (final ProjectValidator validator in allProjectValidators) {
      if (!ranValidators.contains(validator) && validator.supportsProject(project)) {
        results.addAll(await validator.start(project));
        ranValidators.add(validator);
      }
    }

    presentResults(results);
    return const FlutterCommandResult(ExitStatus.success);
  }

  void presentResults(final List<ProjectValidatorResult> results) {
    final StringBuffer buffer = StringBuffer();

    for (final ProjectValidatorResult result in results) {
      addToBufferResult(result, buffer);
      buffer.write('\n');
    }
    logger.printBox(buffer.toString());
  }

  void addToBufferResult(ProjectValidatorResult result, StringBuffer buffer) {
    String icon;
    switch(result.status) {
      case StatusProjectValidator.error:
        icon = '[X]';
        break;
      case StatusProjectValidator.success:
        icon = '[✓]';
        break;
      case StatusProjectValidator.warning:
        icon = '[!]';
        break;
    }

    buffer.write('$icon $result');
  }

  String getUserPath(){
    return (argResults == null || argResults!.rest.isEmpty) ? '' : argResults!.rest[0];
  }
}
