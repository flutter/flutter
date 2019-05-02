// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/common.dart';
import '../build_info.dart';
import '../cache.dart';
import '../platform_step.dart';
import '../project.dart';

import 'android_sdk.dart';
import 'gradle.dart';

/// The Android Gradle build step.
class AndroidPlatformBuildStep extends PlatformBuildStep {
  const AndroidPlatformBuildStep();

  @override
  Future<void> build({
    FlutterProject project,
    BuildInfo buildInfo,
    String target,
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
    if (androidSdk == null) {
      throwToolExit('No Android SDK found. Try setting the ANDROID_SDK_ROOT environment variable.');
    }
    await buildGradleProject(
      project: project,
      buildInfo: buildInfo,
      target: target,
      isBuildingBundle: false,
    );
    androidSdk.reinitialize();
  }

  @override
  Set<TargetPlatform> get targetPlatforms => const <TargetPlatform>{
    TargetPlatform.android_arm,
    TargetPlatform.android_arm64,
    TargetPlatform.android_x64,
    TargetPlatform.android_x86,
  };

  @override
  Set<BuildMode> get buildModes => const <BuildMode>{
    BuildMode.debug,
    BuildMode.dynamicProfile,
    BuildMode.dynamicRelease,
    BuildMode.profile,
    BuildMode.release,
  };

  @override
  Set<DevelopmentArtifact> get developmentArtifacts => const <DevelopmentArtifact>{
    DevelopmentArtifact.universal,
    DevelopmentArtifact.android,
  };
}
