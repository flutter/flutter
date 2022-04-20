// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../analyze_project.dart';
import '../analyze_project_validator.dart';
import '../base/file_system.dart';
import '../globals.dart' as globals;
import '../project.dart';
import '../runner/flutter_command.dart';

class ValidateProjectCommand extends FlutterCommand {
  ValidateProjectCommand({this.verbose = false});

  final bool verbose;

  @override
  final String name = 'analyze-project';

  @override
  final String description = 'Show information about the current project.';

  @override
  final String category = FlutterCommandCategory.project;

  @override
  Future<FlutterCommandResult> runCommand() async {
    globals.flutterVersion.fetchTagsAndUpdate();

    Directory workingDirectory;
    final String userPath = getUserPath();

    if (userPath.isEmpty) {
      workingDirectory = globals.fs.currentDirectory;
    } else {
      workingDirectory = globals.fs.directory(userPath);
    }
    
    final FlutterProject project =  FlutterProject.fromDirectory(workingDirectory);
    final List<ProjectValidatorResult> results = <ProjectValidatorResult>[];

    final AvailableProjectValidators availableProjectValidators = AvailableProjectValidators();
    final Set<ProjectValidatorTask> ranValidators = <ProjectValidatorTask>{};

    for (final SupportedPlatform platform in project.getSupportedPlatforms()){
      for (final ProjectValidatorTask validatorTask in availableProjectValidators.getValidatorTasks(platform)) {
        if (!ranValidators.contains(validatorTask)) {
          results.addAll(validatorTask.start(project));
          ranValidators.add(validatorTask);
        }
      }
    }

    presentResults(results);
    return const FlutterCommandResult(ExitStatus.success);
  }

  void presentResults(final List<ProjectValidatorResult> results) {
    StringBuffer buffer = StringBuffer();

    for (ProjectValidatorResult result in results) {
      addToBufferResult(result, buffer);
      buffer.write('\n');
      globals.logger.printBox(buffer.toString());
    }
  }

  void addToBufferResult(ProjectValidatorResult result, StringBuffer buffer) {
    String icon;
    switch(result.currentStatus()) {
      case Status.error:
        icon = '[X]';
        break;
      case Status.success:
        icon = '[✓]';
        break;
      case Status.warning:
        icon = '[!]';
        break;
      case Status.notReady:
        icon = '[?]';
        break;
    }

    buffer.write('$icon ${result.toString()}');
  }

  String getUserPath(){
    return (argResults == null || argResults!.rest.isEmpty) ? '' : argResults!.rest[0];
  }
}
