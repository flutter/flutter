// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:meta/meta.dart';

import '../base/common.dart';
import '../build_info.dart';
import '../cache.dart';
import '../features.dart';
import '../globals_null_migrated.dart' as globals;
import '../project.dart';
import '../runner/flutter_command.dart' show FlutterCommandResult;
import '../windows/build_windows.dart';
import '../windows/visual_studio.dart';
import 'build.dart';

/// A command to build a Windows UWP desktop target.
class BuildWindowsUwpCommand extends BuildSubCommand {
  BuildWindowsUwpCommand({ bool verboseHelp = false }) {
    addCommonDesktopBuildOptions(verboseHelp: verboseHelp);
  }

  @override
  final String name = 'winuwp';

  @override
  bool get hidden => !featureFlags.isWindowsUwpEnabled || !globals.platform.isWindows;

  @override
  Future<Set<DevelopmentArtifact>> get requiredArtifacts async => <DevelopmentArtifact>{
    // TODO(flutter): add a windows_uwp artifact here once that is updated.
    // https://github.com/flutter/flutter/issues/78627
  };

  @override
  String get description => 'Build a Windows UWP desktop application.';

  @visibleForTesting
  VisualStudio visualStudioOverride;

  @override
  Future<FlutterCommandResult> runCommand() async {
    final FlutterProject flutterProject = FlutterProject.current();
    final BuildInfo buildInfo = await getBuildInfo();
    if (!featureFlags.isWindowsUwpEnabled) {
      throwToolExit('"build windows" is not currently supported.');
    }
    if (!globals.platform.isWindows) {
      throwToolExit('"build windows" only supported on Windows hosts.');
    }
    displayNullSafetyMode(buildInfo);
    await buildWindowsUwp(
      flutterProject.windowsUwp,
      buildInfo,
      target: targetFile,
      visualStudioOverride: visualStudioOverride,
    );
    return FlutterCommandResult.success();
  }
}
