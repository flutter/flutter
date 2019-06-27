// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../android/aar.dart';
import '../build_info.dart';
import '../project.dart';
import '../runner/flutter_command.dart' show DevelopmentArtifact, FlutterCommandResult;
import 'build.dart';

class BuildAarCommand extends BuildSubCommand {
  BuildAarCommand({bool verboseHelp = false}) {
    addBuildModeFlags(verboseHelp: verboseHelp);
    usesFlavorOption();
    usesPubOption();
    argParser
      ..addMultiOption('target-platform',
        splitCommas: true,
        defaultsTo: <String>['android-arm', 'android-arm64'],
        allowed: <String>['android-arm', 'android-arm64', 'android-x86', 'android-x64'],
        help: 'The target platform for which the app is compiled.',
      );
  }

  @override
  final String name = 'aar';

  @override
  Future<Set<DevelopmentArtifact>> get requiredArtifacts async => const <DevelopmentArtifact>{
    DevelopmentArtifact.universal,
    DevelopmentArtifact.android,
  };

  @override
  final String description = 'Build an Android Archive (AAR) file from your module or plugin project.\n\n'
    'In addition, this command generates a Maven POM file, which contains the dependency list used to '
    'resolve transitive dependencies when you import the AAR.';

  @override
  Future<FlutterCommandResult> runCommand() async {
    final BuildInfo buildInfo = getBuildInfo();
    final AndroidBuildInfo androidBuildInfo = AndroidBuildInfo(buildInfo,
      targetArchs: argResults['target-platform'].map<AndroidArch>(getAndroidArchForName)
    );
    await buildAar(
      project: FlutterProject.current(),
      target: '',
      androidBuildInfo: androidBuildInfo,
    );
    return null;
  }
}
