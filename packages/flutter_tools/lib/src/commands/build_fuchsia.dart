// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/platform.dart';
import '../build_info.dart';
import '../cache.dart';
import '../fuchsia/fuchsia_build.dart';
import '../project.dart';
import '../runner/flutter_command.dart' show FlutterCommandResult;
import 'build.dart';

/// A command to build a Fuchsia target.
class BuildFuchsiaCommand extends BuildSubCommand {
  BuildFuchsiaCommand({bool verboseHelp = false}) {
    usesTargetOption();
    addBuildModeFlags(verboseHelp: verboseHelp);
  }

  @override
  final String name = 'fuchsia';

  @override
  bool hidden = true;

  @override
  Future<Set<DevelopmentArtifact>> get requiredArtifacts async => <DevelopmentArtifact>{
    DevelopmentArtifact.fuchsia,
    DevelopmentArtifact.universal,
  };

  @override
  String get description => 'build the Fuchsia target (Experimental).';

  @override
  Future<FlutterCommandResult> runCommand() async {
    Cache.releaseLockEarly();
    final BuildInfo buildInfo = getBuildInfo();
    final FlutterProject flutterProject = FlutterProject.current();
    if (!platform.isLinux && !platform.isMacOS) {
      throwToolExit('"build Fuchsia" only supported on Linux and MacOS hosts.');
    }
    if (!flutterProject.fuchsia.existsSync()) {
      throwToolExit('No Fuchsia project configured.');
    }
    final String appName = flutterProject.fuchsia.project.manifest.appName;
    final String cmxPath = fs.path.join(
        flutterProject.fuchsia.meta.path, '$appName.cmx');
    final File cmxFile = fs.file(cmxPath);
    if (!cmxFile.existsSync()) {
      throwToolExit('Fuchsia build requires a .cmx file at $cmxPath for the app');
    }
    await buildFuchsia(
        fuchsiaProject: flutterProject.fuchsia,
        target: targetFile,
        buildInfo: buildInfo);
    return null;
  }
}
