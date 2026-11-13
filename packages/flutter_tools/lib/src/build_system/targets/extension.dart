// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools_core/flutter_tools_core.dart' hide BuildMode, Depfile;

import '../../artifacts.dart';
import '../../base/common.dart';
import '../../base/error_handling_io.dart';
import '../../base/file_system.dart';
import '../../base/logger.dart';
import '../../build_info.dart';
import '../../experimental/extension_build_manager.dart';
import '../build_system.dart';
import '../depfile.dart';
import '../exceptions.dart';

/// Host-owned build environment define keys that extension targets cannot set.
const _reservedEnvironmentDefines = <String>{kBuildMode, kTargetFile, kTargetPlatform};

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

  /// Static input sources for this target.
  ///
  /// [resolveInputs] resolves the concrete input files at build time by
  /// supplying [BuildMode] from the build [Environment] to mode-dependent
  /// artifacts.
  @override
  late final List<Source> inputs = assembleTarget.inputs
      .map(
        (ExtensionSource s) => _toHostSource(
          s,
          defaultTargetPlatform: _defaultTargetPlatform,
          targetPlatformName: assembleTarget.targetPlatform,
        ),
      )
      .toList();

  /// Static output sources for this target.
  ///
  /// [resolveOutputs] resolves the concrete output files at build time by
  /// supplying [BuildMode] from the build [Environment] to mode-dependent
  /// artifacts.
  @override
  late final List<Source> outputs = assembleTarget.outputs
      .map(
        (ExtensionSource s) => _toHostSource(
          s,
          defaultTargetPlatform: _defaultTargetPlatform,
          targetPlatformName: assembleTarget.targetPlatform,
        ),
      )
      .toList();

  BuildMode? _resolveEnvironmentBuildMode(Environment environment) {
    final String? buildMode = environment.defines[kBuildMode];
    return buildMode != null ? BuildMode.fromCliName(buildMode) : null;
  }

  @override
  ResolvedFiles resolveInputs(Environment environment) =>
      _resolveSources(assembleTarget.inputs, environment, inputs: true);

  @override
  ResolvedFiles resolveOutputs(Environment environment) =>
      _resolveSources(assembleTarget.outputs, environment, inputs: false);

  ResolvedFiles _resolveSources(
    List<ExtensionSource> sources,
    Environment environment, {
    required bool inputs,
  }) {
    final BuildMode? mode = _resolveEnvironmentBuildMode(environment);
    final List<Source> resolvedSources = sources
        .map(
          (ExtensionSource s) => _toHostSource(
            s,
            defaultBuildMode: mode,
            defaultTargetPlatform: _defaultTargetPlatform,
            targetPlatformName: assembleTarget.targetPlatform,
          ),
        )
        .toList();
    final collector = SourceVisitor(environment, inputs);
    for (final source in resolvedSources) {
      source.accept(collector);
    }
    depfiles.forEach(collector.visitDepfile);
    return collector;
  }

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
      :Logger logger,
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

    for (final String depfileName in depfiles) {
      ErrorHandlingFileSystem.deleteIfExists(buildDir.childFile(depfileName));
    }

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
      throw ExtensionAssembleException(assembleTarget.name, errorMessage: result.errorMessage);
    }

    for (final String depfileName in depfiles) {
      final File depfileFile = buildDir.childFile(depfileName);
      if (!depfileFile.existsSync()) {
        logger.printError(
          'Extension assemble target "${assembleTarget.name}" declared depfile '
          '"$depfileName", but it was not written to the build directory. '
          'Incremental build caching for this target will be disabled. '
          'Try upgrading the extension or running "flutter clean".',
        );
        continue;
      }
      final Depfile depfile;
      try {
        depfile = depFileService.parse(
          depfileFile,
          allowMalformed: false,
          baseDirectory: projectDir,
        );
      } on FormatException catch (e) {
        logger.printError(
          'Invalid depfile "$depfileName" produced by extension assemble target '
          '"${assembleTarget.name}": ${e.message} '
          'Incremental build caching for this target will be disabled. '
          'Try upgrading the extension or running "flutter clean".',
        );
        ErrorHandlingFileSystem.deleteIfExists(depfileFile);
        continue;
      }
      depFileService.writeToFile(depfile, depfileFile, writeEmpty: true);
    }

    for (final MapEntry(:String key, :String value) in result.extraDefines.entries) {
      if (_reservedEnvironmentDefines.contains(key) || defines.containsKey(key)) {
        logger.printTrace(
          'Ignoring extraDefine "$key" from extension assemble target "${assembleTarget.name}" '
          'because it is reserved or already defined.',
        );
        continue;
      }
      defines[key] = value;
    }
  }
}

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

/// Engine artifacts whose cached path does not depend on the target platform,
/// so they can be resolved for out-of-tree target platforms.
const _targetPlatformIndependentArtifacts = <ExtensionArtifact>{
  BuiltInArtifacts.flutterPatchedSdkPath,
  BuiltInArtifacts.icuData,
};

