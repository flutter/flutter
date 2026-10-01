// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../base/analyze_size.dart';
import '../base/bot_detector.dart';
import '../base/common.dart';
import '../base/config.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/os.dart';
import '../base/platform.dart';
import '../base/process.dart';
import '../base/terminal.dart';
import '../base/user_messages.dart';
import '../build_info.dart';
import '../build_system/build_system.dart';
import '../context/tool_context.dart';
import '../features.dart';
import '../macos/build_macos.dart';
import '../runner/flutter_command.dart';
import '../runner/flutter_command_runner.dart' show FlutterGlobalOptions;
import '../version.dart';
import 'build.dart';

/// A command to build a macOS desktop target through a build shell script.
class BuildMacosCommand extends BuildSubCommand {
  BuildMacosCommand({
    required this.buildSystem,
    required this.featureFlags,
    required ToolContext super.toolContext,
    required super.verboseHelp,
  }) : super(logger: toolContext.logger, outputPreferences: toolContext.outputPreferences) {
    registerOptionBundles(const <OptionBundle>[
      CommonBuildOptionsBundle(),
      BuildModeOptionsBundle(),
      DartCompileOptionsBundle(),
      AppleBuildOptionsBundle(),
    ]);
    argParser.addDescriptors(const <OptionDescriptor<Object?>>[
      BuildInfoOptions.trackWidgetCreation,
      AppleBuildOptionsBundle.configOnly,
    ], verboseHelp: verboseHelp);
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

  bool get configOnly => getValue(AppleBuildOptionsBundle.configOnly);

  @override
  Future<FlutterCommandResult> runCommand() async {
    final ToolContext(
      :BotDetector botDetector,
      :Config config,
      :FileSystemUtils fileSystemUtils,
      :FlutterVersion flutterVersion,
      :FileSystem fs,
      :Logger logger,
      :OperatingSystemUtils os,
      :Platform platform,
      :ProcessUtils processUtils,
      :AnsiTerminal terminal,
      :UserMessages userMessages,
    ) = toolContext;
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
      analytics: analytics,
      botDetector: botDetector,
      buildInfo: buildInfo,
      config: config,
      configOnly: configOnly,
      featureFlags: featureFlags,
      fileSystem: fs,
      fileSystemUtils: fileSystemUtils,
      flutterProject: project,
      flutterVersion: flutterVersion,
      logger: logger,
      operatingSystemUtils: os,
      platform: platform,
      processUtils: processUtils,
      sizeAnalyzer: SizeAnalyzer(
        fileSystem: fs,
        logger: logger,
        appFilenamePattern: 'App',
        analytics: analytics,
      ),
      targetOverride: targetFile,
      terminal: terminal,
      userMessages: userMessages,
      usingCISystem: usingCISystem,
      verboseLogging: logger.isVerbose || globalResults?[FlutterGlobalOptions.kVerboseFlag] == true,
    );
    return FlutterCommandResult.success();
  }
}
