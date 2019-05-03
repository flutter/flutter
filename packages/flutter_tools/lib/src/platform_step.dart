// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'android/apk.dart';
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
  /// Throws an [AmbiguousPlatformBuilder] if multiple build steps
  /// match.
  ///
  /// Throws a [MissingPlatformBuilder] if no build steps match.
  PlatformBuildStep selectPlatform({
    BuildInfo buildInfo,
  }) {
    PlatformBuildStep selected;
    for (PlatformBuildStep platformStep in _platformSteps) {
      final Set<BuildMode> modes = platformStep.supported[buildInfo.targetPlatform];
      if (modes == null) {
        continue;
      }
      if (!modes.contains(buildInfo.mode)) {
        continue;
      }
      if (selected != null) {
        throw AmbiguousPlatformBuilder(
          buildInfo.mode,
          buildInfo.targetPlatform,
        );
      }
      selected = platformStep;
    }
    if (selected == null) {
      throw MissingPlatformBuilder(
        buildInfo.mode,
        buildInfo.targetPlatform,
      );
    }
    return selected;
  }
}

/// An exception thrown when there is no builder corresponding to the provided
/// target platform and build mode combination.
class MissingPlatformBuilder implements Exception {
  const MissingPlatformBuilder(this.buildMode, this.targetPlatform);

  final BuildMode buildMode;
  final TargetPlatform targetPlatform;

  @override
  String toString() => 'Cannot build for $targetPlatform in $buildMode';
}

/// An exception thrown when there is are multiple builders corresponding to
/// the target platform and build mode combination.
class AmbiguousPlatformBuilder implements Exception {
  const AmbiguousPlatformBuilder(this.buildMode, this.targetPlatform);

  final BuildMode buildMode;
  final TargetPlatform targetPlatform;

  @override
  String toString() => 'Multiple builders for $targetPlatform in $buildMode';
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

  /// The supported build and platform modes for this target.
  Map<TargetPlatform, Set<BuildMode>> get supported;

  /// Development artifacts required by this platform step.
  Set<DevelopmentArtifact> get developmentArtifacts;
}
