// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/args.dart';
import 'package:meta/meta.dart';
import 'package:unified_analytics/unified_analytics.dart';

import '../artifacts.dart';
import '../base/common.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
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
import '../build_system/targets/windows.dart';
import '../cache.dart';
import '../context/tool_context.dart';
import '../convert.dart';
import '../project.dart';
import '../runner/flutter_command.dart';

/// All currently implemented targets.
var _kDefaultTargets = <Target>[
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
  const DebugUnpackMacOS(),
  const ProfileUnpackMacOS(),
  const ReleaseUnpackMacOS(),
  // Linux targets
  const DebugBundleLinuxAssets(TargetPlatform.linux_x64),
  const DebugBundleLinuxAssets(TargetPlatform.linux_arm64),
  const DebugBundleLinuxAssets(TargetPlatform.linux_riscv64),
  const ProfileBundleLinuxAssets(TargetPlatform.linux_x64),
  const ProfileBundleLinuxAssets(TargetPlatform.linux_arm64),
  const ProfileBundleLinuxAssets(TargetPlatform.linux_riscv64),
  const ReleaseBundleLinuxAssets(TargetPlatform.linux_x64),
  const ReleaseBundleLinuxAssets(TargetPlatform.linux_arm64),
  const ReleaseBundleLinuxAssets(TargetPlatform.linux_riscv64),
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
  const DebugUnpackIOS(),
  const ProfileUnpackIOS(),
  const ReleaseUnpackIOS(),
  // Windows targets
  const UnpackWindows(TargetPlatform.windows_x64),
  const UnpackWindows(TargetPlatform.windows_arm64),
  const DebugBundleWindowsAssets(TargetPlatform.windows_x64),
  const DebugBundleWindowsAssets(TargetPlatform.windows_arm64),
  const ProfileBundleWindowsAssets(TargetPlatform.windows_x64),
  const ProfileBundleWindowsAssets(TargetPlatform.windows_arm64),
  const ReleaseBundleWindowsAssets(TargetPlatform.windows_x64),
  const ReleaseBundleWindowsAssets(TargetPlatform.windows_arm64),
];

/// Assemble provides a low level API to interact with the flutter tool build
/// system.
class AssembleCommand extends FlutterCommand {
  AssembleCommand({
    required BuildSystem buildSystem,
    required ToolContext toolContext,
    super.analytics,
    bool verboseHelp = false,
  }) : _buildSystem = buildSystem,
       _toolContext = toolContext,
       _verboseHelp = verboseHelp,
       super(toolContext: toolContext) {
    requiresPubspecYaml();
    argParser.addMultiOption(
      'define',
      abbr: 'd',
      valueHelp: 'target=key=value',
      hide: !verboseHelp,
      help:
          'DEPRECATED. Use "--dart-define" or "-D" instead for consistency.\n'
          '\n'
          'Allows passing configuration to a target, as in "--define=target=key=value".',
    );

    // New -D/--dart-define (consistent across app)
    usesDartDefineOption();

    argParser.addOption(
      'performance-measurement-file',
      help: 'Output individual target performance to a JSON file.',
    );
    argParser.addMultiOption(
      'input',
      abbr: 'i',
      help:
          'Allows passing additional inputs with "--input=key=value". Unlike '
          'defines, additional inputs do not generate a new configuration; instead '
          'they are treated as dependencies of the targets that use them.',
    );
    argParser.addOption(
      'depfile',
      help:
          'A file path where a depfile will be written. '
          'This contains all build inputs and outputs in a Make-style syntax.',
    );
    argParser.addOption(
      'build-inputs',
      help:
          'A file path where a newline-separated '
          'file containing all inputs used will be written after a build. '
          'This file is not included as a build input or output. This file is not '
          'written if the build fails for any reason.',
    );
    argParser.addOption(
      'build-outputs',
      help:
          'A file path where a newline-separated '
          'file containing all outputs created will be written after a build. '
          'This file is not included as a build input or output. This file is not '
          'written if the build fails for any reason.',
    );
    argParser.addOption(
      'output',
      abbr: 'o',
      help:
          'A directory where output '
          'files will be written. Must be either absolute or relative from the '
          'root of the current Flutter project.',
    );
    usesExtraDartFlagOptions(verboseHelp: verboseHelp);
    argParser.addOption(
      'resource-pool-size',
      help: 'The maximum number of concurrent tasks the build system will run.',
    );
  }

  final bool _verboseHelp;
  final BuildSystem _buildSystem;
  final ToolContext _toolContext;

  Analytics get _effectiveAnalytics => analytics;

