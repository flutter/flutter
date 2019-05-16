// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/file_system.dart';
import '../build_info.dart';
import '../build_system/build_system.dart';
import '../convert.dart';
import '../globals.dart';
import '../project.dart';

import '../runner/flutter_command.dart';

class AssembleCommand extends FlutterCommand {
  AssembleCommand() {
    addSubcommand(AssembleRun());
    addSubcommand(AssembleDescribe());
    addSubcommand(AssembleListInputs());
  }
  @override
  String get description => 'Assemble and build flutter resources.';

  @override
  String get name => 'assemble';

  @override
  Future<FlutterCommandResult> runCommand() {
    return null;
  }
}

class AssembleRun extends FlutterCommand {
  AssembleRun() {
    argParser.addOption('task', help: 'The name of the task to describe.');
  }

  @override
  String get description => 'Execute the stages for a specified target.';

  @override
  String get name => 'run';

  @override
  Future<FlutterCommandResult> runCommand() async {
    final String taskName = argResults['task'];
    if (taskName == null) {
      printError('missing value for argument --task');
    }
    const BuildSystem buildSystem = BuildSystem();
    final FlutterProject flutterProject = FlutterProject.current();
    final Environment environment = Environment(
      buildDir: fs.directory(getBuildDirectory()),
      projectDir: flutterProject.directory,
      buildMode: BuildMode.debug,
      targetPlatform: TargetPlatform.android_arm,
      stampDir: fs.directory(getBuildDirectory()),
    );
    await buildSystem.build(taskName, environment);
    return null;
  }
}

class AssembleDescribe extends FlutterCommand {
  AssembleDescribe() {
    argParser.addOption('task', help: 'The name of the task to describe.');
  }

  @override
  String get description => 'List the stages for a specified target.';

  @override
  String get name => 'describe';

  @override
  Future<FlutterCommandResult> runCommand() {
    final String taskName = argResults['task'];
    if (taskName == null) {
      printError('missing value for argument --task');
    }
    const BuildSystem buildSystem = BuildSystem();
    final FlutterProject flutterProject = FlutterProject.current();
    final Environment environment = Environment(
      buildDir: fs.directory(getBuildDirectory()),
      projectDir: flutterProject.directory,
      buildMode: BuildMode.debug,
      targetPlatform: TargetPlatform.android_arm,
      stampDir: fs.directory(getBuildDirectory()),
    );
    print(
      json.encode(buildSystem.describe(taskName, environment))
    );
    return null;
  }
}

class AssembleListInputs extends FlutterCommand {
  AssembleListInputs() {
    argParser.addOption('task', help: 'The name of the task to list inputs.');
  }

  @override
  String get description => 'List the inputs for a particular target.';

  @override
  String get name => 'inputs';

  @override
  Future<FlutterCommandResult> runCommand() {
    final String taskName = argResults['task'];
    if (taskName == null) {
      printError('missing value for argument --task');
    }
    const BuildSystem buildSystem = BuildSystem();
    final FlutterProject flutterProject = FlutterProject.current();
    final Environment environment = Environment(
      buildDir: fs.directory(getBuildDirectory()),
      projectDir: flutterProject.directory,
      buildMode: BuildMode.debug,
      targetPlatform: TargetPlatform.android_arm,
      stampDir: fs.directory(getBuildDirectory()),
    );
    final List<Map<String, Object>> results = buildSystem.describe(taskName, environment);
    for (Map<String, Object> result in results) {
      if (result['name'] == taskName) {
        final List<String> inputs = result['inputs'];
        inputs.forEach(print);
      }
    }
    return null;
  }
}