// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../android/apk.dart';
import 'build.dart';

class BuildApkCommand extends BuildSubCommand {
  BuildApkCommand() {
    usesTargetOption();
    addBuildModeFlags();
    argParser.addFlag('preview-dart-2', negatable: false);
    usesFlavorOption();
    usesPubOption();
  }

  @override
  final String name = 'apk';

  @override
  final String description = 'Build an Android APK file from your app.\n\n'
    'This command can build debug and release versions of your application. \'debug\' builds support\n'
    'debugging and a quick development cycle. \'release\' builds don\'t support debugging and are\n'
    'suitable for deploying to app stores.';

  @override
  Future<Null> runCommand() async {
    await super.runCommand();
    await buildApk(buildInfo: getBuildInfo(), target: targetFile);
  }
}
