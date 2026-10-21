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
import '../depfile.dart';
import '../exceptions.dart';

/// Resolves a build target dependency by its [dependency] name.
typedef DependencyResolverCallback = Target Function(String dependency);

/// A `flutter assemble` target that delegates to a tool extension.
class ExtensionTarget extends Target {
  ExtensionTarget({
    required this.assembleTarget,
    required this._buildManager,
    required this._dependencyResolver,
  });

  /// The extension-defined assemble target.
  final ExtensionAssembleTarget assembleTarget;

  final ExtensionBuildManager _buildManager;
  final DependencyResolverCallback _dependencyResolver;

  @override
  String get name => assembleTarget.name;

  @override
  late final List<Target> dependencies = assembleTarget.dependencies
      .map(_dependencyResolver)
      .toList();

  late final TargetPlatform? _defaultTargetPlatform = _tryResolveTargetPlatform(
    assembleTarget.targetPlatform,
  );

  @override
  late final List<Source> inputs = assembleTarget.inputs
      .map((ExtensionSource s) => _toHostSource(s, defaultTargetPlatform: _defaultTargetPlatform))
      .toList();

  @override
  late final List<Source> outputs = assembleTarget.outputs
      .map((ExtensionSource s) => _toHostSource(s, defaultTargetPlatform: _defaultTargetPlatform))
      .toList();

  @override
  List<String> get depfiles => assembleTarget.depfiles;

  @override
  Future<void> build(Environment environment) async {
    final Environment(
      :Artifacts artifacts,
      :Directory buildDir,
      :Map<String, String> defines,
      :DepfileService depFileService,
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

    final Map<String, String> resolvedArtifacts = resolveExtensionAssembleTargetArtifacts(
      artifacts: artifacts,
      buildMode: mode,
      target: assembleTarget,
    );

    final ExtensionBuildResult result = await _buildManager.assemble(
      buildDir: buildDir.uri,
      buildMode: mode,
      flutterRoot: environment.flutterRootDir.uri,
      mainPath: mainPath,
      outputDir: outputDir.uri,
      projectRoot: projectDir.uri,
      resolvedArtifacts: resolvedArtifacts,
      targetName: assembleTarget.name,
    );

    if (!result.success) {
      final String? errorMessage = result.errorMessage;
      throwToolExit(
        errorMessage != null && errorMessage.isNotEmpty
            ? 'Extension assemble target "${assembleTarget.name}" failed: $errorMessage'
            : 'Extension assemble target "${assembleTarget.name}" failed.',
      );
    }

    defines.addAll(result.extraDefines);

    for (final String depfileName in depfiles) {
      final File depfileFile = buildDir.childFile(depfileName);
      if (depfileFile.existsSync()) {
        final Depfile depfile = depFileService.parse(depfileFile, projectDir);
        depFileService.writeToFile(depfile, depfileFile, writeEmpty: true);
      }
    }
  }
}

final _placeholderRegex = RegExp(r'\{[^}]+\}');

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
/// unsupported `{...}` placeholder or uses `{TARGET_PLATFORM}` when
/// [ExtensionBuildTarget.targetPlatform] is `null`.
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
    if (placeholder == BuiltInPlaceholders.targetPlatform && target.targetPlatform == null) {
      throwToolExit(
        'Placeholder "${BuiltInPlaceholders.targetPlatform}" in outputDir "${target.outputDir}" '
        'requires targetPlatform to be set on build target "${target.name}".',
      );
    }
  }
  String outputPath = target.outputDir
      .replaceAll(BuiltInPlaceholders.outputDir, buildOutputDir.path)
      .replaceAll(BuiltInPlaceholders.projectDir, projectDir.path)
      .replaceAll(BuiltInPlaceholders.buildMode, buildMode.cliName);
  if (target.targetPlatform case final String targetPlatform) {
    outputPath = outputPath.replaceAll(BuiltInPlaceholders.targetPlatform, targetPlatform);
  }
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

/// Resolves all engine and host artifact inputs declared on [target] using
/// [artifacts] and [buildMode].
///
/// Throws a [ToolExit] if any artifact platform name or requested artifact
/// name is invalid or unsupported.
Map<String, String> resolveExtensionAssembleTargetArtifacts({
  required Artifacts artifacts,
  required BuildMode buildMode,
  required ExtensionAssembleTarget target,
}) {
  final TargetPlatform? targetPlatform = _tryResolveTargetPlatform(target.targetPlatform);
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

TargetPlatform? _tryResolveTargetPlatform(String? platformName) {
  if (platformName == null || platformName.isEmpty) {
    return null;
  }
  try {
    return TargetPlatform.fromName(platformName);
  } on Exception {
    // Custom extension target platforms do not map to a built-in TargetPlatform.
    return null;
  }
}

Source _toHostSource(ExtensionSource source, {TargetPlatform? defaultTargetPlatform}) =>
    switch (source) {
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
          platform: _resolveArtifactPlatform(platform, artifact) ?? defaultTargetPlatform,
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
