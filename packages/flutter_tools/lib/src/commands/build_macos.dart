// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../base/analyze_size.dart';
import '../base/common.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../build_info.dart';
import '../build_system/build_system.dart';
import '../cache.dart';
import '../context/tool_context.dart';
import '../features.dart';
import '../macos/build_macos.dart';
import '../runner/flutter_command.dart' show FlutterCommandResult;
import '../runner/flutter_command_runner.dart' show FlutterGlobalOptions;
import 'build.dart';

/// A command to build a macOS desktop target through a build shell script.
class BuildMacosCommand extends BuildSubCommand {
  BuildMacosCommand({
    required this.buildSystem,
    required this.featureFlags,
    required ToolContext toolContext,
    required bool verboseHelp,
  }) : super(
         logger: toolContext.logger,
         outputPreferences: toolContext.outputPreferences,
         toolContext: toolContext,
         verboseHelp: verboseHelp,
       ) {
    addCommonDesktopBuildOptions(verboseHelp: verboseHelp);
    usesFlavorOption();
    argParser.addFlag(
      'config-only',
      help:
          'Update the project configuration without performing a build. '
          'This can be used in CI/CD process that create an archive to avoid '
          'performing duplicate work.',
    );
  }

  /// The build system used to execute targets.
  final BuildSystem buildSystem;

  /// Feature flags governing macOS desktop builds.
  @visibleForTesting
  final FeatureFlags featureFlags;

  @override
  ToolContext get toolContext => super.toolContext!;

  @override
  final name = 'macos';

  @override
  bool get hidden => !featureFlags.isMacOSEnabled || !toolContext.platform.isMacOS;

  @override
  Future<Set<DevelopmentArtifact>> get requiredArtifacts async => <DevelopmentArtifact>{
    DevelopmentArtifact.macOS,
  };

  @override
  String get description => 'Build a macOS desktop application.';

  @override
  bool get supported => toolContext.platform.isMacOS;

  bool get configOnly => boolArg('config-only');

  @override
  Future<FlutterCommandResult> runCommand() async {
    final FileSystem fs = toolContext.fs;
    final Logger logger = toolContext.logger;

    final BuildInfo buildInfo = await getBuildInfo();
    if (!featureFlags.isMacOSEnabled) {
      throwToolExit(
        '"build macos" is not currently supported. To enable, run "flutter config --enable-macos-desktop".',
      );
    }
    if (!supported) {
      throwToolExit('"build macos" only supported on macOS hosts.');
    }

    await buildMacOS(
      flutterProject: project,
      buildInfo: buildInfo,
      targetOverride: targetFile,
      verboseLogging: logger.isVerbose || globalResults?[FlutterGlobalOptions.kVerboseFlag] == true,
      configOnly: configOnly,
      sizeAnalyzer: SizeAnalyzer(
        fileSystem: fs,
        logger: logger,
        appFilenamePattern: 'App',
        analytics: analytics,
      ),
      usingCISystem: usingCISystem,
    );
    return FlutterCommandResult.success();
  }
}
