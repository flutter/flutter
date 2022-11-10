// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/analyze_size.dart';
import '../base/common.dart';
import '../base/file_system.dart';
import '../base/platform.dart';
import '../build_info.dart';
import '../cache.dart';
import '../features.dart';
import '../macos/build_macos.dart';
import '../project.dart';
import '../reporting/reporting.dart';
import '../runner/flutter_command.dart' show FlutterCommandResult;
import 'build.dart';

/// A command to build a macOS desktop target through a build shell script.
class BuildMacosCommand extends BuildSubCommand {
  BuildMacosCommand({
    required super.logger,
    required this.fileSystem,
    required this.platform,
    required this.flutterUsage,
    required bool verboseHelp,
  }) : super(verboseHelp: verboseHelp) {
    addCommonDesktopBuildOptions(verboseHelp: verboseHelp);
  }

  final FileSystem fileSystem;
  final Platform platform;
  final Usage flutterUsage;

  @override
  final String name = 'macos';

  @override
  bool get hidden => !featureFlags.isMacOSEnabled || !platform.isMacOS;

  @override
  Future<Set<DevelopmentArtifact>> get requiredArtifacts async => <DevelopmentArtifact>{
    DevelopmentArtifact.macOS,
  };

  @override
  String get description => 'Build a macOS desktop application.';

  @override
  bool get supported => platform.isMacOS;

  @override
  Future<FlutterCommandResult> runCommand() async {
    final BuildInfo buildInfo = await getBuildInfo();
    final FlutterProject flutterProject = FlutterProject.current();
    if (!featureFlags.isMacOSEnabled) {
      throwToolExit('"build macos" is not currently supported. To enable, run "flutter config --enable-macos-desktop".');
    }
    if (!supported) {
      throwToolExit('"build macos" only supported on macOS hosts.');
    }
    displayNullSafetyMode(buildInfo);
    await buildMacOS(
      flutterProject: flutterProject,
      buildInfo: buildInfo,
      targetOverride: targetFile,
      fileSystem: fileSystem,
      flutterUsage: flutterUsage,
      platform: platform,
      logger: logger,
      verboseLogging: logger.isVerbose,
      sizeAnalyzer: SizeAnalyzer(
        fileSystem: fileSystem,
        logger: logger,
        appFilenamePattern: 'App',
        flutterUsage: flutterUsage,
      ),
    );
    return FlutterCommandResult.success();
  }
}
