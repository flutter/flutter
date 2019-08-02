// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/os.dart';
import '../base/platform.dart';
import '../build_info.dart';
import '../cache.dart';
import '../features.dart';
import '../globals.dart';
import '../macos/application_package.dart';
import '../macos/build_macos.dart';
import '../project.dart';
import '../runner/flutter_command.dart' show FlutterCommandResult;
import 'build.dart';

/// A command to build a macOS desktop target.
class BuildMacosCommand extends BuildSubCommand {
  BuildMacosCommand({bool verboseHelp}) {
    usesTargetOption();
    addBuildModeFlags(verboseHelp: verboseHelp);
    argParser.addOption('output',
      abbr: 'o',
      help: 'A path where the built artifact can be copied to.',
      valueHelp: 'build/myapp',
      defaultsTo: fs.path.join('build', 'macos'));
  }

  @override
  final String name = 'macos';

  @override
  bool hidden = true;

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
    final PrebuiltMacOSApp application = await macOSBuilder.buildMacOS(
      flutterProject: flutterProject,
      buildInfo: buildInfo,
      targetOverride: targetFile,
    );
    // Copy the final .app from the build cache and set the executable with +x.
    final String appDirectory = fs.path.basename(application.bundleDir.path);
    final Directory outputDirectory = fs.directory(argResults['output']).childDirectory(appDirectory);
    outputDirectory.createSync(recursive: true);
    copyDirectorySync(application.bundleDir, outputDirectory);
    os.chmod(fs.file(application.executable), 'x');
    printStatus('Built to ${outputDirectory.path}');
    return null;
  }
}
