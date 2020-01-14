// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../base/common.dart';
import '../base/file_system.dart';
import '../build_system/build_system.dart';
import '../build_system/depfile.dart';
import '../build_system/targets/android.dart';
import '../build_system/targets/assets.dart';
import '../build_system/targets/dart.dart';
import '../build_system/targets/ios.dart';
import '../build_system/targets/linux.dart';
import '../build_system/targets/macos.dart';
import '../build_system/targets/web.dart';
import '../build_system/targets/windows.dart';
import '../cache.dart';
import '../globals.dart' as globals;
import '../project.dart';
import '../reporting/reporting.dart';
import '../runner/flutter_command.dart';

/// All currently implemented targets.
const List<Target> _kDefaultTargets = <Target>[
  UnpackWindows(),
  CopyAssets(),
  KernelSnapshot(),
  AotElfProfile(),
  AotElfRelease(),
  AotAssemblyProfile(),
  AotAssemblyRelease(),
  DebugMacOSFramework(),
  DebugMacOSBundleFlutterAssets(),
  ProfileMacOSBundleFlutterAssets(),
  ReleaseMacOSBundleFlutterAssets(),
  DebugBundleLinuxAssets(),
  WebServiceWorker(),
  DebugAndroidApplication(),
  FastStartAndroidApplication(),
  ProfileAndroidApplication(),
  ReleaseAndroidApplication(),
  // These are one-off rules for bundle and aot compat
  ReleaseCopyFlutterAotBundle(),
  ProfileCopyFlutterAotBundle(),
  CopyFlutterBundle(),
  // Android ABI specific AOT rules.
  androidArmProfileBundle,
  androidArm64ProfileBundle,
  androidx64ProfileBundle,
  androidArmReleaseBundle,
  androidArm64ReleaseBundle,
  androidx64ReleaseBundle,
];

/// Assemble provides a low level API to interact with the flutter tool build
/// system.
class AssembleCommand extends FlutterCommand {
  AssembleCommand() {
    argParser.addMultiOption(
      'define',
      abbr: 'd',
      help: 'Allows passing configuration to a target with --define=target=key=value.',
    );
    argParser.addOption('depfile', help: 'A file path where a depfile will be written. '
      'This contains all build inputs and outputs in a make style syntax'
    );
    argParser.addOption('build-inputs', help: 'A file path where a newline '
        'separated file containing all inputs used will be written after a build.'
        ' This file is not included as a build input or output. This file is not'
        ' written if the build fails for any reason.');
    argParser.addOption('build-outputs', help: 'A file path where a newline '
        'separated file containing all outputs used will be written after a build.'
        ' This file is not included as a build input or output. This file is not'
        ' written if the build fails for any reason.');
    argParser.addOption('output', abbr: 'o', help: 'A directory where output '
        'files will be written. Must be either absolute or relative from the '
        'root of the current Flutter project.',
    );
    argParser.addOption(kExtraGenSnapshotOptions);
    argParser.addOption(
      'resource-pool-size',
      help: 'The maximum number of concurrent tasks the build system will run.',
    );
  }

  @override
  String get description => 'Assemble and build flutter resources.';

  @override
  String get name => 'assemble';

  @override
  Future<Map<CustomDimensions, String>> get usageValues async {
    final FlutterProject futterProject = FlutterProject.current();
    if (futterProject == null) {
      return const <CustomDimensions, String>{};
    }
    try {
      final Environment localEnvironment = environment;
      return <CustomDimensions, String>{
        CustomDimensions.commandBuildBundleTargetPlatform: localEnvironment.defines['TargetPlatform'],
        CustomDimensions.commandBuildBundleIsModule: '${futterProject.isModule}',
      };
    } catch (err) {
      // We've failed to send usage.
    }
    return const <CustomDimensions, String>{};
  }