  @override
  bool get hidden => !_verboseHelp;

  late final FlutterProject _flutterProject = _toolContext.projectFactory.fromDirectory(
    _toolContext.fs.currentDirectory,
  );

  @override
  String get description => 'Assemble and build Flutter resources.';

  @override
  String get name => 'assemble';

  @override
  String get category => FlutterCommandCategory.project;

  @override
  Future<Event> unifiedAnalyticsUsageValues(String commandPath) async => Event.commandUsageValues(
    workflow: commandPath,
    commandHasTerminal: hasTerminal,
    buildBundleTargetPlatform: _environment.defines[kTargetPlatform],
    buildBundleIsModule: _flutterProject.isModule,
  );

  @override
  Future<Set<DevelopmentArtifact>> get requiredArtifacts async {
    final String? platform = _environment.defines[kTargetPlatform];
    if (platform == null) {
      return super.requiredArtifacts;
    }

    final targetPlatform = TargetPlatform.fromName(platform);
    final DevelopmentArtifact? artifact = artifactFromTargetPlatform(targetPlatform);
    if (artifact != null) {
      return <DevelopmentArtifact>{artifact};
    }
    return super.requiredArtifacts;
  }

  /// The target(s) we are building.
  List<Target> createTargets() {
    final ArgResults argumentResults = argResults!;
    if (argumentResults.rest.isEmpty) {
      throwToolExit('missing target name for flutter assemble.');
    }
    final String name = argumentResults.rest.first;
    final targetMap = <String, Target>{
      for (final Target target in _kDefaultTargets) target.name: target,
    };
    final results = <Target>[
      for (final String targetName in argumentResults.rest)
        if (targetMap.containsKey(targetName)) targetMap[targetName]!,
    ];
    if (results.isEmpty) {
      throwToolExit('No target named "$name" defined.');
    }
    return results;
  }

  bool isDeferredComponentsTargets() {
    for (final String targetName in argResults!.rest) {
      if (deferredComponentsTargets.contains(targetName)) {
        return true;
      }
    }
    return false;
  }

  bool isDebug() {
    for (final String targetName in argResults!.rest) {
      if (targetName.contains('debug')) {
        return true;
      }
    }
    return false;
  }

  late final Environment _environment = _createEnvironment();

  /// The environmental configuration for a build invocation.
  Environment _createEnvironment() {
    final FileSystem fs = _toolContext.fs;
    String? output = stringArg('output');
    if (output == null) {
      throwToolExit('--output directory is required for assemble.');
    }
    // If path is relative, make it absolute from flutter project.
    if (fs.path.isRelative(output)) {
      output = fs.path.join(_flutterProject.directory.path, output);
    }
    final Artifacts artifacts = _toolContext.artifacts;

    List<String> decodedDefines;
    try {
      decodedDefines = decodeDartDefines({
        'dart-define': stringsArg('dart-define').join(','),
      }, 'dart-define');
    } on FormatException {
      throwToolExit(
        'Error parsing assemble command: The -Pdart-defines argument contains non-base64 encoded data. '
        'Check your build command and try again.',
      );
    }

    return Environment(
      outputDir: fs.directory(output),
      buildDir: _flutterProject.directory
          .childDirectory('.dart_tool')
          .childDirectory('flutter_build'),
      projectDir: _flutterProject.directory,
      packageConfigPath: packageConfigPath(),
      defines: _parseDefines([...stringsArg('define'), ...decodedDefines]),
      inputs: _parseDefines(stringsArg('input')),
      cacheDir: _toolContext.cache.getRoot(),
      flutterRootDir: fs.directory(Cache.flutterRoot),
      artifacts: artifacts,
      fileSystem: fs,
      logger: _toolContext.logger,
      processManager: _toolContext.processManager,
      analytics: _effectiveAnalytics,
      platform: _toolContext.platform,
      engineVersion: artifacts.usesLocalArtifacts
          ? null
          : _toolContext.flutterVersion.engineRevision,
      generateDartPluginRegistry: true,
    );
  }

