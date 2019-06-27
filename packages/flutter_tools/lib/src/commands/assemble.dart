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
import '../globals.dart';
import '../project.dart';
import '../runner/flutter_command.dart';

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
    argParser.addMultiOption(
      'define',
      abbr: 'd',
      help: 'Allows passing configuration to a target with --define=target=key=value.'
    );
    argParser.addOption(
      'build-mode',
      allowed: const <String>[
        'debug',
        'profile',
        'release',
      ],
    );
    argParser.addOption(
      'resource-pool-size',
      help: 'The maximum number of concurrent tasks the build system will run.'
    );
  }

  // TODO(jonahwilliams): create a namepsaced registry system for targets.
  static final BuildSystem buildSystem = BuildSystem(<String, Target>{
    unpackMacos.name: unpackMacos,
    unpackLinux.name: unpackLinux,
    unpackWindows.name: unpackWindows,
    copyAssets.name: copyAssets,
    kernelSnapshot.name: kernelSnapshot,
    aotElf.name: aotElf,
  });

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
      defines: _parseDefines(argResults['define']),
    );
    return result;
  }

  static Map<String, String> _parseDefines(List<String> values) {
    final Map<String, String> results = <String, String>{};
    for (String chunk in values) {
      final List<String> parts = chunk.split('=');
      if (parts.length != 2) {
        throwToolExit('Improperly formatted define flag: $chunk');
      }
      final String key = parts[0];
      final String value = parts[1];
      results[key] = value;
    }
    return results;
  }
}

/// Execute a build starting from a target action.
class AssembleRun extends AssembleBase {
  @override
  String get description => 'Execute the stages for a specified target.';

  @override
  String get name => 'run';

  @override
  bool get isExperimental => true;

  @override
  Future<FlutterCommandResult> runCommand() async {
    final bool passed = await AssembleBase.buildSystem.build(targetName, environment, BuildSystemConfig(
      resourcePoolSize: argResults['resource-pool-size'],
    ));
    if (!passed) {
      throwToolExit('build failed.');
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
        json.encode(AssembleBase.buildSystem.describe(targetName, environment))
      );
    } on Exception catch (err, stackTrace) {
      printTrace(stackTrace.toString());
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
      final List<Map<String, Object>> results = AssembleBase
          .buildSystem.describe(targetName, environment);
      for (Map<String, Object> result in results) {
        if (result['name'] == targetName) {
          final List<String> inputs = result['inputs'];
          inputs.forEach(print);
        }
      }
    } on Exception catch (err, stackTrace) {
      printTrace(stackTrace.toString());
      throwToolExit(err.toString());
    }
    return null;
  }
}

