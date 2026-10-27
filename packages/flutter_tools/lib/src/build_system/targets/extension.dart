// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools_core/flutter_tools_core.dart' hide BuildMode;

import '../../artifacts.dart';
import '../../base/common.dart';
import '../../base/file_system.dart';
import '../../build_info.dart';

final _placeholderRegex = RegExp(r'\{[A-Z_]+\}');

const _supportedOutputDirPlaceholders = <String>{
  BuiltInPlaceholders.outputDir,
  BuiltInPlaceholders.projectDir,
  BuiltInPlaceholders.buildMode,
  BuiltInPlaceholders.targetPlatform,
};

/// Resolves the output directory for [target] by substituting placeholders
/// (`{OUTPUT_DIR}`, `{PROJECT_DIR}`, `{BUILD_MODE}`, and `{TARGET_PLATFORM}`).
///
/// Relative paths are resolved relative to [projectDir].
/// Throws a [ToolExit] if [ExtensionBuildTarget.outputDir] contains an
/// unsupported `{...}` placeholder.
Directory resolveExtensionOutputDir({
  required BuildMode buildMode,
  required Directory buildOutputDir,
  required FileSystem fileSystem,
  required Directory projectDir,
  required ExtensionBuildTarget target,
}) {
  for (final RegExpMatch match in _placeholderRegex.allMatches(target.outputDir)) {
    final String? placeholder = match[0];
    if (!_supportedOutputDirPlaceholders.contains(placeholder)) {
      throwToolExit(
        'Unsupported placeholder "$placeholder" in outputDir "${target.outputDir}" for build target "${target.name}".',
      );
    }
  }
  String outputPath = target.outputDir
      .replaceAll(BuiltInPlaceholders.outputDir, buildOutputDir.path)
      .replaceAll(BuiltInPlaceholders.projectDir, projectDir.path)
      .replaceAll(BuiltInPlaceholders.buildMode, buildMode.cliName)
      .replaceAll(BuiltInPlaceholders.targetPlatform, target.targetPlatform);
  if (fileSystem.path.isRelative(outputPath)) {
    outputPath = fileSystem.path.join(projectDir.path, outputPath);
  }
  return fileSystem.directory(fileSystem.path.normalize(outputPath));
}

/// Resolves all engine and host artifacts declared on [target] using
/// [artifacts], [buildMode], and optional downloaded [extensionArtifacts].
///
/// Built-in engine and host artifacts always take precedence over
/// [extensionArtifacts]. Throws a [ToolExit] if any requested artifact name is
/// neither a supported built-in artifact nor present in [extensionArtifacts].
// TODO(bkonyi): Download required artifacts on demand if not already cached.
Map<String, String> resolveExtensionBuildTargetArtifacts({
  required Artifacts artifacts,
  required BuildMode buildMode,
  required ExtensionBuildTarget target,
  Map<String, String> extensionArtifacts = const <String, String>{},
}) {
  final TargetPlatform? targetPlatform = _tryResolveTargetPlatform(target.targetPlatform);
  final resolvedArtifacts = <String, String>{...extensionArtifacts};
  for (final ExtensionArtifact artifact in target.artifacts) {
    if (_builtInArtifacts[artifact.name] case final Artifact builtIn) {
      resolvedArtifacts[artifact.name] = artifacts.getArtifactPath(
        builtIn,
        platform: targetPlatform,
        mode: buildMode,
      );
    } else if (!extensionArtifacts.containsKey(artifact.name)) {
      throwToolExit('Unsupported artifact "${artifact.name}" requested by a tool extension.');
    }
  }
  for (final ExtensionHostArtifact artifact in target.hostArtifacts) {
    if (_builtInHostArtifacts[artifact.name] case final HostArtifact builtIn) {
      resolvedArtifacts[artifact.name] = artifacts.getHostArtifact(builtIn).path;
    } else if (!extensionArtifacts.containsKey(artifact.name)) {
      throwToolExit('Unsupported host artifact "${artifact.name}" requested by a tool extension.');
    }
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

const _builtInArtifacts = <String, Artifact>{
  'flutterPatchedSdkPath': Artifact.flutterPatchedSdkPath,
  'genSnapshot': Artifact.genSnapshot,
  'icuData': Artifact.icuData,
  'linuxDesktopPath': Artifact.linuxDesktopPath,
  'linuxHeaders': Artifact.linuxHeaders,
};

const _builtInHostArtifacts = <String, HostArtifact>{
  'impellerc': HostArtifact.impellerc,
  'libtessellator': HostArtifact.libtessellator,
};
