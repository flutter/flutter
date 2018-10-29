// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../android/apk.dart';
import '../project.dart';
import '../runner/flutter_command.dart' show FlutterCommandResult;
import 'build.dart';

class BuildApkCommand extends BuildSubCommand {
  BuildApkCommand({bool verboseHelp = false}) {
    usesTargetOption();
    addBuildModeFlags();
    usesFlavorOption();
    usesPubOption();
    usesBuildNumberOption();
    usesBuildNameOption();

    argParser
      ..addFlag('track-widget-creation', negatable: false, hide: !verboseHelp)
      ..addFlag('build-shared-library',
        negatable: false,
        help: 'Whether to prefer compiling to a *.so file (android only).',
      )
      ..addOption('target-platform',
        defaultsTo: 'android-arm',
        allowed: <String>['android-arm', 'android-arm64']);
  }

  @override
  final String name = 'apk';

  @override
  final String description = 'Build an Android APK file from your app.\n\n'
    'This command can build debug and release versions of your application. \'debug\' builds support '
    'debugging and a quick development cycle. \'release\' builds don\'t support debugging and are '
    'suitable for deploying to app stores.';

  @override
  Future<FlutterCommandResult> runCommand() async {
    await super.runCommand();
    await buildApk(
      project: await FlutterProject.current(),
      target: targetFile,
      buildInfo: getBuildInfo(),
    );
    return null;
  }
}
