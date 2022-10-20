// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../base/analyze_size.dart';
import '../base/common.dart';
import '../build_info.dart';
import '../cache.dart';
import '../features.dart';
import '../globals.dart' as globals;
import '../project.dart';
import '../runner/flutter_command.dart' show FlutterCommandResult;
import '../windows/build_windows.dart';
import '../windows/visual_studio.dart';
import 'build.dart';

/// A command to build a windows desktop target through a build shell script.
class BuildWindowsCommand extends BuildSubCommand {
  BuildWindowsCommand({
    required super.logger,
    bool verboseHelp = false,
  }) : super(verboseHelp: verboseHelp) {
    addCommonDesktopBuildOptions(verboseHelp: verboseHelp);
    // As long as arm64 does not have artifacts available, stick to x64.
    // OperatingSystemUtils can be used to identify host architecture.
    // TODO(stuartmorgan): https://github.com/flutter/flutter/issues/62597
    const String defaultTargetPlatform = 'windows-x64';
    argParser.addOption('target-platform',
      defaultsTo: defaultTargetPlatform,
      allowed: <String>['windows-arm64', 'windows-x64'],
      help: 'The target platform for which the app is compiled.',
    );
  }

  @override
  final String name = 'windows';

  @override
  bool get hidden => !featureFlags.isWindowsEnabled || !globals.platform.isWindows;

  @override
  Future<Set<DevelopmentArtifact>> get requiredArtifacts async => <DevelopmentArtifact>{
    DevelopmentArtifact.windows,
  };

  @override
  String get description => 'Build a Windows desktop application.';

  @visibleForTesting
  VisualStudio? visualStudioOverride;

  @override
  Future<FlutterCommandResult> runCommand() async {
    final FlutterProject flutterProject = FlutterProject.current();
    final BuildInfo buildInfo = await getBuildInfo();
    final TargetPlatform targetPlatform =
        getTargetPlatformForName(stringArg('target-platform')!);
    if (!featureFlags.isWindowsEnabled) {
      throwToolExit('"build windows" is not currently supported. To enable, run "flutter config --enable-windows-desktop".');
    }
    if (!globals.platform.isWindows) {
      throwToolExit('"build windows" only supported on Windows hosts.');
    }
    displayNullSafetyMode(buildInfo);
    await buildWindows(
      flutterProject.windows,
      buildInfo,
      target: targetFile,
      targetPlatform: targetPlatform,
      visualStudioOverride: visualStudioOverride,
      sizeAnalyzer: SizeAnalyzer(
        fileSystem: globals.fs,
        logger: globals.logger,
        appFilenamePattern: 'app.so',
        flutterUsage: globals.flutterUsage,
      ),
    );
    return FlutterCommandResult.success();
  }
}
