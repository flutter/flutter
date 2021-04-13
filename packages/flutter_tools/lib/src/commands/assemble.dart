// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:meta/meta.dart';

import '../base/common.dart';
import '../base/file_system.dart';
import '../build_info.dart';
import '../build_system/build_system.dart';
import '../build_system/depfile.dart';
import '../build_system/targets/android.dart';
import '../build_system/targets/assets.dart';
import '../build_system/targets/common.dart';
import '../build_system/targets/deferred_components.dart';
import '../build_system/targets/ios.dart';
import '../build_system/targets/linux.dart';
import '../build_system/targets/macos.dart';
import '../build_system/targets/web.dart';
import '../build_system/targets/windows.dart';
import '../cache.dart';
import '../convert.dart';
import '../globals.dart' as globals;
import '../project.dart';
import '../reporting/reporting.dart';
import '../runner/flutter_command.dart';

/// All currently implemented targets.
List<Target> _kDefaultTargets = <Target>[
  // Shared targets
  const CopyAssets(),
  const KernelSnapshot(),
  const AotElfProfile(TargetPlatform.android_arm),
  const AotElfRelease(TargetPlatform.android_arm),
  const AotAssemblyProfile(),
  const AotAssemblyRelease(),
  // macOS targets
  const DebugMacOSFramework(),
  const DebugMacOSBundleFlutterAssets(),
  const ProfileMacOSBundleFlutterAssets(),
  const ReleaseMacOSBundleFlutterAssets(),
  // Linux targets
  const DebugBundleLinuxAssets(TargetPlatform.linux_x64),
  const DebugBundleLinuxAssets(TargetPlatform.linux_arm64),
  const ProfileBundleLinuxAssets(TargetPlatform.linux_x64),
  const ProfileBundleLinuxAssets(TargetPlatform.linux_arm64),
  const ReleaseBundleLinuxAssets(TargetPlatform.linux_x64),
  const ReleaseBundleLinuxAssets(TargetPlatform.linux_arm64),
  // Web targets
  const WebServiceWorker(),
  const ReleaseAndroidApplication(),
  // This is a one-off rule for bundle and aot compat.
  const CopyFlutterBundle(),
  // Android targets,
  const DebugAndroidApplication(),
  const ProfileAndroidApplication(),
  // Android ABI specific AOT rules.
  androidArmProfileBundle,
  androidArm64ProfileBundle,
  androidx64ProfileBundle,
  androidArmReleaseBundle,
  androidArm64ReleaseBundle,
  androidx64ReleaseBundle,
  // Deferred component enabled AOT rules
  androidArmProfileDeferredComponentsBundle,
  androidArm64ProfileDeferredComponentsBundle,
  androidx64ProfileDeferredComponentsBundle,
  androidArmReleaseDeferredComponentsBundle,
  androidArm64ReleaseDeferredComponentsBundle,
  androidx64ReleaseDeferredComponentsBundle,
  // iOS targets
  const DebugIosApplicationBundle(),
  const ProfileIosApplicationBundle(),
  const ReleaseIosApplicationBundle(),
  // Windows targets
  const UnpackWindows(),
  const DebugBundleWindowsAssets(),
  const ProfileBundleWindowsAssets(),
  const ReleaseBundleWindowsAssets(),
  // Windows UWP targets
  const DebugBundleWindowsAssetsUwp(),
  const ProfileBundleWindowsAssetsUwp(),
  const ReleaseBundleWindowsAssetsUwp(),
];

// TODO(ianh): https://github.com/dart-lang/args/issues/181 will allow us to remove useLegacyNames
// and just switch to arguments that use the regular style, which still supporting the old names.
// When fixing this, remove the hack in test/general.shard/args_test.dart that ignores these names.
const bool useLegacyNames = true;