  /// The target(s) we are building.
  List<Target> get targets {
    if (argResults.rest.isEmpty) {
      throwToolExit('missing target name for flutter assemble.');
    }
    final String name = argResults.rest.first;
    final Map<String, Target> targetMap = <String, Target>{
      for (final Target target in _kDefaultTargets)
        target.name: target
    };
    final List<Target> results = <Target>[
      for (final String targetName in argResults.rest)
        if (targetMap.containsKey(targetName))
          targetMap[targetName]
    ];
    if (results.isEmpty) {
      throwToolExit('No target named "$name" defined.');
    }
    return results;
  }

  /// The environmental configuration for a build invocation.
  Environment get environment {
    final FlutterProject flutterProject = FlutterProject.current();
    String output = stringArg('output');
    if (output == null) {
      throwToolExit('--output directory is required for assemble.');
    }
    // If path is relative, make it absolute from flutter project.
    if (globals.fs.path.isRelative(output)) {
      output = globals.fs.path.join(flutterProject.directory.path, output);
    }
    final Environment result = Environment(
      outputDir: globals.fs.directory(output),
      buildDir: flutterProject.directory
          .childDirectory('.dart_tool')
          .childDirectory('flutter_build'),
      projectDir: flutterProject.directory,
      defines: _parseDefines(stringsArg('define')),
      cacheDir: globals.cache.getRoot(),
      flutterRootDir: globals.fs.directory(Cache.flutterRoot),
    );
    return result;
  }

  Map<String, String> _parseDefines(List<String> values) {
    final Map<String, String> results = <String, String>{};
    for (final String chunk in values) {
      final int indexEquals = chunk.indexOf('=');
      if (indexEquals == -1) {
        throwToolExit('Improperly formatted define flag: $chunk');
      }
      final String key = chunk.substring(0, indexEquals);
      final String value = chunk.substring(indexEquals + 1);
      results[key] = value;
    }
    // Workaround for extraGenSnapshot formatting.
    if (argResults.wasParsed(kExtraGenSnapshotOptions)) {
      results[kExtraGenSnapshotOptions] = argResults[kExtraGenSnapshotOptions] as String;
    }
    return results;
  }

  @override
  Future<FlutterCommandResult> runCommand() async {
    final List<Target> targets = this.targets;
    final Target target = targets.length == 1 ? targets.single : _CompositeTarget(targets);
    final BuildResult result = await buildSystem.build(target, environment, buildSystemConfig: BuildSystemConfig(
      resourcePoolSize: argResults.wasParsed('resource-pool-size')
        ? int.tryParse(stringArg('resource-pool-size'))
        : null,
    ));
    if (!result.success) {
      for (final ExceptionMeasurement measurement in result.exceptions.values) {
        globals.printError('Target ${measurement.target} failed: ${measurement.exception}',
          stackTrace: measurement.fatal
            ? measurement.stackTrace
            : null,
        );
      }
      throwToolExit('build failed.');
    }
    globals.printTrace('build succeeded.');
    if (argResults.wasParsed('build-inputs')) {
      writeListIfChanged(result.inputFiles, stringArg('build-inputs'));
    }
    if (argResults.wasParsed('build-outputs')) {
      writeListIfChanged(result.outputFiles, stringArg('build-outputs'));
    }
    if (argResults.wasParsed('depfile')) {
      final File depfileFile = globals.fs.file(stringArg('depfile'));
      final Depfile depfile = Depfile(result.inputFiles, result.outputFiles);
      depfile.writeToFile(globals.fs.file(depfileFile));
    }
    return FlutterCommandResult.success();
  }
}

@visibleForTesting
void writeListIfChanged(List<File> files, String path) {
  final File file = globals.fs.file(path);
  final StringBuffer buffer = StringBuffer();
  // These files are already sorted.
  for (final File file in files) {
    buffer.writeln(file.path);
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

class _CompositeTarget extends Target {
  _CompositeTarget(this.dependencies);

  @override
  final List<Target> dependencies;

  @override
  String get name => '_composite';

  @override
  Future<void> build(Environment environment) async { }

  @override
  List<Source> get inputs => <Source>[];

  @override
  List<Source> get outputs => <Source>[];
}
