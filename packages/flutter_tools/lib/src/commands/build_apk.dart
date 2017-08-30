// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart' show required;

import '../android/android_sdk.dart';
import '../android/gradle.dart';
import '../base/common.dart';
import '../build_info.dart';
import '../globals.dart';
import 'build.dart';

export '../android/android_device.dart' show AndroidDevice;

class ApkKeystoreInfo {
  ApkKeystoreInfo({
    @required this.keystore,
    this.password,
    this.keyAlias,
    @required this.keyPassword,
  }) {
    assert(keystore != null);
  }

  final String keystore;
  final String password;
  final String keyAlias;
  final String keyPassword;
}

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

Future<Null> buildApk({
  String target,
  BuildInfo buildInfo: BuildInfo.debug
}) async {
  if (!isProjectUsingGradle()) {
    throwToolExit(
        'The build process for Android has changed, and the current project configuration\n'
        'is no longer valid. Please consult\n\n'
        '  https://github.com/flutter/flutter/wiki/Upgrading-Flutter-projects-to-build-with-gradle\n\n'
        'for details on how to upgrade the project.'
    );
  }

  // Validate that we can find an android sdk.
  if (androidSdk == null)
    throwToolExit('No Android SDK found. Try setting the ANDROID_HOME environment variable.');

  final List<String> validationResult = androidSdk.validateSdkWellFormed();
  if (validationResult.isNotEmpty) {
    validationResult.forEach(printError);
    throwToolExit('Try re-installing or updating your Android SDK.');
  }

  return buildGradleProject(buildInfo, target);
}
