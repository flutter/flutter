// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools_core/flutter_tools_core.dart' hide BuildMode;

import '../../artifacts.dart';
import '../../base/common.dart';
import '../../base/file_system.dart';
import '../../build_info.dart';
import '../../experimental/extension_build_manager.dart';
import '../build_system.dart';
import '../exceptions.dart';

/// A build target that delegates to a tool extension.
class ExtensionAssembleTarget extends Target {
  ExtensionAssembleTarget({
    required this._buildManager,
    required this.buildTarget,
    required this._dependencyResolver,
  });

  /// The extension-defined build target.
  final ExtensionBuildTarget buildTarget;

  final ExtensionBuildManager _buildManager;
  final Target Function(String) _dependencyResolver;

  @override
  String get name => buildTarget.name;

  @override
  late final List<Target> dependencies = buildTarget.dependencies.map(_dependencyResolver).toList();

  @override
  late final List<Source> inputs = buildTarget.inputs.map(_toHostSource).toList();

  @override
  late final List<Source> outputs = buildTarget.outputs.map(_toHostSource).toList();

  @override
  Future<void> build(Environment environment) async {
    final Environment(
      :Artifacts artifacts,
      :Directory buildDir,
      :Map<String, String> defines,
      :FileSystem fileSystem,
      :Directory outputDir,
      :Directory projectDir,
    ) = environment;
    final String mainPath = defines[kTargetFile] ?? fileSystem.path.join('lib', 'main.dart');
    final String? buildMode = defines[kBuildMode];
    if (buildMode == null) {
      throw MissingDefineException(kBuildMode, name);
    }
    final mode = BuildMode.fromCliName(buildMode);

    final Map<String, String> resolvedArtifacts = resolveExtensionTargetArtifacts(
      artifacts: artifacts,
      buildMode: mode,
      target: buildTarget,
    );

    final ExtensionBuildResult result = await _buildManager.build(
      buildDir: buildDir.uri,
      buildMode: mode,
      mainPath: mainPath,
      outputDir: outputDir.uri,
      projectRoot: projectDir.uri,
      resolvedArtifacts: resolvedArtifacts,
      targetName: buildTarget.name,
    );

    if (!result.success) {
      throwToolExit(result.errorMessage ?? 'Extension build target ${buildTarget.name} failed.');
    }
  }
}

/// Resolves the output directory for [target] by substituting placeholders
/// (`{PROJECT_DIR}`, `{BUILD_DIR}`, `{BUILD_MODE}`, and `{TARGET_PLATFORM}`).
Directory resolveExtensionOutputDir({
  required Directory buildDir,
  required BuildMode buildMode,
  required FileSystem fileSystem,
  required Directory projectDir,
  required ExtensionBuildTarget target,
}) {
  final String outputPath = fileSystem.path.normalize(
    target.outputDir
        .replaceAll(kProjectDirPlaceholder, projectDir.path)
        .replaceAll(kBuildDirPlaceholder, buildDir.path)
        .replaceAll(kBuildModePlaceholder, buildMode.cliName)
        .replaceAll(kTargetPlatformPlaceholder, target.targetPlatform),
  );
  return fileSystem.directory(outputPath);
}

/// Resolves all engine and host artifact inputs declared on [target] using
/// [artifacts] and [buildMode].
///
/// Throws a [ToolExit] if any artifact platform name or requested artifact
/// name is invalid or unsupported.
Map<String, String> resolveExtensionTargetArtifacts({
  required Artifacts artifacts,
  required BuildMode buildMode,
  required ExtensionBuildTarget target,
}) {
  TargetPlatform? targetPlatform;
  if (target.targetPlatform.isNotEmpty) {
    try {
      targetPlatform = TargetPlatform.fromName(target.targetPlatform);
    } on Exception {
      // Custom extension target platforms do not map to a built-in TargetPlatform.
    }
  }
  final resolvedArtifacts = <String, String>{};
  for (final ExtensionSource input in target.inputs) {
    switch (input) {
      case ExtensionPatternSource():
        continue;
      case ExtensionArtifactSource(
        :final ExtensionArtifact artifact,
        :final String? platform,
        :final BuildMode? mode,
      ):
        final Artifact hostArtifact = _resolveArtifact(artifact);
        final TargetPlatform? resolvedPlatform = _resolveArtifactPlatform(platform, artifact);
        resolvedArtifacts[artifact.name] = artifacts.getArtifactPath(
          hostArtifact,
          platform: resolvedPlatform ?? targetPlatform,
          mode: mode ?? buildMode,
        );
      case ExtensionHostArtifactSource(:final ExtensionHostArtifact artifact):
        final HostArtifact hostArtifact = _resolveHostArtifact(artifact);
        resolvedArtifacts[artifact.name] = artifacts.getHostArtifact(hostArtifact).path;
    }
  }
  return resolvedArtifacts;
}

Source _toHostSource(ExtensionSource source) => switch (source) {
  ExtensionPatternSource(:final String value, :final bool optional) => Source.pattern(
    value,
    optional: optional,
  ),
  ExtensionArtifactSource(
    :final ExtensionArtifact artifact,
    :final String? platform,
    :final BuildMode? mode,
  ) =>
    Source.artifact(
      _resolveArtifact(artifact),
      platform: _resolveArtifactPlatform(platform, artifact),
      mode: mode,
    ),
  ExtensionHostArtifactSource(:final ExtensionHostArtifact artifact) => Source.hostArtifact(
    _resolveHostArtifact(artifact),
  ),
};

Artifact _resolveArtifact(ExtensionArtifact artifact) => switch (artifact.name) {
  'flutterPatchedSdkPath' => Artifact.flutterPatchedSdkPath,
  'genSnapshot' => Artifact.genSnapshot,
  'icuData' => Artifact.icuData,
  'linuxDesktopPath' => Artifact.linuxDesktopPath,
  'linuxHeaders' => Artifact.linuxHeaders,
  final String name => throwToolExit('Unsupported artifact "$name" requested by a tool extension.'),
};

TargetPlatform? _resolveArtifactPlatform(String? platformName, ExtensionArtifact artifact) {
  if (platformName == null) {
    return null;
  }
  try {
    return TargetPlatform.fromName(platformName);
  } on Exception {
    throwToolExit('Invalid platform name "$platformName" for artifact "${artifact.name}".');
  }
}

HostArtifact _resolveHostArtifact(ExtensionHostArtifact artifact) => switch (artifact.name) {
  'impellerc' => HostArtifact.impellerc,
  'libtessellator' => HostArtifact.libtessellator,
  final String name => throwToolExit(
    'Unsupported host artifact "$name" requested by a tool extension.',
  ),
};