/// Assemble provides a low level API to interact with the flutter tool build
/// system.
class AssembleCommand extends FlutterCommand {
  AssembleCommand({ bool verboseHelp = false, @required BuildSystem buildSystem })
    : _buildSystem = buildSystem {
    argParser.addMultiOption(
      'define',
      abbr: 'd',
      valueHelp: 'target=key=value',
      help: 'Allows passing configuration to a target, as in "--define=target=key=value".',
    );
    argParser.addOption(
      'performance-measurement-file',
      help: 'Output individual target performance to a JSON file.'
    );
    argParser.addMultiOption(
      'input',
      abbr: 'i',
      help: 'Allows passing additional inputs with "--input=key=value". Unlike '
      'defines, additional inputs do not generate a new configuration; instead '
      'they are treated as dependencies of the targets that use them.'
    );
    argParser.addOption('depfile',
      help: 'A file path where a depfile will be written. '
            'This contains all build inputs and outputs in a Make-style syntax.'
    );
    argParser.addOption('build-inputs', help: 'A file path where a newline-separated '
        'file containing all inputs used will be written after a build. '
        'This file is not included as a build input or output. This file is not '
        'written if the build fails for any reason.');
    argParser.addOption('build-outputs', help: 'A file path where a newline-separated '
        'file containing all outputs created will be written after a build. '
        'This file is not included as a build input or output. This file is not '
        'written if the build fails for any reason.');
    argParser.addOption('output', abbr: 'o', help: 'A directory where output '
        'files will be written. Must be either absolute or relative from the '
        'root of the current Flutter project.',
    );
    usesExtraDartFlagOptions(verboseHelp: verboseHelp, useLegacyNames: useLegacyNames);
    usesDartDefineOption(useLegacyNames: useLegacyNames);
    argParser.addOption(
      'resource-pool-size',
      help: 'The maximum number of concurrent tasks the build system will run.',
    );
  }

  final BuildSystem _buildSystem;

  @override
  String get description => 'Assemble and build Flutter resources.';

  @override
  String get name => 'assemble';

  @override
  Future<Map<CustomDimensions, String>> get usageValues async {
    final FlutterProject flutterProject = FlutterProject.current();
    if (flutterProject == null) {
      return const <CustomDimensions, String>{};
    }
    try {
      return <CustomDimensions, String>{
        CustomDimensions.commandBuildBundleTargetPlatform: environment.defines[kTargetPlatform],
        CustomDimensions.commandBuildBundleIsModule: '${flutterProject.isModule}',
      };
    } on Exception {
      // We've failed to send usage.
    }
    return const <CustomDimensions, String>{};
  }

  @override
  Future<Set<DevelopmentArtifact>> get requiredArtifacts async {
    final String platform = environment.defines[kTargetPlatform];
    if (platform == null) {
      return super.requiredArtifacts;
    }

    final TargetPlatform targetPlatform = getTargetPlatformForName(platform);
    final DevelopmentArtifact artifact = artifactFromTargetPlatform(targetPlatform);
    if (artifact != null) {
      return <DevelopmentArtifact>{artifact};
    }
    return super.requiredArtifacts;
  }

