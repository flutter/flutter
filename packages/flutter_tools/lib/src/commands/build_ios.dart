// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/file.dart';
import 'package:meta/meta.dart';

import '../application_package.dart';
import '../base/analyze_size.dart';
import '../base/common.dart';
import '../base/utils.dart';
import '../build_info.dart';
import '../convert.dart';
import '../globals.dart' as globals;
import '../ios/mac.dart';
import '../runner/flutter_command.dart' show DevelopmentArtifact, FlutterCommandResult;
import 'build.dart';

/// Builds an .app for an iOS app to be used for local testing on an iOS device
/// or simulator. Can only be run on a macOS host. For producing deployment
/// .ipas, see https://flutter.dev/docs/deployment/ios.
class BuildIOSCommand extends BuildSubCommand {
  BuildIOSCommand({ @required bool verboseHelp }) {
    addTreeShakeIconsFlag();
    addSplitDebugInfoOption();
    addBuildModeFlags(defaultToRelease: true);
    usesTargetOption();
    usesFlavorOption();
    usesPubOption();
    usesBuildNumberOption();
    usesBuildNameOption();
    addDartObfuscationOption();
    usesDartDefineOption();
    usesExtraFrontendOptions();
    addEnableExperimentation(hide: !verboseHelp);
    addBuildPerformanceFile(hide: !verboseHelp);
    addBundleSkSLPathOption(hide: !verboseHelp);
    addNullSafetyModeOptions(hide: !verboseHelp);
    usesAnalyzeSizeFlag();
    argParser
      ..addFlag('config-only',
        help: 'Update the project configuration without performing a build. '
          'This can be used in CI/CD process that create an archive to avoid '
          'performing duplicate work.'
      )
      ..addFlag('simulator',
        help: 'Build for the iOS simulator instead of the device. This changes '
          'the default build mode to debug if otherwise unspecified.',
      )
      ..addFlag('codesign',
        defaultsTo: true,
        help: 'Codesign the application bundle (only available on device builds).',
      );
  }

  @override
  final String name = 'ios';

  @override
  final String description = 'Build an iOS application bundle (Mac OS X host only).';

  @override
  Future<Set<DevelopmentArtifact>> get requiredArtifacts async => const <DevelopmentArtifact>{
    DevelopmentArtifact.iOS,
  };

  @override
  Future<FlutterCommandResult> runCommand() async {
    final bool forSimulator = boolArg('simulator');
    final bool configOnly = boolArg('config-only');
    final bool shouldCodesign = boolArg('codesign');
    defaultBuildMode = forSimulator ? BuildMode.debug : BuildMode.release;
    final BuildInfo buildInfo = getBuildInfo();

    if (!globals.platform.isMacOS) {
      throwToolExit('Building for iOS is only supported on macOS.');
    }
    if (forSimulator && !buildInfo.supportsSimulator) {
      throwToolExit('${toTitleCase(buildInfo.friendlyModeName)} mode is not supported for simulators.');
    }
    if (configOnly && buildInfo.codeSizeDirectory != null) {
      throwToolExit('Cannot analyze code size without performing a full build.');
    }
    if (!forSimulator && !shouldCodesign) {
      globals.printStatus(
        'Warning: Building for device with codesigning disabled. You will '
        'have to manually codesign before deploying to device.',
      );
    }

    final BuildableIOSApp app = await applicationPackages.getPackageForPlatform(
      TargetPlatform.ios,
      buildInfo,
    ) as BuildableIOSApp;

    if (app == null) {
      throwToolExit('Application not configured for iOS');
    }

    final String logTarget = forSimulator ? 'simulator' : 'device';
    final String typeName = globals.artifacts.getEngineType(TargetPlatform.ios, buildInfo.mode);
    globals.printStatus('Building $app for $logTarget ($typeName)...');
    final XcodeBuildResult result = await buildXcodeProject(
      app: app,
      buildInfo: buildInfo,
      targetOverride: targetFile,
      buildForDevice: !forSimulator,
      codesign: shouldCodesign,
      configOnly: configOnly,
    );

    if (!result.success) {
      await diagnoseXcodeBuildFailure(result, globals.flutterUsage, globals.logger);
      throwToolExit('Encountered error while building for $logTarget.');
    }

    if (buildInfo.codeSizeDirectory != null) {
      final SizeAnalyzer sizeAnalyzer = SizeAnalyzer(
        fileSystem: globals.fs,
        logger: globals.logger,
        flutterUsage: globals.flutterUsage,
        appFilenamePattern: 'App'
      );
      // Only support 64bit iOS code size analysis.
      final String arch = getNameForDarwinArch(DarwinArch.arm64);
      final File aotSnapshot = globals.fs.directory(buildInfo.codeSizeDirectory)
        .childFile('snapshot.$arch.json');
      final File precompilerTrace = globals.fs.directory(buildInfo.codeSizeDirectory)
        .childFile('trace.$arch.json');

      // This analysis is only supported for release builds, which also excludes the simulator.
      // Attempt to guess the correct .app by picking the first one.
      final Directory candidateDirectory = globals.fs.directory(
        globals.fs.path.join(getIosBuildDirectory(), 'Release-iphoneos'),
      );
      final Directory appDirectory = candidateDirectory.listSync()
        .whereType<Directory>()
        .firstWhere((Directory directory) {
        return globals.fs.path.extension(directory.path) == '.app';
      });
      final Map<String, Object> output = await sizeAnalyzer.analyzeAotSnapshot(
        aotSnapshot: aotSnapshot,
        precompilerTrace: precompilerTrace,
        outputDirectory: appDirectory,
        type: 'ios',
      );
      final File outputFile = globals.fsUtils.getUniqueFile(
        globals.fs.directory(getBuildDirectory()),'ios-code-size-analysis', 'json',
      )..writeAsStringSync(jsonEncode(output));
      // This message is used as a sentinel in analyze_apk_size_test.dart
      globals.printStatus(
        'A summary of your iOS bundle analysis can be found at: ${outputFile.path}',
      );
    }

    if (result.output != null) {
      globals.printStatus('Built ${result.output}.');
    }

    return FlutterCommandResult.success();
  }
}
