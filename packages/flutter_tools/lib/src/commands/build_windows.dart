// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/common.dart';
import '../base/platform.dart';
import '../build_info.dart';
import '../cache.dart';
import '../features.dart';
import '../project.dart';
import '../runner/flutter_command.dart' show FlutterCommandResult;
import '../windows/build_windows.dart';
import 'build.dart';

/// A command to build a windows desktop target through a build shell script.
class BuildWindowsCommand extends BuildSubCommand {
  BuildWindowsCommand() {
    usesTargetOption();
    argParser.addFlag('debug',
      negatable: false,
      help: 'Build a debug version of your app.',
    );
    argParser.addFlag('profile',
      negatable: false,
      help: 'Build a version of your app specialized for performance profiling.'
    );
    argParser.addFlag('release',
      negatable: false,
      help: 'Build a version of your app specialized for performance profiling.',
    );
  }

  @override
  final String name = 'windows';

  @override
  bool get hidden => !featureFlags.isWindowsEnabled || !platform.isWindows;

  @override
  Future<Set<DevelopmentArtifact>> get requiredArtifacts async => <DevelopmentArtifact>{
    DevelopmentArtifact.windows,
    DevelopmentArtifact.universal,
  };

  @override
  String get description => 'build the desktop Windows target.';

  @override
  Future<FlutterCommandResult> runCommand() async {
    Cache.releaseLockEarly();
    final FlutterProject flutterProject = FlutterProject.current();
    final BuildInfo buildInfo = getBuildInfo();
    if (!featureFlags.isWindowsEnabled) {
      throwToolExit('"build windows" is not currently supported.');
    }
    if (!platform.isWindows) {
      throwToolExit('"build windows" only supported on Windows hosts.');
    }
    if (!flutterProject.windows.existsSync()) {
      throwToolExit('No Windows desktop project configured.');
    }
    await buildWindows(flutterProject.windows, buildInfo, target: targetFile);
    return null;
  }
}