  /// The target(s) we are building.
  List<Target> createTargets() {
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

  bool isDeferredComponentsTargets() {
    for (final String targetName in argResults.rest) {
      if (deferredComponentsTargets.contains(targetName)) {
        return true;
      }
    }
    return false;
  }

  bool isDebug() {
    for (final String targetName in argResults.rest) {
      if (targetName.contains('debug')) {
        return true;
      }
    }
    return false;
  }

  Environment get environment => _environment ??= createEnvironment();
  Environment _environment;

  /// The environmental configuration for a build invocation.
  Environment createEnvironment() {
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
      inputs: _parseDefines(stringsArg('input')),
      cacheDir: globals.cache.getRoot(),
      flutterRootDir: globals.fs.directory(Cache.flutterRoot),
      artifacts: globals.artifacts,
      fileSystem: globals.fs,
      logger: globals.logger,
      processManager: globals.processManager,
      platform: globals.platform,
      engineVersion: globals.artifacts.isLocalEngine
        ? null
        : globals.flutterVersion.engineRevision
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
    if (argResults.wasParsed(useLegacyNames ? kExtraGenSnapshotOptions : FlutterOptions.kExtraGenSnapshotOptions)) {
      results[kExtraGenSnapshotOptions] = (argResults[useLegacyNames ? kExtraGenSnapshotOptions : FlutterOptions.kExtraGenSnapshotOptions] as List<String>).join(',');
    }
    if (argResults.wasParsed(useLegacyNames ? kDartDefines : FlutterOptions.kDartDefinesOption)) {
      results[kDartDefines] = (argResults[useLegacyNames ? kDartDefines : FlutterOptions.kDartDefinesOption] as List<String>).join(',');
    }
    results[kDeferredComponents] = 'false';
    if (FlutterProject.current().manifest.deferredComponents != null && isDeferredComponentsTargets() && !isDebug()) {
      results[kDeferredComponents] = 'true';
    }
    if (argResults.wasParsed(useLegacyNames ? kExtraFrontEndOptions : FlutterOptions.kExtraFrontEndOptions)) {
      results[kExtraFrontEndOptions] = (argResults[useLegacyNames ? kExtraFrontEndOptions : FlutterOptions.kExtraFrontEndOptions] as List<String>).join(',');
    }
    return results;
  }

  @override
  Future<FlutterCommandResult> runCommand() async {
    final List<Target> targets = createTargets();
    final List<Target> nonDeferredTargets = <Target>[];
    final List<Target> deferredTargets = <AndroidAotDeferredComponentsBundle>[];
    for (final Target target in targets) {
      if (deferredComponentsTargets.contains(target.name)) {
        deferredTargets.add(target);
      } else {
        nonDeferredTargets.add(target);
      }
    }
    Target target;
    List<String> decodedDefines;
    try {
      decodedDefines = decodeDartDefines(environment.defines, kDartDefines);
    } on FormatException {
      throwToolExit(
        'Error parsing assemble command: your generated configuration may be out of date. '
        "Try re-running 'flutter build ios' or the appropriate build command."
      );
    }
    if (FlutterProject.current().manifest.deferredComponents != null
        && decodedDefines.contains('validate-deferred-components=true')
        && deferredTargets.isNotEmpty
        && !isDebug()) {
      // Add deferred components validation target that require loading units.
      target = DeferredComponentsGenSnapshotValidatorTarget(
        deferredComponentsDependencies: deferredTargets.cast<AndroidAotDeferredComponentsBundle>(),
        nonDeferredComponentsDependencies: nonDeferredTargets,
        title: 'Deferred components gen_snapshot validation',
      );
    } else if (targets.length > 1) {
      target = CompositeTarget(targets);
    } else if (targets.isNotEmpty) {
      target = targets.single;
    }
    final BuildResult result = await _buildSystem.build(
      target,
      environment,
      buildSystemConfig: BuildSystemConfig(
        resourcePoolSize: argResults.wasParsed('resource-pool-size')
          ? int.tryParse(stringArg('resource-pool-size'))
          : null,
        ),
      );
    if (!result.success) {
      for (final ExceptionMeasurement measurement in result.exceptions.values) {
        if (measurement.fatal || globals.logger.isVerbose) {
          globals.printError('Target ${measurement.target} failed: ${measurement.exception}',
            stackTrace: measurement.stackTrace
          );
        }
      }
      throwToolExit('');
    }
    globals.printTrace('build succeeded.');

    if (argResults.wasParsed('build-inputs')) {
      writeListIfChanged(result.inputFiles, stringArg('build-inputs'));
    }
    if (argResults.wasParsed('build-outputs')) {
      writeListIfChanged(result.outputFiles, stringArg('build-outputs'));
    }
    if (argResults.wasParsed('performance-measurement-file')) {
      final File outFile = globals.fs.file(argResults['performance-measurement-file']);
      writePerformanceData(result.performance.values, outFile);
    }
    if (argResults.wasParsed('depfile')) {
      final File depfileFile = globals.fs.file(stringArg('depfile'));
      final Depfile depfile = Depfile(result.inputFiles, result.outputFiles);
      final DepfileService depfileService = DepfileService(
        fileSystem: globals.fs,
        logger: globals.logger,
      );
      depfileService.writeToFile(depfile, globals.fs.file(depfileFile));
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

/// Output performance measurement data in [outFile].
@visibleForTesting
void writePerformanceData(Iterable<PerformanceMeasurement> measurements, File outFile) {
  final Map<String, Object> jsonData = <String, Object>{
    'targets': <Object>[
      for (final PerformanceMeasurement measurement in measurements)
        <String, Object>{
          'name': measurement.analyticsName,
          'skipped': measurement.skipped,
          'succeeded': measurement.succeeded,
          'elapsedMilliseconds': measurement.elapsedMilliseconds,
        }
    ]
  };
  if (!outFile.parent.existsSync()) {
    outFile.parent.createSync(recursive: true);
  }
  outFile.writeAsStringSync(json.encode(jsonData));
}
