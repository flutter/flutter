// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

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
  BuildWindowsCommand({ bool verboseHelp = false }) {
    addCommonDesktopBuildOptions(verboseHelp: verboseHelp);
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
  VisualStudio visualStudioOverride;

  @override
  Future<FlutterCommandResult> runCommand() async {
    final FlutterProject flutterProject = FlutterProject.current();
    final BuildInfo buildInfo = getBuildInfo();
    if (!featureFlags.isWindowsEnabled) {
      throwToolExit('"build windows" is not currently supported.');
    }
    if (!globals.platform.isWindows) {
      throwToolExit('"build windows" only supported on Windows hosts.');
    }
    await buildWindows(
      flutterProject.windows,
      buildInfo,
      target: targetFile,
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
