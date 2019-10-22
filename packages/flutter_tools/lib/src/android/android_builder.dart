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
    try {
      await buildGradleAar(
        project: project,
        androidBuildInfo: androidBuildInfo,
        target: target,
        outputDir: fs.directory(outputDir ?? project.android.buildDirectory),
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
        gradleErrors: gradleErrors,
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
        gradleErrors: gradleErrors,
      );
    } finally {
      androidSdk.reinitialize();
    }
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
