// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'android/apk.dart';
import 'base/common.dart';
import 'base/context.dart';
import 'build_info.dart';
import 'cache.dart';
import 'project.dart';

/// The [PlatformBuilders] instance.
PlatformBuilders get platformBuilders => context.get<PlatformBuilders>();

/// A registry that selects the correct [PlatformBuilder] based on the provided
/// build info.
class PlatformBuilders {
  /// Create a new [PlatformBuilder] with `_platformSteps` as platform specific
  /// implementations.
  const PlatformBuilders([this._platformSteps = const <PlatformBuildStep>[
    AndroidPlatformBuildStep(),
  ]]);

  final List<PlatformBuildStep> _platformSteps;

  /// Build the platform specific bundle for [flutterProject].
  ///
  /// Selects the [PlatformBuildStep] that supports the required [TargetPlatform]
  /// and [BuildMode] requested.
  ///
  /// Throws a [ToolExit] if zero steps or more than one step match.
  PlatformBuildStep selectPlatform({
    BuildInfo buildInfo,
  }) {
    PlatformBuildStep selected;
    for (PlatformBuildStep platformStep in _platformSteps) {
      if (!platformStep.targetPlatforms.contains(buildInfo.targetPlatform)) {
        continue;
      }
      if (!platformStep.buildModes.contains(buildInfo.mode)) {
        continue;
      }
      if (selected != null) {
        throwToolExit(
          'Multiple platform steps registered for targetPlatform: ${buildInfo.targetPlatform} '
          'and build mode: ${buildInfo.mode}.'
        );
      }
      selected = platformStep;
    }
    if (selected == null) {
      throwToolExit(
        'No platform steps registered for targetPlatform: ${buildInfo.targetPlatform} '
        'and build mode: ${buildInfo.mode}.'
      );
    }
    return selected;
  }
}

/// The workflow by which a flutter application in packaged into a platform
/// specific application.
abstract class PlatformBuildStep {
  const PlatformBuildStep();

  /// Build the platform specific bundle for [flutterProject].
  Future<void> build({
    FlutterProject project,
    BuildInfo buildInfo,
    String target,
  });

  /// The targets this platform step supports.
  Set<TargetPlatform> get targetPlatforms;

  /// The build modes this platform step supports.
  Set<BuildMode> get buildModes;

  /// Development artifacts required by this platform step.
  Set<DevelopmentArtifact> get developmentArtifacts;
}
