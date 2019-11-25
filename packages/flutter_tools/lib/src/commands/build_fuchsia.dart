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
import '../fuchsia/fuchsia_pm.dart';
import '../project.dart';
import '../runner/flutter_command.dart' show FlutterCommandResult;
import 'build.dart';

/// A command to build a Fuchsia target.
class BuildFuchsiaCommand extends BuildSubCommand {
  BuildFuchsiaCommand({bool verboseHelp = false}) {
    usesTargetOption();
    addBuildModeFlags(verboseHelp: verboseHelp);
    argParser.addOption(
      'runner-source',
      help: 'The package source to use for the flutter_runner. '
            '"${FuchsiaPackageServer.deviceHost}" implies using a runner already on the device. '
            '"${FuchsiaPackageServer.toolHost}" implies using a runner distributed with Flutter.',
      allowed: <String>[
        FuchsiaPackageServer.deviceHost,
        FuchsiaPackageServer.toolHost,
      ],
      defaultsTo: FuchsiaPackageServer.toolHost,
    );
    argParser.addOption('target-platform',
      defaultsTo: 'fuchsia-x64',
      allowed: <String>['fuchsia-arm64', 'fuchsia-x64'],
      help: 'The target platform for which the app is compiled.',
    );
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
  String get description => 'Build the Fuchsia target (Experimental).';

  @override
  Future<FlutterCommandResult> runCommand() async {
    Cache.releaseLockEarly();
    final BuildInfo buildInfo = getBuildInfo();
    final FlutterProject flutterProject = FlutterProject.current();
    if (!platform.isLinux && !platform.isMacOS) {
      throwToolExit('"build fuchsia" is only supported on Linux and MacOS hosts.');
    }
    if (!flutterProject.fuchsia.existsSync()) {
      throwToolExit('No Fuchsia project is configured.');
    }
    final String appName = flutterProject.fuchsia.project.manifest.appName;
    final String cmxPath = fs.path.join(
        flutterProject.fuchsia.meta.path, '$appName.cmx');
    final File cmxFile = fs.file(cmxPath);
    if (!cmxFile.existsSync()) {
      throwToolExit('The Fuchsia build requires a .cmx file at $cmxPath for the app.');
    }
    await buildFuchsia(
      fuchsiaProject: flutterProject.fuchsia,
      target: targetFile,
      targetPlatform: getTargetPlatformForName(stringArg('target-platform')),
      buildInfo: buildInfo,
      runnerPackageSource: stringArg('runner-source'),
    );
    return null;
  }
}
