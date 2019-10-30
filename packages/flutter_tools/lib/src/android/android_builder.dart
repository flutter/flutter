// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import '../android/gradle_errors.dart';
import '../base/context.dart';
import '../base/file_system.dart';
import '../build_info.dart';
import '../project.dart';
import 'android_sdk.dart';
import 'gradle.dart';

/// The builder in the current context.
AndroidBuilder get androidBuilder {
  return context.get<AndroidBuilder>() ?? const _AndroidBuilderImpl();
}

/// Provides the methods to build Android artifacts.
// TODO(egarciad): https://github.com/flutter/flutter/issues/43863
abstract class AndroidBuilder {
  const AndroidBuilder();
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
  const _AndroidBuilderImpl();

  /// Builds the AAR and POM files for the current Flutter module or plugin.
  @override
  Future<void> buildAar({
    @required FlutterProject project,
    @required AndroidBuildInfo androidBuildInfo,
    @required String target,
    @required String outputDir,
  }) async {
    try {
      Directory outputDirectory =
        fs.directory(outputDir ?? project.android.buildDirectory);
      if (project.isModule) {
        // Module projects artifacts are located in `build/host`.
        outputDirectory = outputDirectory.childDirectory('host');
      }
      await buildGradleAar(
        project: project,
        androidBuildInfo: androidBuildInfo,
        target: target,
        outputDir: outputDirectory,
      );
    } finally {
      androidSdk.reinitialize();
    }
  }

  /// Builds the APK.
  @override
  Future<void> buildApk({
    @required FlutterProject project,
    @required AndroidBuildInfo androidBuildInfo,
    @required String target,
  }) async {
    try {
      await buildGradleApp(
        project: project,
        androidBuildInfo: androidBuildInfo,
        target: target,
        isBuildingBundle: false,
        localGradleErrors: gradleErrors,
      );
    } finally {
      androidSdk.reinitialize();
    }
  }

  /// Builds the App Bundle.
  @override
  Future<void> buildAab({
    @required FlutterProject project,
    @required AndroidBuildInfo androidBuildInfo,
    @required String target,
  }) async {
    try {
      await buildGradleApp(
        project: project,
        androidBuildInfo: androidBuildInfo,
        target: target,
        isBuildingBundle: true,
        localGradleErrors: gradleErrors,
      );
    } finally {
      androidSdk.reinitialize();
    }
  }
}
