// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/common.dart';
import '../codegen.dart';
import '../project.dart';
import '../runner/flutter_command.dart';

class GenerateCommand extends FlutterCommand {
  GenerateCommand() {
    usesTargetOption();
  }
  @override
  String get description => 'run code generators.';

  @override
  String get name => 'generate';

  @override
  bool get hidden => true;

  @override
  Future<FlutterCommandResult> runCommand() async {
    if (!experimentalBuildEnabled) {
      throwToolExit('FLUTTER_EXPERIMENTAL_BUILD is not enabled, codegen is unsupported.');
    }
    final FlutterProject flutterProject = await FlutterProject.current();
    await codeGenerator.generate(flutterProject, mainPath: argResults['target']);
    return null;
  }
}
