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
  ApkKeystoreInfo({ this.keystore, this.password, this.keyAlias, @required this.keyPassword }) {
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
    usesPubOption();

    argParser.addOption('target-arch',
      defaultsTo: 'arm',
      allowed: <String>['arm', 'x86', 'x64'],
      help: 'Architecture of the target device.');
  }

  @override
  final String name = 'apk';

  @override
  final String description = 'Build an Android APK file from your app.\n\n'
    'This command can build debug and release versions of your application. \'debug\' builds support\n'
    'debugging and a quick development cycle. \'release\' builds don\'t support debugging and are\n'
    'suitable for deploying to app stores.';

  TargetPlatform _getTargetPlatform(String targetArch) {
    switch (targetArch) {
      case 'arm':
        return TargetPlatform.android_arm;
      case 'x86':
        return TargetPlatform.android_x86;
      case 'x64':
        return TargetPlatform.android_x64;
      default:
        throw new Exception('Unrecognized target architecture: $targetArch');
    }
  }

  @override
  Future<Null> runCommand() async {
    await super.runCommand();

    final TargetPlatform targetPlatform = _getTargetPlatform(argResults['target-arch']);
    final BuildMode buildMode = getBuildMode();
    await buildApk(targetPlatform, buildMode: buildMode, target: targetFile);
  }
}

Future<Null> buildApk(
  TargetPlatform platform, {
  String target,
  BuildMode buildMode: BuildMode.debug,
  String kernelPath,
}) async {
  if (!isProjectUsingGradle()) {
    throwToolExit(
        'The build process for Android has changed, and the current project configuration\n'
        'is no longer valid. Please consult\n\n'
        '  https://github.com/flutter/flutter/wiki/Upgrading-Flutter-projects-to-build-with-gradle\n\n'
        'for details on how to upgrade the project.'
    );
  }

  if (platform != TargetPlatform.android_arm && buildMode != BuildMode.debug) {
    throwToolExit('Profile and release builds are only supported on ARM targets.');
  }
  // Validate that we can find an android sdk.
  if (androidSdk == null)
    throwToolExit('No Android SDK found. Try setting the ANDROID_HOME environment variable.');

  final List<String> validationResult = androidSdk.validateSdkWellFormed();
  if (validationResult.isNotEmpty) {
    validationResult.forEach(printError);
    throwToolExit('Try re-installing or updating your Android SDK.');
  }

  return buildGradleProject(buildMode, target, kernelPath);
}
