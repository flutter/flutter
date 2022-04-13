// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import '../analyze_project.dart';
import '../globals.dart' as globals;
import '../project.dart';
import '../runner/flutter_command.dart';
import '../base/file_system.dart';

class AnalyzeProjectCommand extends FlutterCommand {
  AnalyzeProjectCommand({this.verbose = false});

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
    
    FlutterProject project =  FlutterProject.fromDirectory(workingDirectory);
    List<ProjectValidatorResult> results = <ProjectValidatorResult>[];

    //final AnalyzeProject analyzeProject = AnalyzeProject(logger: globals.logger);
    //final bool result = await analyzeProject.diagnose();
    return FlutterCommandResult(true ? ExitStatus.success : ExitStatus.warning);
  }

  String getUserPath(){
    // TODO
    return '';
  }
}
