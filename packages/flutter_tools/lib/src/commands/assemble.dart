// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/common.dart';
import '../base/file_system.dart';
import '../build_info.dart';
import '../build_system/build_system.dart';
import '../build_system/targets/assets.dart';
import '../build_system/targets/dart.dart';
import '../build_system/targets/linux.dart';
import '../build_system/targets/macos.dart';
import '../build_system/targets/windows.dart';
import '../convert.dart';
import '../project.dart';
import '../runner/flutter_command.dart';

// TODO(jonahwilliams): create a namepsaced registry system for targets.
const BuildSystem buildSystem = BuildSystem(<Target>[
  unpackMacos,
  unpackLinux,
  unpackWindows,
  copyAssets,
  kernelSnapshot,
]);

/// Assemble provides a low level API to interact with the flutter tool build
/// system.
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
  bool get isExperimental => true;

  @override
  Future<FlutterCommandResult> runCommand() {
    return null;
  }
}

abstract class AssembleBase extends FlutterCommand {
  AssembleBase() {
    argParser.addOption(
      'target-platform',
      allowed: const <String>[
        'android-arm',
        'android-arm64',
        'android-x64',
        'android-x86',
        'ios',
        'darwin-x64',
        'linux-x64',
        'windows-x64',
        'fuchsia',
        'web',
      ],
    );
    argParser.addOption(
      'build-mode',
      allowed: const <String>[
        'debug',
        'profile',
        'release',
      ],
    );
  }

  /// Returns the provided target platform.
  ///
  /// Throws a [ToolExit] if none is provided. This intentionally has no
  /// default.
  TargetPlatform get targetPlatform {
    final String value = argResults['target-platform'] ?? 'darwin-x64';
    if (value == null) {
      throwToolExit('--target-platform is required for flutter assemble.');
    }
    return getTargetPlatformForName(value);
  }

  /// Returns the provided build mode.
  ///
  /// Throws a [ToolExit] if none is provided. This intentionally has no
  /// default.
  BuildMode get buildMode {
    final String value = argResults['build-mode'] ?? 'debug';
    if (value == null) {
      throwToolExit('--build-mode is required for flutter assemble.');
    }
    return getBuildModeForName(value);
  }

  /// The name of the target we are describing or building.
  String get targetName {
    if (argResults.rest.isEmpty) {
      throwToolExit('missing target name for flutter assemble.');
    }
    return argResults.rest.first;
  }

  /// The environmental configuration for a build invocation.
  Environment get environment {
    final FlutterProject flutterProject = FlutterProject.current();
    final Environment result = Environment(
      buildDir: fs.directory(getBuildDirectory()),
      projectDir: flutterProject.directory,
      buildMode: buildMode,
      targetPlatform: targetPlatform,
    );
    return result;
  }
}

/// Execute a particular target.
class AssembleRun extends AssembleBase {
  @override
  String get description => 'Execute the stages for a specified target.';

  @override
  String get name => 'run';

  @override
  bool get isExperimental => true;

  @override
  Future<FlutterCommandResult> runCommand() async {
    try {
      await buildSystem.build(targetName, environment);
    } on Exception catch (err) {
      throwToolExit(err.toString());
    }
    return null;
  }
}

/// Fully describe a target and its dependencies.
class AssembleDescribe extends AssembleBase {
  @override
  String get description => 'List the stages for a specified target.';

  @override
  String get name => 'describe';

  @override
  bool get isExperimental => true;

  @override
  Future<FlutterCommandResult> runCommand() {
    try {
      print(
        json.encode(buildSystem.describe(targetName, environment))
      );
    } on Exception catch (err) {
      throwToolExit(err.toString());
    }
    return null;
  }
}

/// List input files for a target.
class AssembleListInputs extends AssembleBase {
  @override
  String get description => 'List the inputs for a particular target.';

  @override
  String get name => 'inputs';

  @override
  bool get isExperimental => true;

  @override
  Future<FlutterCommandResult> runCommand() {
    try {
      final List<Map<String, Object>> results = buildSystem.describe(targetName, environment);
      for (Map<String, Object> result in results) {
        if (result['name'] == targetName) {
          final List<String> inputs = result['inputs'];
          inputs.forEach(print);
        }
      }
    } on Exception catch (err) {
      throwToolExit(err.toString());
    }
    return null;
  }
}

