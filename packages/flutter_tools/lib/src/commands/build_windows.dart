// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../base/analyze_size.dart';
import '../base/common.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/os.dart';
import '../base/platform.dart';
import '../build_info.dart';
import '../build_system/build_system.dart';
import '../cache.dart';
import '../context/tool_context.dart';
import '../features.dart';
import '../runner/flutter_command.dart' show FlutterCommandResult;
import '../windows/build_windows.dart';
import '../windows/visual_studio.dart';
import 'build.dart';

/// A command to build a windows desktop target through a build shell script.
class BuildWindowsCommand extends BuildSubCommand {
  BuildWindowsCommand({
    required this.buildSystem,
    required ToolContext toolContext,
    required bool verboseHelp,
    required FeatureFlags featureFlags,
    required VisualStudio visualStudio,
  }) : _featureFlags = featureFlags,
       _visualStudio = visualStudio,
       super(
         logger: toolContext.logger,
         outputPreferences: toolContext.outputPreferences,
         toolContext: toolContext,
         verboseHelp: verboseHelp,
       ) {
    addCommonDesktopBuildOptions(verboseHelp: verboseHelp);
    usesFlavorOption();
    argParser.addFlag(
      'config-only',
      help: 'Update the project configuration without performing a build.',
    );
  }

  final BuildSystem buildSystem;
  final FeatureFlags _featureFlags;

  @visibleForTesting
  FeatureFlags get featureFlags => _featureFlags;

  @override
  ToolContext get toolContext => super.toolContext!;

  @override
  final name = 'windows';

  @override
  bool get hidden => !_featureFlags.isWindowsEnabled || !toolContext.platform.isWindows;

  @override
  Future<Set<DevelopmentArtifact>> get requiredArtifacts async => <DevelopmentArtifact>{
    DevelopmentArtifact.windows,
  };

  @override
  String get description => 'Build a Windows desktop application.';

  final VisualStudio _visualStudio;

  bool get configOnly => boolArg('config-only');

  @override
  Future<FlutterCommandResult> runCommand() async {
    final FileSystem fs = toolContext.fs;
    final Logger logger = this.logger;
    final OperatingSystemUtils os = toolContext.os;
    final Platform platform = toolContext.platform;

    final BuildInfo buildInfo = await getBuildInfo();
    if (!_featureFlags.isWindowsEnabled) {
      throwToolExit(
        '"build windows" is not currently supported. To enable, run "flutter config --enable-windows-desktop".',
      );
    }
    if (!platform.isWindows) {
      throwToolExit('"build windows" only supported on Windows hosts.');
    }

    final defaultTargetPlatform = (os.hostPlatform == HostPlatform.windows_arm64)
        ? 'windows-arm64'
        : 'windows-x64';
    final targetPlatform = TargetPlatform.fromName(defaultTargetPlatform);

    await buildWindows(
      project.windows,
      buildInfo,
      targetPlatform,
      target: targetFile,
      visualStudioOverride: _visualStudio,
      sizeAnalyzer: SizeAnalyzer(
        fileSystem: fs,
        logger: logger,
        appFilenamePattern: 'app.so',
        analytics: analytics,
      ),
      configOnly: configOnly,
    );
    return FlutterCommandResult.success();
  }
}
