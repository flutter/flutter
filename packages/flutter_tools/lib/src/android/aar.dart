// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import '../base/common.dart';
import '../build_info.dart';
import '../project.dart';

import 'android_sdk.dart';
import 'gradle.dart';

/// Provides a method to build a module or plugin as AAR.
abstract class AarBuilder {
  /// Builds the AAR artifacts.
  Future<void> build({
    @required FlutterProject project,
    @required AndroidBuildInfo androidBuildInfo,
    @required String target,
    @required String outputDir,
  });
}

/// Default implementation of [AarBuilder].
class AarBuilderImpl extends AarBuilder {
  AarBuilderImpl();

  /// Builds the AAR and POM files for the current Flutter module or plugin.
  @override
  Future<void> build({
    @required FlutterProject project,
    @required AndroidBuildInfo androidBuildInfo,
    @required String target,
    @required String outputDir,
  }) async {
    if (!project.android.isUsingGradle) {
      throwToolExit(
          'The build process for Android has changed, and the current project configuration\n'
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
}
