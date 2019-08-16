// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../android/app_bundle.dart';
import '../build_info.dart';
import '../project.dart';
import '../runner/flutter_command.dart' show FlutterCommandResult;
import 'build.dart';

class BuildAppBundleCommand extends BuildSubCommand {
  BuildAppBundleCommand({bool verboseHelp = false}) {
    usesTargetOption();
    addBuildModeFlags();
    usesFlavorOption();
    usesPubOption();
    usesBuildNumberOption();
    usesBuildNameOption();

    argParser
      ..addFlag('track-widget-creation', negatable: false, hide: !verboseHelp)
      ..addMultiOption('target-platform',
        splitCommas: true,
        defaultsTo: <String>['android-arm', 'android-arm64'],
        allowed: <String>['android-arm', 'android-arm64'],
        help: 'The target platform for which the app is compiled.',
      );
  }

  @override
  final String name = 'appbundle';

  @override
  final String description =
      'Build an Android App Bundle file from your app.\n\n'
      'This command can build debug and release versions of an app bundle for your application. \'debug\' builds support '
      'debugging and a quick development cycle. \'release\' builds don\'t support debugging and are '
      'suitable for deploying to app stores. \n app bundle improves your app size';

  @override
  Future<FlutterCommandResult> runCommand() async {
    final AndroidBuildInfo androidBuildInfo = AndroidBuildInfo(getBuildInfo(),
      targetArchs: argResults['target-platform'].map<AndroidArch>(getAndroidArchForName)
    );
    await buildAppBundle(
      project: FlutterProject.current(),
      target: targetFile,
      androidBuildInfo: androidBuildInfo,
    );
    return null;
  }
}
