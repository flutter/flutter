// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import '../android/gradle_errors.dart';
import '../base/context.dart';
import '../base/file_system.dart';
import '../build_info.dart';
import '../globals.dart' as globals;
import '../project.dart';
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
    @required Set<AndroidBuildInfo> androidBuildInfo,
    @required String target,
    @required String outputDirectoryPath,
    @required String buildNumber,
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
    @required Set<AndroidBuildInfo> androidBuildInfo,
    @required String target,
    @required String outputDirectoryPath,
    @required String buildNumber,
  }) async {
    try {
      Directory outputDirectory =
        globals.fs.directory(outputDirectoryPath ?? project.android.buildDirectory);
      if (project.isModule) {
        // Module projects artifacts are located in `build/host`.
        outputDirectory = outputDirectory.childDirectory('host');
      }
      for (final AndroidBuildInfo androidBuildInfo in androidBuildInfo) {
        await buildGradleAar(
          project: project,
          androidBuildInfo: androidBuildInfo,
          target: target,
          outputDirectory: outputDirectory,
          buildNumber: buildNumber,
        );
      }
      printHowToConsumeAar(
        buildModes: androidBuildInfo
          .map<String>((AndroidBuildInfo androidBuildInfo) {
            return androidBuildInfo.buildInfo.modeName;
          }).toSet(),
        androidPackage: project.manifest.androidPackage,
        repoDirectory: getRepoDirectory(outputDirectory),
        buildNumber: buildNumber,
        logger: globals.logger,
        fileSystem: globals.fs,
      );
    } finally {
      globals.androidSdk?.reinitialize();
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
      globals.androidSdk?.reinitialize();
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
      globals.androidSdk?.reinitialize();
    }
  }
}