/// Resolves all engine and host artifacts declared on [target] using
/// [artifacts] and [buildMode].
///
/// Throws a [ToolExit] if any requested artifact name is invalid or unsupported,
/// or if a target-platform-specific artifact is requested on an out-of-tree
/// or unspecified target platform.
// TODO(bkonyi): Download required artifacts on demand if not already cached.
Map<String, String> resolveExtensionBuildTargetArtifacts({
  required Artifacts artifacts,
  required BuildMode buildMode,
  required ExtensionBuildTarget target,
}) {
  final TargetPlatform? targetPlatform = _tryResolveTargetPlatform(target.targetPlatform);
  final resolvedArtifacts = <String, String>{};
  for (final ExtensionArtifact artifact in target.artifacts) {
    final Artifact resolvedArtifact = _resolveArtifact(artifact);
    if (targetPlatform == null && !_targetPlatformIndependentArtifacts.contains(artifact)) {
      final reason = target.targetPlatform != null
          ? 'targets out-of-tree platform "${target.targetPlatform}"'
          : 'does not specify a targetPlatform';
      throwToolExit(
        'Artifact "${artifact.name}" requires a built-in target platform, '
        'but build target "${target.name}" $reason.',
      );
    }
    resolvedArtifacts[artifact.name] = artifacts.getArtifactPath(
      resolvedArtifact,
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
/// Throws a [ToolExit] if any requested artifact name or explicit artifact
/// target platform is invalid or unsupported, if a target-platform-specific
/// artifact resolves to a `null` target platform, or if the same artifact
/// resolves to different paths across multiple target platforms or build modes.
// TODO(bkonyi): Download required artifacts on demand if not already cached.
Map<String, String> resolveExtensionAssembleTargetArtifacts({
  required Artifacts artifacts,
  required BuildMode buildMode,
  required ExtensionAssembleTarget target,
}) {
  final TargetPlatform? defaultTargetPlatform = _tryResolveTargetPlatform(target.targetPlatform);
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
        final Artifact resolvedArtifact = _resolveArtifact(artifact);
        final TargetPlatform? resolvedPlatform = _resolveArtifactTargetPlatform(
          artifact: artifact,
          defaultTargetPlatform: defaultTargetPlatform,
          sourcePlatform: platform,
          targetPlatformName: target.targetPlatform,
        );
        final String path = artifacts.getArtifactPath(
          resolvedArtifact,
          platform: resolvedPlatform,
          mode: mode ?? buildMode,
        );
        final String? existingPath = resolvedArtifacts[artifact.name];
        if (existingPath != null && existingPath != path) {
          throwToolExit(
            'Assemble target "${target.name}" requested artifact "${artifact.name}" '
            'for multiple target platforms or build modes.',
          );
        }
        resolvedArtifacts[artifact.name] = path;
      case ExtensionHostArtifactSource(:final ExtensionHostArtifact artifact):
        final HostArtifact hostArtifact = _resolveHostArtifact(artifact);
        resolvedArtifacts[artifact.name] = artifacts.getHostArtifact(hostArtifact).path;
    }
  }
  return resolvedArtifacts;
}

TargetPlatform? _resolveArtifactTargetPlatform({
  required ExtensionArtifact artifact,
  required TargetPlatform? defaultTargetPlatform,
  required String? sourcePlatform,
  required String targetPlatformName,
}) {
  final TargetPlatform? resolvedPlatform;
  if (sourcePlatform != null) {
    resolvedPlatform = _tryResolveTargetPlatform(sourcePlatform);
    if (resolvedPlatform == null) {
      throwToolExit(
        'Unsupported target platform "$sourcePlatform" for artifact "${artifact.name}".',
      );
    }
  } else {
    resolvedPlatform = defaultTargetPlatform;
  }
  if (resolvedPlatform == null && !_targetPlatformIndependentArtifacts.contains(artifact)) {
    throwToolExit(
      'Artifact "${artifact.name}" requires a built-in target platform; specify a built-in '
      '"platform" on the artifact source when targeting out-of-tree platform '
      '"$targetPlatformName".',
    );
  }
  return resolvedPlatform;
}

TargetPlatform? _tryResolveTargetPlatform(String? platformName) {
  if (platformName == null || platformName.isEmpty) {
    return null;
  }
  try {
    return TargetPlatform.fromName(platformName);
  } on Exception {
    // Out-of-tree extension target platforms don't map to a built-in
    // TargetPlatform, so target-independent artifacts resolve with
    // platform: null. Target-specific engine artifacts such as genSnapshot
    // require an explicit built-in platform on the artifact source until
    // extensions can provide their own artifacts.
    // TODO(bkonyi): Support custom extension-provided artifact resolution for
    // out-of-tree target platforms via ExtensionArtifactManager.
    return null;
  }
}

Source _toHostSource(
  ExtensionSource source, {
  required TargetPlatform? defaultTargetPlatform,
  required String targetPlatformName,
  BuildMode? defaultBuildMode,
}) => switch (source) {
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
      platform: _resolveArtifactTargetPlatform(
        artifact: artifact,
        defaultTargetPlatform: defaultTargetPlatform,
        sourcePlatform: platform,
        targetPlatformName: targetPlatformName,
      ),
      mode: mode ?? defaultBuildMode,
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

HostArtifact _resolveHostArtifact(ExtensionHostArtifact artifact) => switch (artifact.name) {
  'impellerc' => HostArtifact.impellerc,
  'libtessellator' => HostArtifact.libtessellator,
  final String name => throwToolExit(
    'Unsupported host artifact "$name" requested by a tool extension.',
  ),
};
