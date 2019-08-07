// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../base/common.dart';
import '../base/context.dart';
import '../base/file_system.dart';
import '../build_system/build_system.dart';
import '../build_system/definitions.dart';
import '../build_system/phases.dart';
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
    argParser.addOption('build-inputs', help: 'A file path where a newline '
        'separated file containing all inputs used will be written after a build.'
        ' This file is not included as a build input or output. This file is not'
        ' written if the build fails for any reason.');
    argParser.addOption('build-outputs', help: 'A file path where a newline '
        'separated file containing all outputs used will be written after a build.'
        ' This file is not included as a build input or output. This file is not'
        ' written if the build fails for any reason.');
    argParser.addOption(
      'resource-pool-size',
      help: 'The maximum number of concurrent tasks the build system will run.'
    );
  }

  @override
  String get description => 'Assemble and build flutter resources.';

  @override
  String get name => 'assemble';

  /// The [BuildDefinition] we are building.
  BuildDefinition createBuildDefinition() {
    if (argResults.rest.isEmpty) {
      throwToolExit('missing target name for flutter assemble.');
    }
    final String name = argResults.rest.first;
    return kAllBuildDefinitions.firstWhere((BuildDefinition definition) => definition.name == name);
  }

  /// The environmental configuration for a build invocation.
  Environment createEnvironment() {
    final FlutterProject flutterProject = FlutterProject.current();
    final Environment result = Environment(
      buildDir: flutterProject.directory
          .childDirectory('.dart_tool')
          .childDirectory('flutter_build'),
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

  @override
  Future<FlutterCommandResult> runCommand() async {
    final Environment environment = createEnvironment();
    final BuildDefinition buildDefinition = createBuildDefinition();
    final Target target = await buildDefinition.createBuild(environment);
    final BuildResult result = await buildSystem.build(target, environment, buildSystemConfig: BuildSystemConfig(
      resourcePoolSize: argResults['resource-pool-size'],
    ));
    if (!result.success) {
      for (MapEntry<String, ExceptionMeasurement> data in result.exceptions.entries) {
        printError('Target ${data.key} failed: ${data.value.exception}');
        printError('${data.value.exception}');
      }
      throwToolExit('build failed.');
    }
    printStatus('build succeeded.');
    if (argResults.wasParsed('build-inputs')) {
      writeListIfChanged(result.inputFiles, argResults['build-inputs']);
    }
    if (argResults.wasParsed('build-outputs')) {
      writeListIfChanged(result.outputFiles, argResults['build-outputs']);
    }
    return null;
  }
}

@visibleForTesting
void writeListIfChanged(List<File> files, String path) {
  final File file = fs.file(path);
  final StringBuffer buffer = StringBuffer();
  // These files are already sorted.
  for (File file in files) {
    buffer.writeln(file.resolveSymbolicLinksSync());
  }
  final String newContents = buffer.toString();
  if (!file.existsSync()) {
    file.writeAsStringSync(newContents);
  }
  final String currentContents = file.readAsStringSync();
  if (currentContents != newContents) {
    file.writeAsStringSync(newContents);
  }
}
