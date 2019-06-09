// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../android/app_bundle.dart';
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
      ..addFlag(
        'build-shared-library',
        negatable: false,
        help: 'Whether to prefer compiling to a *.so file (android only).',
      )
      ..addOption(
        'target-platform',
        allowed: <String>['android-arm', 'android-arm64'],
        help: 'The target platform for which the app is compiled.\n'
            'By default, the bundle will include \'arm\' and \'arm64\', '
            'which is the recommended configuration for app bundles.\n'
            'For more, see https://developer.android.com/distribute/best-practices/develop/64-bit',
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
    await buildAppBundle(
      project: FlutterProject.current(),
      target: targetFile,
      buildInfo: getBuildInfo(),
    );
    return null;
  }
}
