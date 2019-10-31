// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/common.dart';
import '../base/platform.dart';
import '../build_info.dart';
import '../cache.dart';
import '../features.dart';
import '../macos/build_macos.dart';
import '../project.dart';
import '../runner/flutter_command.dart' show FlutterCommandResult;
import 'build.dart';

/// A command to build a macOS desktop target through a build shell script.
class BuildMacosCommand extends BuildSubCommand {
  BuildMacosCommand({bool verboseHelp}) {
    usesTargetOption();
    addBuildModeFlags(verboseHelp: verboseHelp);
  }

  @override
  final String name = 'macos';

  @override
  bool get hidden => !featureFlags.isMacOSEnabled || !platform.isMacOS;

  @override
  Future<Set<DevelopmentArtifact>> get requiredArtifacts async => <DevelopmentArtifact>{
    DevelopmentArtifact.macOS,
    DevelopmentArtifact.universal,
  };

  @override
  String get description => 'build the macOS desktop target.';

  @override
  Future<FlutterCommandResult> runCommand() async {
    Cache.releaseLockEarly();
    final BuildInfo buildInfo = getBuildInfo();
    final FlutterProject flutterProject = FlutterProject.current();
    if (!featureFlags.isMacOSEnabled) {
      throwToolExit('"build macos" is not currently supported.');
    }
    if (!platform.isMacOS) {
      throwToolExit('"build macos" only supported on macOS hosts.');
    }
    if (!flutterProject.macos.existsSync()) {
      throwToolExit('No macOS desktop project configured.');
    }
    await buildMacOS(
      flutterProject: flutterProject,
      buildInfo: buildInfo,
      targetOverride: targetFile,
    );
    return null;
  }
}
