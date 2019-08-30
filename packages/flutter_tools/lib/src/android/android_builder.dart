// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import '../base/common.dart';
import '../base/context.dart';
import '../build_info.dart';
import '../globals.dart';
import '../project.dart';

import 'android_sdk.dart';
import 'gradle.dart';

/// The builder in the current context.
AndroidBuilder get androidBuilder => context.get<AndroidBuilder>() ?? _AndroidBuilderImpl();

/// Provides the methods to build Android artifacts.
abstract class AndroidBuilder {
  /// Builds an AAR artifact.
  Future<void> buildAar({
    @required FlutterProject project,
    @required AndroidBuildInfo androidBuildInfo,
    @required String target,
    @required String outputDir,
  });

  /// Builds an APK artifact.
  Future<void> buildApk({
    @required FlutterProject project,
    @required AndroidBuildInfo androidBuildInfo,
    @required String target,
  });

  /// Builds an App Bundle artifact.
  Future<void> buildAab({
    @required FlutterProject project,
    @required AndroidBuildInfo androidBuildInfo,
    @required String target,
  });
}

/// Default implementation of [AarBuilder].
class _AndroidBuilderImpl extends AndroidBuilder {
  _AndroidBuilderImpl();

  /// Builds the AAR and POM files for the current Flutter module or plugin.
  @override
  Future<void> buildAar({
    @required FlutterProject project,
    @required AndroidBuildInfo androidBuildInfo,
    @required String target,
    @required String outputDir,
  }) async {
    if (!project.android.isUsingGradle) {
      throwToolExit(
          'The build process for Android has changed, and the current project configuration '
              'is no longer valid. Please consult\n\n'
              '  https://github.com/flutter/flutter/wiki/Upgrading-Flutter-projects-to-build-with-gradle\n\n'
              'for details on how to upgrade the project.'
      );
    }
    if (!project.manifest.isModule && !project.manifest.isPlugin) {
      throwToolExit('AARs can only be built for plugin or module projects.');
    }
    // Validate that we can find an Android SDK.
    if (androidSdk == null) {
      throwToolExit('No Android SDK found. Try setting the `ANDROID_SDK_ROOT` environment variable.');
    }
    await buildGradleAar(
      project: project,
      androidBuildInfo: androidBuildInfo,
      target: target,
      outputDir: outputDir,
    );
    androidSdk.reinitialize();
  }

  /// Builds the APK.
  @override
  Future<void> buildApk({
    @required FlutterProject project,
    @required AndroidBuildInfo androidBuildInfo,
    @required String target,
  }) async {
     if (!project.android.isUsingGradle) {
      throwToolExit(
          'The build process for Android has changed, and the current project configuration '
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
      androidBuildInfo: androidBuildInfo,
      target: target,
      isBuildingBundle: false,
    );
    androidSdk.reinitialize();
  }

  /// Builds the App Bundle.
  @override
  Future<void> buildAab({
    @required FlutterProject project,
    @required AndroidBuildInfo androidBuildInfo,
    @required String target,
  }) async {
    if (!project.android.isUsingGradle) {
      throwToolExit(
          'The build process for Android has changed, and the current project configuration '
          'is no longer valid. Please consult\n\n'
          'https://github.com/flutter/flutter/wiki/Upgrading-Flutter-projects-to-build-with-gradle\n\n'
          'for details on how to upgrade the project.'
      );
    }
    // Validate that we can find an android sdk.
    if (androidSdk == null) {
      throwToolExit('No Android SDK found. Try setting the ANDROID_HOME environment variable.');
    }
    final List<String> validationResult = androidSdk.validateSdkWellFormed();
    if (validationResult.isNotEmpty) {
      for (String message in validationResult) {
        printError(message, wrap: false);
      }
      throwToolExit('Try re-installing or updating your Android SDK.');
    }
    return buildGradleProject(
      project: project,
      androidBuildInfo: androidBuildInfo,
      target: target,
      isBuildingBundle: true,
    );
  }
}

/// A fake implementation of [AndroidBuilder].
@visibleForTesting
class FakeAndroidBuilder implements AndroidBuilder {
  @override
  Future<void> buildAar({
    @required FlutterProject project,
    @required AndroidBuildInfo androidBuildInfo,
    @required String target,
    @required String outputDir,
  }) async {}

  @override
  Future<void> buildApk({
    @required FlutterProject project,
    @required AndroidBuildInfo androidBuildInfo,
    @required String target,
  }) async {}

  @override
  Future<void> buildAab({
    @required FlutterProject project,
    @required AndroidBuildInfo androidBuildInfo,
    @required String target,
  }) async {}
}
