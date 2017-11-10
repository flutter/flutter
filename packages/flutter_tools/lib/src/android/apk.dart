// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/common.dart';
import '../build_info.dart';
import '../globals.dart';
import 'android_sdk.dart';
import 'gradle.dart';

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