  Map<String, String> _parseDefines(List<String> values) {
    final results = <String, String>{};
    for (final chunk in values) {
      if (chunk.isEmpty) {
        continue;
      }
      final int indexEquals = chunk.indexOf('=');
      if (indexEquals == -1) {
        throwToolExit('Improperly formatted define flag: $chunk');
      }
      final String key = chunk.substring(0, indexEquals);
      final String value = chunk.substring(indexEquals + 1);
      results[key] = value;
    }
    final ArgResults argumentResults = argResults!;
    if (argumentResults.wasParsed(FlutterOptions.kExtraGenSnapshotOptions)) {
      results[kExtraGenSnapshotOptions] =
          (argumentResults[FlutterOptions.kExtraGenSnapshotOptions] as List<String>).join(',');
    }

    final Map<String, Object?> defineConfigJsonMap = extractDartDefineConfigJsonMap();
    final List<String> dartDefines = extractDartDefines(defineConfigJsonMap: defineConfigJsonMap);
    if (dartDefines.isNotEmpty) {
      results[kDartDefines] = dartDefines.join(',');
    }

    results[kDeferredComponents] = 'false';
    if (_flutterProject.manifest.deferredComponents != null &&
        isDeferredComponentsTargets() &&
        !isDebug()) {
      results[kDeferredComponents] = 'true';
    }
    if (argumentResults.wasParsed(FlutterOptions.kExtraFrontEndOptions)) {
      results[kExtraFrontEndOptions] =
          (argumentResults[FlutterOptions.kExtraFrontEndOptions] as List<String>).join(',');
    }
    return results;
  }

  @override
  Future<FlutterCommandResult> runCommand() async {
    final FileSystem fs = _toolContext.fs;
    final Logger logger = _toolContext.logger;
    final List<Target> targets = createTargets();
    final nonDeferredTargets = <Target>[];
    final List<Target> deferredTargets = <AndroidAotDeferredComponentsBundle>[];
    for (final target in targets) {
      if (deferredComponentsTargets.contains(target.name)) {
        deferredTargets.add(target);
      } else {
        nonDeferredTargets.add(target);
      }
    }
    Target? target;
    if (deferredTargets.isNotEmpty) {
      // Record to analytics that DeferredComponents is being used.
      _effectiveAnalytics.send(
        Event.flutterBuildInfo(
          label: 'assemble-deferred-components',
          buildType: 'android',
          settings: deferredTargets.map((Target t) => t.name).join(','),
        ),
      );
    }
    if (_flutterProject.manifest.deferredComponents != null &&
        _environment.defines['validate-deferred-components'] == 'true' &&
        deferredTargets.isNotEmpty &&
        !isDebug()) {
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
    final ArgResults argumentResults = argResults!;
    final BuildResult result = await _buildSystem.build(
      target!,
      _environment,
      buildSystemConfig: BuildSystemConfig(
        resourcePoolSize: argumentResults.wasParsed('resource-pool-size')
            ? int.tryParse(stringArg('resource-pool-size')!)
            : null,
      ),
    );
    if (!result.success) {
      for (final ExceptionMeasurement measurement in result.exceptions.values) {
        if (measurement.fatal || logger.isVerbose) {
          logger.printError(
            'Target ${measurement.target} failed: ${measurement.exception}',
            stackTrace: logger.isVerbose ? measurement.stackTrace : null,
          );
        }
      }
      throwToolExit('');
    }
    logger.printTrace('build succeeded.');

    if (argumentResults.wasParsed('build-inputs')) {
      writeListIfChanged(result.inputFiles, stringArg('build-inputs')!, fs: fs);
    }
    if (argumentResults.wasParsed('build-outputs')) {
      writeListIfChanged(result.outputFiles, stringArg('build-outputs')!, fs: fs);
    }
    if (argumentResults.wasParsed('performance-measurement-file')) {
      final File outFile = fs.file(argumentResults['performance-measurement-file']);
      writePerformanceData(result.performance.values, outFile);
    }
    if (argumentResults.wasParsed('depfile')) {
      final File depfileFile = fs.file(stringArg('depfile'));
      final depfile = Depfile(result.inputFiles, result.outputFiles);
      _environment.depFileService.writeToFile(depfile, depfileFile);
    }
    return FlutterCommandResult.success();
  }
}

@visibleForTesting
void writeListIfChanged(List<File> files, String path, {required FileSystem fs}) {
  final File file = fs.file(path);
  final buffer = StringBuffer();
  // These files are already sorted.
  for (final file in files) {
    buffer.writeln(file.path);
  }
  final newContents = buffer.toString();
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
  final jsonData = <String, Object>{
    'targets': <Object>[
      for (final PerformanceMeasurement measurement in measurements)
        <String, Object>{
          'name': measurement.analyticsName,
          'skipped': measurement.skipped,
          'succeeded': measurement.succeeded,
          'elapsedMilliseconds': measurement.elapsedMilliseconds,
        },
    ],
  };
  if (!outFile.parent.existsSync()) {
    outFile.parent.createSync(recursive: true);
  }
  outFile.writeAsStringSync(json.encode(jsonData));
}
