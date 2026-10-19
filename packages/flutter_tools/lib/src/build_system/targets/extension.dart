// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools_core/flutter_tools_core.dart' hide BuildMode;

import '../../artifacts.dart';
import '../../base/common.dart';
import '../../base/file_system.dart';
import '../../build_info.dart';

/// Resolves the output directory for [target] by substituting placeholders
/// (`{PROJECT_DIR}`, `{BUILD_DIR}`, `{BUILD_MODE}`, and `{TARGET_PLATFORM}`).
///
/// Relative paths are resolved relative to [projectDir].
Directory resolveExtensionOutputDir({
  required Directory buildDir,
  required BuildMode buildMode,
  required FileSystem fileSystem,
  required Directory projectDir,
  required ExtensionBuildTarget target,
}) {
  String outputPath = target.outputDir
      .replaceAll(BuiltInPlaceholders.projectDir, projectDir.path)
      .replaceAll(BuiltInPlaceholders.buildDir, buildDir.path)
      .replaceAll(BuiltInPlaceholders.buildMode, buildMode.cliName)
      .replaceAll(BuiltInPlaceholders.targetPlatform, target.targetPlatform);
  if (fileSystem.path.isRelative(outputPath)) {
    outputPath = fileSystem.path.join(projectDir.path, outputPath);
  }
  return fileSystem.directory(fileSystem.path.normalize(outputPath));
}

/// Resolves all engine and host artifacts declared on [target] using
/// [artifacts] and [buildMode].
///
/// Throws a [ToolExit] if any requested artifact name is invalid or unsupported.
Map<String, String> resolveExtensionBuildTargetArtifacts({
  required Artifacts artifacts,
  required BuildMode buildMode,
  required ExtensionBuildTarget target,
}) {
  final TargetPlatform? targetPlatform = _tryResolveTargetPlatform(target.targetPlatform);
  final resolvedArtifacts = <String, String>{};
  for (final ExtensionArtifact artifact in target.artifacts) {
    final Artifact hostArtifact = _resolveArtifact(artifact);
    resolvedArtifacts[artifact.name] = artifacts.getArtifactPath(
      hostArtifact,
      platform: targetPlatform,
      mode: buildMode,
    );
  }
  for (final ExtensionHostArtifact artifact in target.hostArtifacts) {
    final HostArtifact hostArtifact = _resolveHostArtifact(artifact);
    resolvedArtifacts[artifact.name] = artifacts.getHostArtifact(hostArtifact).path;
  }
  return resolvedArtifacts;
}

TargetPlatform? _tryResolveTargetPlatform(String platformName) {
  if (platformName.isEmpty) {
    return null;
  }
  try {
    return TargetPlatform.fromName(platformName);
  } on Exception {
    // Custom extension target platforms do not map to a built-in TargetPlatform.
    return null;
  }
}

Artifact _resolveArtifact(ExtensionArtifact artifact) => switch (artifact.name) {
  'flutterPatchedSdkPath' => Artifact.flutterPatchedSdkPath,
  'genSnapshot' => Artifact.genSnapshot,
  'icuData' => Artifact.icuData,
  'linuxDesktopPath' => Artifact.linuxDesktopPath,
  'linuxHeaders' => Artifact.linuxHeaders,
  final String name => throwToolExit('Unsupported artifact "$name" requested by a tool extension.'),
};

HostArtifact _resolveHostArtifact(ExtensionHostArtifact artifact) => switch (artifact.name) {
  'impellerc' => HostArtifact.impellerc,
  'libtessellator' => HostArtifact.libtessellator,
  final String name => throwToolExit(
    'Unsupported host artifact "$name" requested by a tool extension.',
  ),
};
