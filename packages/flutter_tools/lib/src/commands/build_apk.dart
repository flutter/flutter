// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../android/apk.dart';
import '../build_info.dart';
import '../globals.dart';
import '../project.dart';
import '../runner/flutter_command.dart' show FlutterCommandResult;
import 'build.dart';

class BuildApkCommand extends BuildSubCommand {
  BuildApkCommand({bool verboseHelp = false}) {
    usesTargetOption();
    addBuildModeFlags(verboseHelp: verboseHelp);
    addDynamicModeFlags(verboseHelp: verboseHelp);
    addDynamicPatchingFlags(verboseHelp: verboseHelp);
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
        allowed: <String>['android-arm', 'android-arm64', 'android-x86', 'android-x64']);
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
    await buildApk(
      project: await FlutterProject.current(),
      target: targetFile,
      buildInfo: getBuildInfo(),
    );
    return null;
  }

  @override
  Future<void> updateCache() async {
    final BuildInfo buildInfo = getBuildInfo();
    await cache.updateAll(
      buildModes: <BuildMode>[
        buildInfo.mode,
        BuildMode.debug,
      ],
      targetPlatforms: <TargetPlatform>[
        TargetPlatform.android_arm,
        TargetPlatform.android_arm64,
        TargetPlatform.android_x64,
        TargetPlatform.android_x86
      ],
      clobber: false,
      skipUnknown: true,
    );
  }
}
