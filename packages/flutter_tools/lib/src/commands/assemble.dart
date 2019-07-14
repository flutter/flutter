// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/common.dart';
import '../base/context.dart';
import '../base/file_system.dart';
import '../build_info.dart';
import '../build_system/build_system.dart';
import '../build_system/exceptions.dart';
import '../build_system/output_formats.dart';
import '../globals.dart';
import '../project.dart';
import '../runner/flutter_command.dart';

/// The [BuildSystem] instance.
BuildSystem get buildSystem => context.get<BuildSystem>();

/// Assemble provides a low level API to interact with the flutter tool build
/// system.
class AssembleCommand extends FlutterCommand {
  AssembleCommand() {
    argParser.addMultiOption(
      'define',
      abbr: 'd',
      help: 'Allows passing configuration to a target with --define=target=key=value.'
    );
    argParser.addOption(
      'project-dir',
      help: 'The root directory of the project to build.'
    );
    argParser.addOption(
      'resource-pool-size',
      help: 'The maximum number of concurrent tasks the build system will run.'
    );
    argParser.addOption(
      'xcfilelist-path',
      help: 'The location where a FlutterInputs.xcfilelist and FlutterOutputs.xcfilelist'
      ' will be generated. If not provided these files are not created.'
    );
  }

  /// The name of the target we are describing or building.
  String get targetName {
    if (argResults.rest.isEmpty) {
      throwToolExit('missing target name for flutter assemble.');
    }
    return argResults.rest.first;
  }

  /// The environmental configuration for a build invocation.
  Environment buildEnvironment() {
    final Directory projectDirectory = argResults['project-dir'] == null
        ? fs.currentDirectory
        : fs.directory(argResults['project-dir']);
    final FlutterProject flutterProject = FlutterProject.fromDirectory(projectDirectory);
    final Map<String, String> defines = buildSystem.collectDefines(targetName,  _parseDefines(argResults['define']));
    final Environment result = Environment(
      buildDir: fs.directory(fs.path.join(projectDirectory.path, getBuildDirectory())),
      projectDir: flutterProject.directory,
      defines: defines,
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

  @override
  String get description => 'Assemble and build flutter resources.';

  @override
  String get name => 'assemble';

  @override
  bool get isExperimental => true;

  @override
  Future<FlutterCommandResult> runCommand() async {
    Environment environment;
    try {
      environment = buildEnvironment();
    } on ConflictingDefineException catch (err) {
      throwToolExit(err.toString());
    }
    final BuildResult result = await buildSystem.build(targetName, environment, BuildSystemConfig(
      resourcePoolSize: argResults['resource-pool-size'],
    ));
    if (!result.success) {
      for (MapEntry<String, ExceptionMeasurement> data in result.exceptions.entries) {
        printError('Target ${data.key} failed: ${data.value.exception}');
        printError('${data.value.exception}');
      }
      throwToolExit('build failed');
    } else {
      printStatus('build succeeded');
      final String generateXcfileListPath = argResults['xcfilelist-path'];
      if (generateXcfileListPath != null) {
        generateXcFileList(targetName, environment, generateXcfileListPath);
      }
    }
    return null;
  }
}
