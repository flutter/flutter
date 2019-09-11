// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/common.dart';
import '../base/platform.dart';
import '../build_info.dart';
import '../cache.dart';
import '../features.dart';
import '../linux/build_linux.dart';
import '../project.dart';
import '../runner/flutter_command.dart' show FlutterCommandResult;
import 'build.dart';

/// A command to build a linux desktop target through a build shell script.
class BuildLinuxCommand extends BuildSubCommand {
  BuildLinuxCommand() {
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
  final String name = 'linux';

  @override
  bool get hidden => !featureFlags.isLinuxEnabled || !platform.isLinux;

  @override
  Future<Set<DevelopmentArtifact>> get requiredArtifacts async => <DevelopmentArtifact>{
    DevelopmentArtifact.linux,
    DevelopmentArtifact.universal,
  };

  @override
  String get description => 'build the Linux desktop target.';

  @override
  Future<FlutterCommandResult> runCommand() async {
    Cache.releaseLockEarly();
    final BuildInfo buildInfo = getBuildInfo();
    final FlutterProject flutterProject = FlutterProject.current();
    if (!featureFlags.isLinuxEnabled) {
      throwToolExit('"build linux" is not currently supported.');
    }
    if (!platform.isLinux) {
      throwToolExit('"build linux" only supported on Linux hosts.');
    }
    if (!flutterProject.linux.existsSync()) {
      throwToolExit('No Linux desktop project configured.');
    }
    await buildLinux(flutterProject.linux, buildInfo, target: targetFile);
    return null;
  }
}
