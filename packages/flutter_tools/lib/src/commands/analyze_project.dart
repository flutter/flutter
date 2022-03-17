// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../analyze_project.dart';
import '../globals.dart' as globals;
import '../runner/flutter_command.dart';

class AnalyzeProjectCommand extends FlutterCommand {
  AnalyzeProjectCommand({this.verbose = false});

  final bool verbose;

  @override
  final String name = 'analyze_project';

  @override
  final String description = 'Show information about the current project.';

  @override
  final String category = FlutterCommandCategory.project;

  @override
  Future<FlutterCommandResult> runCommand() async {
    globals.flutterVersion.fetchTagsAndUpdate();
    final AnalyzeProject analyzeProject = AnalyzeProject(logger: globals.logger);
    final bool result = await analyzeProject.diagnose();
    return FlutterCommandResult(result ? ExitStatus.success : ExitStatus.warning);
  }
}
