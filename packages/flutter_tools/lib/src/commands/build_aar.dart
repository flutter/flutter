// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:unified_analytics/unified_analytics.dart';

import '../android/android_builder.dart';
import '../android/android_sdk.dart';
import '../android/gradle_utils.dart';
import '../base/common.dart';
import '../base/file_system.dart';
import '../base/os.dart';
import '../build_info.dart';
import '../globals.dart' as globals;
import '../project.dart';
import '../runner/flutter_command.dart';
import 'build.dart';

class BuildAarCommand extends BuildSubCommand {
  BuildAarCommand({
    required super.logger,
    required AndroidSdk? androidSdk,
    required FileSystem fileSystem,
    required super.verboseHelp,
  }) : _androidSdk = androidSdk,
       _fileSystem = fileSystem {
    enableUsesPubOption();
    registerOptionBundles(const <OptionBundle>[
      DartCompileOptionsBundle(),
      AndroidGradleOptionsBundle(),
    ]);
    argParser.addDescriptors(const <OptionDescriptor<Object?>>[
      _debugMode,
      _profileMode,
      _releaseMode,
      CommonOptions.treeShakeIcons,
      BuildInfoOptions.flavor,
      CommonOptions.buildNumber,
      CommonOptions.outputDir,
      CommonOptions.pub,
      BuildInfoOptions.splitDebugInfo,
      BuildInfoOptions.obfuscate,
      BuildInfoOptions.extraFrontEndOptions,
      BuildInfoOptions.extraGenSnapshotOptions,
      _targetPlatform,
      BuildInfoOptions.trackWidgetCreation,
    ], verboseHelp: verboseHelp);
  }

  static const _debugMode = FlagOptionDescriptor(
    name: 'debug',
    defaultsTo: true,
    help: 'Build a debug version of the current project.',
  );

  static const _profileMode = FlagOptionDescriptor(
    name: 'profile',
    defaultsTo: true,
    help: 'Build a version of the current project specialized for performance profiling.',
  );

  static const _releaseMode = FlagOptionDescriptor(
    name: 'release',
    defaultsTo: true,
    help: 'Build a release version of the current project.',
  );

  static const _targetPlatform = MultiOptionDescriptor(
    name: 'target-platform',
    defaultsTo: <String>['android-arm', 'android-arm64', 'android-x64'],
    allowed: <String>['android-arm', 'android-arm64', 'android-x64'],
    help: 'The target platform for which the project is compiled.',
  );
  final AndroidSdk? _androidSdk;
  final FileSystem _fileSystem;

  @override
  final name = 'aar';

  @override
  Future<Set<DevelopmentArtifact>> get requiredArtifacts async => <DevelopmentArtifact>{
    DevelopmentArtifact.androidGenSnapshot,
  };

  @override
  late final FlutterProject project = _getProject();

  @override
  Future<Event> unifiedAnalyticsUsageValues(String commandPath) async {
    final String projectType;
    if (project.manifest.isModule) {
      projectType = 'module';
    } else if (project.manifest.isPlugin) {
      projectType = 'plugin';
    } else {
      projectType = 'app';
    }

    return Event.commandUsageValues(
      workflow: commandPath,
      commandHasTerminal: hasTerminal,
      buildAarProjectType: projectType,
      buildAarTargetPlatform: getValue(_targetPlatform).join(','),
      // TODO(gmackall): Consider collecting hcpp analytics, see https://github.com/flutter/flutter/issues/184541.
    );
  }

  @override
  final description =
      'Build a repository containing an AAR and a POM file.\n\n'
      'By default, AARs are built for `release`, `debug` and `profile`.\n'
      'The POM file is used to include the dependencies that the AAR was compiled against.\n'
      'To learn more about how to use these artifacts, see: https://flutter.dev/to/integrate-android-archive\n'
      'This command assumes that the entrypoint is "lib/main.dart". '
      'This cannot currently be configured.';

  @override
  Future<void> validateCommand() async {
    if (!project.manifest.isModule) {
      throwToolExit('AARs can only be built from modules.');
    }
    await super.validateCommand();
  }

  @override
  bool get regeneratePlatformSpecificToolingDuringVerify => false;

  @override
  Future<FlutterCommandResult> runCommand() async {
    if (_androidSdk == null) {
      exitWithNoSdkMessage();
    }
    final androidBuildInfo = <AndroidBuildInfo>{};

    final Iterable<CpuArch> targetArchitectures = getValue(
      _targetPlatform,
    ).map<CpuArch>(getCpuArchForName);

    final String? buildNumberArg = getValue(CommonOptions.buildNumber);
    final String buildNumber = (buildNumberArg != null && buildNumberArg.isNotEmpty)
        ? buildNumberArg
        : '1.0';

    final File targetFile = _fileSystem.file(_fileSystem.path.join('lib', 'main.dart'));
    for (final FlagOptionDescriptor descriptor in const [_debugMode, _profileMode, _releaseMode]) {
      if (getValue(descriptor)) {
        androidBuildInfo.add(
          AndroidBuildInfo(
            await getBuildInfo(
              forcedBuildMode: BuildMode.fromCliName(descriptor.name),
              forcedTargetFile: targetFile,
            ),
            targetArchs: targetArchitectures,
          ),
        );
      }
    }
    if (androidBuildInfo.isEmpty) {
      throwToolExit('Please specify a build mode and try again.');
    }

    await androidBuilder?.buildAar(
      project: project,
      target: targetFile.path,
      androidBuildInfo: androidBuildInfo,
      generateTooling: regeneratePlatformSpecificToolingIfApplicable,
      outputDirectoryPath: getValue(CommonOptions.outputDir),
      buildNumber: buildNumber,
    );

    final bool impellerEnabled = project.android.computeImpellerEnabled();
    final buildLabel = impellerEnabled
        ? 'manifest-aar-impeller-enabled'
        : 'manifest-aar-impeller-disabled';
    globals.analytics.send(Event.flutterBuildInfo(label: buildLabel, buildType: 'android'));

    return FlutterCommandResult.success();
  }

  /// Returns the [FlutterProject] which is determined from the remaining command-line
  /// argument if any or the current working directory.
  FlutterProject _getProject() {
    final List<String> remainingArguments = argResults!.rest;
    if (remainingArguments.isEmpty) {
      return super.project;
    }
    final File mainFile = _fileSystem.file(remainingArguments.first);
    final String path;
    if (!mainFile.existsSync()) {
      final Directory pathProject = _fileSystem.directory(remainingArguments.first);
      if (!pathProject.existsSync()) {
        throwToolExit('${remainingArguments.first} does not exist');
      }
      path = pathProject.path;
    } else {
      path = mainFile.parent.path;
    }
    final String? projectRoot = findProjectRoot(_fileSystem, path);
    if (projectRoot == null) {
      throwToolExit('${mainFile.parent.path} is not a valid flutter project');
    }
    return FlutterProject.fromDirectory(_fileSystem.directory(projectRoot));
  }
}
