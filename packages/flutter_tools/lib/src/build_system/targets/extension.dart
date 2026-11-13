// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools_core/flutter_tools_core.dart' hide BuildMode;

import '../../artifacts.dart';
import '../../base/common.dart';
import '../../base/file_system.dart';
import '../../build_info.dart';
import '../../experimental/extension_artifact_manager.dart';
import '../../experimental/extension_build_manager.dart';
import '../build_system.dart';
import '../exceptions.dart';

/// Resolves a build target dependency by its [dependency] name.
typedef DependencyResolverCallback = Target Function(String dependency);

/// A `flutter assemble` target that delegates to a tool extension.
class ExtensionTarget extends Target {
  ExtensionTarget({
    required this.assembleTarget,
    required this._buildManager,
    required this._dependencyResolver,
    this._extensionArtifacts = const <String, ResolvedExtensionArtifact>{},
  });

  /// The extension-defined assemble target.
  final ExtensionAssembleTarget assembleTarget;

  final ExtensionBuildManager _buildManager;
  final DependencyResolverCallback _dependencyResolver;
  final Map<String, ResolvedExtensionArtifact> _extensionArtifacts;

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
          extensionArtifacts: _extensionArtifacts,
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
          extensionArtifacts: _extensionArtifacts,
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
            extensionArtifacts: _extensionArtifacts,
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

