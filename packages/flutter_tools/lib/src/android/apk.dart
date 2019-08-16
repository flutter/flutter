// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import '../base/common.dart';
import '../build_info.dart';
import '../project.dart';

import 'android_sdk.dart';
import 'gradle.dart';

Future<void> buildApk({
  @required FlutterProject project,
  @required String target,
  @required AndroidBuildInfo androidBuildInfo,
}) async {
  if (!project.android.isUsingGradle) {
    throwToolExit(
        'The build process for Android has changed, and the current project configuration\n'
            'is no longer valid. Please consult\n\n'
            '  https://github.com/flutter/flutter/wiki/Upgrading-Flutter-projects-to-build-with-gradle\n\n'
            'for details on how to upgrade the project.'
    );
  }

  // Validate that we can find an android sdk.
  if (androidSdk == null)
    throwToolExit('No Android SDK found. Try setting the ANDROID_SDK_ROOT environment variable.');

  await buildGradleProject(
    project: project,
    androidBuildInfo: androidBuildInfo,
    target: target,
    isBuildingBundle: false,
  );
  androidSdk.reinitialize();
}