    final Map<String, String> resolvedArtifacts = resolveExtensionAssembleTargetArtifacts(
      artifacts: artifacts,
      buildMode: mode,
      extensionArtifacts: _extensionArtifacts,
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
      throw ExtensionAssembleException(assembleTarget.name, errorMessage: result.errorMessage);
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

/// Engine artifacts whose cached path does not depend on the target platform,
/// so they can be resolved for out-of-tree target platforms.
const _targetPlatformIndependentArtifacts = <ExtensionArtifact>{
  BuiltInArtifacts.flutterPatchedSdkPath,
  BuiltInArtifacts.icuData,
};

/// Returns the non-built-in artifact names declared on [target] (excluding
/// built-in engine and host artifacts, which always resolve from [Artifacts]).
Set<String> customArtifactNamesForBuildTarget(ExtensionBuildTarget target) => <String>{
  for (final ExtensionArtifact artifact in target.artifacts)
    if (!_builtInArtifacts.containsKey(artifact.name)) artifact.name,
  for (final ExtensionHostArtifact artifact in target.hostArtifacts)
    if (!_builtInHostArtifacts.containsKey(artifact.name)) artifact.name,
};

/// Returns the non-built-in artifact names and target platforms requested by
/// [target]'s inputs.
({Set<String> artifactNames, Set<String> targetPlatforms}) customArtifactRequestsForAssembleTarget(
  ExtensionAssembleTarget target,
) {
  final artifactNames = <String>{};
  final targetPlatforms = <String>{if (target.targetPlatform.isNotEmpty) target.targetPlatform};
  for (final ExtensionSource source in target.inputs) {
    switch (source) {
      case ExtensionPatternSource():
        continue;
      case ExtensionArtifactSource(:final ExtensionArtifact artifact, :final String? platform)
          when !_builtInArtifacts.containsKey(artifact.name):
        artifactNames.add(artifact.name);
        if (platform != null && platform.isNotEmpty) {
          targetPlatforms.add(platform);
        }
      case ExtensionArtifactSource():
        continue;
      case ExtensionHostArtifactSource(:final ExtensionHostArtifact artifact)
          when !_builtInHostArtifacts.containsKey(artifact.name):
        artifactNames.add(artifact.name);
      case ExtensionHostArtifactSource():
        continue;
    }
  }
  return (artifactNames: artifactNames, targetPlatforms: targetPlatforms);
}

/// Resolves all engine, host, and custom extension artifacts declared on
/// [target] using [artifacts], [buildMode], and optional [extensionArtifacts].
///
/// Built-in engine and host artifacts always take precedence over
/// [extensionArtifacts], and undeclared entries in [extensionArtifacts] are not
/// included. Throws a [ToolExit] if any requested artifact name is neither a
/// supported built-in artifact nor present in [extensionArtifacts], or if a
/// target-platform-specific built-in artifact is requested on an out-of-tree
/// target platform.
Map<String, String> resolveExtensionBuildTargetArtifacts({
  required Artifacts artifacts,
  required BuildMode buildMode,
  required ExtensionBuildTarget target,
  Map<String, ResolvedExtensionArtifact> extensionArtifacts =
      const <String, ResolvedExtensionArtifact>{},
}) {
  final TargetPlatform? targetPlatform = _tryResolveTargetPlatform(target.targetPlatform);
  final resolvedArtifacts = <String, String>{};
  for (final ExtensionArtifact artifact in target.artifacts) {
    if (_builtInArtifacts[artifact.name] case final Artifact builtIn) {
      if (targetPlatform == null && !_targetPlatformIndependentArtifacts.contains(artifact)) {
        throwToolExit(
          'Artifact "${artifact.name}" requires a built-in target platform, '
          'but build target "${target.name}" targets out-of-tree platform "${target.targetPlatform}".',
        );
      }
      resolvedArtifacts[artifact.name] = artifacts.getArtifactPath(
        builtIn,
        platform: targetPlatform,
        mode: buildMode,
      );
    } else if (extensionArtifacts[artifact.name] case final ResolvedExtensionArtifact custom) {
      resolvedArtifacts[artifact.name] = custom.path;
    } else {
      throwToolExit('Unsupported artifact "${artifact.name}" requested by a tool extension.');
    }
  }
  for (final ExtensionHostArtifact artifact in target.hostArtifacts) {
    if (_builtInHostArtifacts[artifact.name] case final HostArtifact builtIn) {
      resolvedArtifacts[artifact.name] = artifacts.getHostArtifact(builtIn).path;
    } else if (extensionArtifacts[artifact.name] case final ResolvedExtensionArtifact custom) {
      resolvedArtifacts.putIfAbsent(artifact.name, () => custom.path);
    } else {
      throwToolExit('Unsupported host artifact "${artifact.name}" requested by a tool extension.');
    }
  }
  return resolvedArtifacts;
}

/// Resolves all engine, host, and custom extension artifact inputs declared on
/// [target] using [artifacts], [buildMode], and optional [extensionArtifacts].
///
/// Built-in engine and host artifacts always take precedence over
/// [extensionArtifacts]. Throws a [ToolExit] if any requested artifact name or
/// explicit built-in artifact target platform is invalid or unsupported, if a
/// target-platform-specific built-in artifact resolves to a `null` target
/// platform, or if the same artifact resolves to different paths across
/// multiple target platforms or build modes.
Map<String, String> resolveExtensionAssembleTargetArtifacts({
  required Artifacts artifacts,
  required BuildMode buildMode,
  required ExtensionAssembleTarget target,
  Map<String, ResolvedExtensionArtifact> extensionArtifacts =
      const <String, ResolvedExtensionArtifact>{},
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
        final String path;
        if (_builtInArtifacts[artifact.name] case final Artifact builtIn) {
          final TargetPlatform? resolvedPlatform = _resolveArtifactTargetPlatform(
            artifact: artifact,
            defaultTargetPlatform: defaultTargetPlatform,
            sourcePlatform: platform,
            targetPlatformName: target.targetPlatform,
          );
          path = artifacts.getArtifactPath(
            builtIn,
            platform: resolvedPlatform,
            mode: mode ?? buildMode,
          );
        } else if (extensionArtifacts[artifact.name] case final ResolvedExtensionArtifact custom) {
          path = custom.path;
        } else {
          throwToolExit('Unsupported artifact "${artifact.name}" requested by a tool extension.');
        }
        final String? existingPath = resolvedArtifacts[artifact.name];
        if (existingPath != null && existingPath != path) {
          throwToolExit(
            'Assemble target "${target.name}" requested artifact "${artifact.name}" '
            'for multiple target platforms or build modes.',
          );
        }
        resolvedArtifacts[artifact.name] = path;
      case ExtensionHostArtifactSource(:final ExtensionHostArtifact artifact):
        if (_builtInHostArtifacts[artifact.name] case final HostArtifact hostArtifact) {
          resolvedArtifacts[artifact.name] = artifacts.getHostArtifact(hostArtifact).path;
        } else if (extensionArtifacts[artifact.name] case final ResolvedExtensionArtifact custom) {
          resolvedArtifacts.putIfAbsent(artifact.name, () => custom.path);
        } else {
          throwToolExit(
            'Unsupported host artifact "${artifact.name}" requested by a tool extension.',
          );
        }
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

TargetPlatform? _tryResolveTargetPlatform(String platformName) {
  if (platformName.isEmpty) {
    return null;
  }
  try {
    return TargetPlatform.fromName(platformName);
  } on Exception {
    // Out-of-tree extension target platforms don't map to a built-in
    // TargetPlatform, so target-independent built-in artifacts resolve with
    // platform: null while custom artifacts resolve via ExtensionArtifactManager.
    return null;
  }
}

Source _toHostSource(
  ExtensionSource source, {
  required TargetPlatform? defaultTargetPlatform,
  required Map<String, ResolvedExtensionArtifact> extensionArtifacts,
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
    switch (_builtInArtifacts[artifact.name]) {
      final Artifact builtIn => Source.artifact(
        builtIn,
        platform: _resolveArtifactTargetPlatform(
          artifact: artifact,
          defaultTargetPlatform: defaultTargetPlatform,
          sourcePlatform: platform,
          targetPlatformName: targetPlatformName,
        ),
        mode: mode ?? defaultBuildMode,
      ),
      null => switch (extensionArtifacts[artifact.name]) {
        final ResolvedExtensionArtifact custom => _ExtensionArtifactInputSource(custom),
        null => throwToolExit(
          'Unsupported artifact "${artifact.name}" requested by a tool extension.',
        ),
      },
    },
  ExtensionHostArtifactSource(:final ExtensionHostArtifact artifact) =>
    switch (_builtInHostArtifacts[artifact.name]) {
      final HostArtifact builtIn => Source.hostArtifact(builtIn),
      null => switch (extensionArtifacts[artifact.name]) {
        final ResolvedExtensionArtifact custom => _ExtensionArtifactInputSource(custom),
        null => throwToolExit(
          'Unsupported host artifact "${artifact.name}" requested by a tool extension.',
        ),
      },
    },
};

final class _ExtensionArtifactInputSource implements Source {
  const _ExtensionArtifactInputSource(this._artifact);

  final ResolvedExtensionArtifact _artifact;

  @override
  bool get implicit => false;

  @override
  void accept(SourceVisitor visitor) {
    if (_artifact.stampFile case final File stampFile) {
      visitor.sources.add(stampFile);
      return;
    }
    final FileSystem fs = visitor.environment.fileSystem;
    if (fs.isDirectorySync(_artifact.path)) {
      visitor.sources.addAll(<File>[
        for (final FileSystemEntity entity
            in fs.directory(_artifact.path).listSync(recursive: true))
          if (entity is File) entity,
      ]);
      return;
    }
    visitor.sources.add(fs.file(_artifact.path));
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
